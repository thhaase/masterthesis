#!/usr/bin/env python3
"""Word counter for Typst master thesis (IAS Linköping spec: 10,000–12,000 words).

Counts words in body matter (Introduction → Conclusion), excluding front matter,
back matter, figures, captions (incl. #long-caption), tables, math, code,
citations, and comments. Author-side notes (e.g. #text(fill: red)[...]) are
kept by default since they are still prose; pass --strict to drop them.

Usage:
    python wordcount.py master-thesis.typ
    python wordcount.py master-thesis.typ --json
    python wordcount.py master-thesis.typ --strict
    python wordcount.py master-thesis.typ --debug
    python wordcount.py --self-test
"""

import argparse
import json
import re
import sys
from pathlib import Path

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

TARGET_MIN = 10_000
TARGET_MAX = 12_000

# Functions whose entire #name(...)[body] is dropped from the count.
# Everything else with a [body] keeps the body and drops the (args).
DROP_FUNCS = {
    "figure",          # figures + their caption args
    "long-caption",    # custom dual-caption command
    "raw",             # #raw(...)
    "cite",            # #cite(<key>, ...)
    "bibliography",
    "image",
    "table",           # tabular data, not prose
    "grid",
    "place",           # placed content is usually figure-like
    "counter",         # #counter(page).update(0)
}

# Functions that consume the rest of their line (not balanced-bracket calls).
LINE_DIRECTIVES = {"import", "include"}

# Functions that consume a balanced expression (parens, brackets, braces) up
# to end-of-line at depth zero.
EXPR_DIRECTIVES = {"set", "show", "let"}


class C:
    """ANSI escape codes; auto-disabled when stdout is not a TTY or NO_COLOR is set."""
    import os as _os
    _enabled = sys.stdout.isatty() and "NO_COLOR" not in _os.environ
    RESET = "\033[0m" if _enabled else ""
    BOLD = "\033[1m" if _enabled else ""
    DIM = "\033[2m" if _enabled else ""
    RED = "\033[31m" if _enabled else ""
    YELLOW = "\033[33m" if _enabled else ""
    GREEN = "\033[32m" if _enabled else ""
    DIM_OFF = RESET


# ----------------------------------------------------------------------------
# Bracket matching
# ----------------------------------------------------------------------------

def find_matching(text, start, open_ch, close_ch):
    """Given index of `open_ch` in `text`, return index of the matching
    `close_ch`. Handles "..." strings and \\ escapes. Returns -1 if unmatched."""
    if start >= len(text) or text[start] != open_ch:
        return -1
    depth = 1
    i = start + 1
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == '"':
            i += 1
            while i < n:
                if text[i] == '\\':
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if ch == '\\' and i + 1 < n:
            i += 2
            continue
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


# ----------------------------------------------------------------------------
# Body boundary detection
# ----------------------------------------------------------------------------

_RE_START_SENTINEL = re.compile(
    r'//\s*=+\s*C\s*O\s*N\s*T\s*E\s*N\s*T', re.IGNORECASE)
_RE_END_SENTINEL = re.compile(r'//\s*=+\s*APPENDICES', re.IGNORECASE)
_RE_INTRO_HEADING = re.compile(r'^=\s+Introduction\b', re.MULTILINE)
_RE_APPENDIX_HEADING = re.compile(r'^=\s+Appendix\b', re.MULTILINE)


def find_body_bounds(text):
    """Return (start_offset, end_offset) of the body matter."""
    m = _RE_START_SENTINEL.search(text)
    if m:
        nl = text.find('\n', m.end())
        start = nl + 1 if nl != -1 else m.end()
    else:
        m = _RE_INTRO_HEADING.search(text)
        if not m:
            raise RuntimeError(
                "Could not locate body start "
                "(no 'CONTENT STARTS HERE' sentinel and no '= Introduction').")
        start = m.start()

    m = _RE_END_SENTINEL.search(text, start)
    if m:
        end = m.start()
    else:
        m = _RE_APPENDIX_HEADING.search(text, start)
        end = m.start() if m else len(text)
    return start, end


# ----------------------------------------------------------------------------
# Cleaning passes
# ----------------------------------------------------------------------------

def strip_comments(t):
    """Strip /* ... */ block and // line comments. String-aware: respects
    "..." literals so URLs like "https://..." aren't mangled."""
    out = []
    i, n = 0, len(t)
    while i < n:
        c = t[i]
        if c == '"':
            # Copy entire string literal verbatim
            out.append(c)
            i += 1
            while i < n:
                if t[i] == '\\' and i + 1 < n:
                    out.append(t[i:i + 2])
                    i += 2
                    continue
                out.append(t[i])
                if t[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if c == '/' and i + 1 < n and t[i + 1] == '*':
            end = t.find('*/', i + 2)
            i = end + 2 if end != -1 else n
            out.append(' ')
            continue
        if c == '/' and i + 1 < n and t[i + 1] == '/':
            nl = t.find('\n', i + 2)
            i = nl if nl != -1 else n
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def strip_raw_markup(t):
    """Strip Typst markup raw: ``` triple-backtick blocks and ` inline spans."""
    # Triple-backtick block, optional language tag, may contain newlines.
    t = re.sub(r'```[\w-]*[\s\S]*?```', ' ', t)
    # Single-backtick inline; non-greedy, no newlines.
    t = re.sub(r'`[^`\n]*`', ' ', t)
    return t


def consume_expr_directive(t, j):
    """Starting at `j` (just past `#set ` / `#show ` / `#let `), consume a
    balanced expression to end-of-line at depth zero. Returns new index."""
    n = len(t)
    paren = bracket = brace = 0
    in_str = False
    while j < n:
        ch = t[j]
        if in_str:
            if ch == '\\' and j + 1 < n:
                j += 2
                continue
            if ch == '"':
                in_str = False
            j += 1
            continue
        if ch == '"':
            in_str = True
            j += 1
            continue
        if ch == '(': paren += 1
        elif ch == ')': paren -= 1
        elif ch == '[': bracket += 1
        elif ch == ']': bracket -= 1
        elif ch == '{': brace += 1
        elif ch == '}': brace -= 1
        elif ch == '\n' and paren == 0 and bracket == 0 and brace == 0:
            break
        j += 1
    return j


def consume_field_chain(t, j):
    """Consume `.field` and `.method(...)` accesses starting at index `j`."""
    n = len(t)
    while j < n and t[j] == '.':
        j += 1
        m = re.match(r'\w+', t[j:])
        if m:
            j += m.end()
        if j < n and t[j] == '(':
            c = find_matching(t, j, '(', ')')
            if c != -1:
                j = c + 1
    return j


# Typst function-call name: starts with letter/_, allows letters/digits/_/-
_RE_HASH_NAME = re.compile(r'#([A-Za-z_][\w\-]*)')


def process_hash_calls(t, strict=False):
    """Single pass: rewrite every `#name(...)`/`#name[...]`/`#name(...)[...]`.

    - LINE_DIRECTIVES: drop directive + rest of line.
    - EXPR_DIRECTIVES: drop directive + balanced expression to EOL.
    - DROP_FUNCS: drop entire call, body, optional <label>, and optionally a
      following #long-caption[...].
    - pagebreak: drop call (with optional args).
    - else: drop (args), keep [body] content, drop trailing .field/.method().
            With strict=True: drop entirely if args contain `fill: red`.
    """
    out = []
    i, n = 0, len(t)
    while i < n:
        if t[i] != '#':
            out.append(t[i])
            i += 1
            continue
        m = _RE_HASH_NAME.match(t, i)
        if not m:
            out.append(t[i])
            i += 1
            continue
        name = m.group(1)
        j = m.end()

        if name in LINE_DIRECTIVES:
            nl = t.find('\n', j)
            i = nl if nl != -1 else n
            continue

        if name in EXPR_DIRECTIVES:
            i = consume_expr_directive(t, j)
            continue

        if name == 'pagebreak':
            if j < n and t[j] == '(':
                cp = find_matching(t, j, '(', ')')
                if cp != -1:
                    j = cp + 1
            i = j
            continue

        # Parse optional (args) and [body]
        args_text = ""
        if j < n and t[j] == '(':
            cp = find_matching(t, j, '(', ')')
            if cp != -1:
                args_text = t[j + 1:cp]
                j = cp + 1
        body_start, body_end = -1, -1
        if j < n and t[j] == '[':
            cb = find_matching(t, j, '[', ']')
            if cb != -1:
                body_start, body_end = j + 1, cb
                j = cb + 1
        j = consume_field_chain(t, j)

        if name in DROP_FUNCS:
            # Eat optional whitespace + <label>
            k = j
            while k < n and t[k] in ' \t':
                k += 1
            if k < n and t[k] == '<':
                end_lbl = t.find('>', k)
                if end_lbl != -1:
                    j = end_lbl + 1
            # Eat optional following #long-caption[...]
            k = j
            while k < n and t[k] in ' \t\r\n':
                k += 1
            if t[k:k + 14] == '#long-caption[':
                lc = find_matching(t, k + 13, '[', ']')
                if lc != -1:
                    j = lc + 1
            i = j
            continue

        # Strict mode: drop red TODO-style annotations
        if strict and name == 'text' and re.search(r'\bfill\s*:\s*red\b', args_text):
            i = j
            continue

        # Default: drop args, keep body content (with surrounding spaces so it
        # doesn't fuse with adjacent tokens).
        if body_start != -1:
            out.append(' ')
            out.append(t[body_start:body_end])
            out.append(' ')
        else:
            out.append(' ')
        i = j
    return ''.join(out)


def clean(text, strict=False):
    """Apply the full cleaning pipeline to a body section."""
    # Comments and markup-raw first (idempotent if already done by caller).
    t = strip_comments(text)
    t = strip_raw_markup(t)
    # Iterate hash-call processing to a fixpoint, since unwrapping a body may
    # surface previously-nested hash calls (e.g. #text[#figure[...]]).
    for _ in range(8):
        prev = t
        t = process_hash_calls(t, strict=strict)
        if t == prev:
            break
    # Math: inline & display, respecting `\$` escapes
    t = re.sub(r'\$(?:\\.|[^\\$])*\$', ' ', t, flags=re.DOTALL)
    # Citations: @key (optional [supplement]). Allow digit-first keys.
    t = re.sub(r'@\w[\w.\-:]*(?:\[[^\]]*\])?', '', t)
    # Labels <fig:foo>, <sec:bar>, ...
    t = re.sub(r'<[A-Za-z_][\w:.\-]*>', '', t)
    # Heading markers — keep heading text
    t = re.sub(r'^=+\s+', '', t, flags=re.MULTILINE)
    return t


# ----------------------------------------------------------------------------
# Section splitting
# ----------------------------------------------------------------------------

_RE_LEVEL1 = re.compile(r'^=\s+(.+?)\s*$', re.MULTILINE)


def split_sections(body_text):
    """Split body into level-1 sections by `= Heading`. Comments and raw
    markup are stripped first so `=` inside backticks or comments doesn't fool
    us."""
    cleaned = strip_raw_markup(strip_comments(body_text))
    matches = list(_RE_LEVEL1.finditer(cleaned))
    sections = []
    for i, m in enumerate(matches):
        name = m.group(1).strip()
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(cleaned)
        sections.append({"name": name, "raw": cleaned[start:end]})
    return sections


def count_words(text):
    """Count whitespace-separated tokens with at least one alphanumeric char.
    Hyphenated words and digit-bearing tokens count as one word each."""
    return sum(1 for tok in text.split() if any(ch.isalnum() for ch in tok))


# ----------------------------------------------------------------------------
# Reporting
# ----------------------------------------------------------------------------

def render_bar(total, target_min, target_max, width=40):
    filled = min(int(round(total / target_max * width)), width)
    min_mark = int(round(target_min / target_max * width))
    parts = []
    for i in range(width):
        if i < filled:
            color = C.GREEN if i >= min_mark else C.YELLOW
            parts.append(color + "█" + C.RESET)
        else:
            parts.append(C.DIM + "░" + C.RESET)
    overshoot = total - target_max
    if overshoot > 0:
        n_extra = min(int(round(overshoot / target_max * width)) + 1, 8)
        parts.append(C.RED + "▌" * n_extra + C.RESET)
    return "".join(parts)


def print_pretty_report(file_name, total, sections, target_min, target_max,
                        strict=False):
    print()
    mode = f"  {C.DIM}[strict mode]{C.RESET}" if strict else ""
    print(f"  {C.BOLD}Word Count{C.RESET}  {C.DIM}— {file_name}{C.RESET}{mode}")
    print("  " + "─" * 52)

    name_w = max((len(s["name"]) for s in sections), default=12)
    name_w = max(name_w, 16)

    for s in sections:
        pct = (s["words"] / total * 100) if total else 0
        bar_inline = "▏" + "▍" * max(int(s["words"] / 200), 1)
        print(f"  {s['name']:<{name_w}}  "
              f"{C.BOLD}{s['words']:>6,}{C.RESET}  "
              f"{C.DIM}{pct:>5.1f}%  {bar_inline}{C.RESET}")

    print("  " + "─" * 52)
    print(f"  {C.BOLD}{'TOTAL':<{name_w}}  {total:>6,}{C.RESET}")
    print()
    print(f"  {C.DIM}Target:{C.RESET} {target_min:,}–{target_max:,} words")
    print(f"  [{render_bar(total, target_min, target_max)}] "
          f"{total:,} / {target_max:,}")

    if total < target_min:
        deficit = target_min - total
        print(f"  {C.YELLOW}● under target{C.RESET}  "
              f"{C.DIM}— need {deficit:,} more words to reach minimum{C.RESET}")
    elif total > target_max:
        excess = total - target_max
        print(f"  {C.RED}● over target{C.RESET}  "
              f"{C.DIM}— need to cut {excess:,} words to fit maximum{C.RESET}")
    else:
        room_min = total - target_min
        room_max = target_max - total
        print(f"  {C.GREEN}● within target{C.RESET}  "
              f"{C.DIM}— {room_min:,} above min, {room_max:,} below max{C.RESET}")
    print()


# ----------------------------------------------------------------------------
# Self-test (golden fixtures)
# ----------------------------------------------------------------------------

_FIXTURES = [
    # (name, snippet, expected_words, strict)
    ("plain prose",
     "The cat sat on the mat.", 6, False),
    ("link with URL // is preserved",
     'See #link("https://example.com//path")[the docs] for details.',
     5,  # See / the / docs / for / details
     False),
    ("inline raw stripped",
     "We use `data.table` for performance reasons.", 5, False),  # We use for performance reasons
    ("triple-backtick block stripped",
     "Setup follows.\n```r\nlibrary(igraph)\nx <- 1\n```\nDone.", 3, False),
    ("align wrapper keeps body (deny-list fix)",
     "#align(center)[A centered pull quote here.]", 5, False),
    ("block wrapper keeps body",
     "#block(width: 80%)[Indented commentary on prior work.]", 5, False),
    ("figure + caption + long-caption all dropped",
     ("Before figure.\n#figure(image(\"x.png\"), caption: [Short cap])"
      "<fig:x>\n#long-caption[A much longer caption goes here.]\nAfter figure."),
     4, False),  # Before / figure / After / figure
    ("table dropped",
     "Numbers below.\n#table(columns: 2, [a], [b], [c], [d])\nDone.",
     3, False),  # Numbers / below / Done
    ("citation @key dropped",
     "As shown by @mudde2004 in his work.", 6, False),
    ("citation digit-first key dropped",
     "Per @2024foo this matters.", 3, False),
    ("inline math stripped",
     "The value $x = 5$ is small.", 4, False),  # The / value / is / small
    ("escaped dollar in math",
     r"Cost is \$5 in total.", 5, False),  # \$ doesn't open math; "5" stays
    ("red TODO kept by default",
     "#text(fill: red)[TODO: rewrite this paragraph.]", 4, False),
    ("red TODO dropped in strict mode",
     "#text(fill: red)[TODO: rewrite this paragraph.]", 0, True),
    ("emph + footnote nesting",
     "Foo #emph[bar #footnote[baz qux]] end.", 5, False),
    ("set/show directives stripped",
     '#set page(margin: 1in)\n#show: thesis.with(title: "Foo")\nReal text here.',
     3, False),
    ("counter().update() chain dropped",
     "#counter(page).update(0)\nReal prose follows.", 3, False),
    ("comment with // inside string preserved",
     'Use #link("https://x.com/y")[the link]. // comment removed',
     3, False),  # Use / the / link
]


def run_self_test():
    """Run golden fixtures. Returns 0 on success, 1 on failure."""
    failures = []
    for name, snippet, expected, strict in _FIXTURES:
        cleaned = clean(snippet, strict=strict)
        got = count_words(cleaned)
        status = (C.GREEN + "PASS" + C.RESET) if got == expected else (
                  C.RED + "FAIL" + C.RESET)
        marker = "" if got == expected else f"  (expected {expected})"
        flag = " [strict]" if strict else ""
        print(f"  {status}  {name}{flag}: {got}{marker}")
        if got != expected:
            failures.append((name, snippet, expected, got, cleaned))

    print()
    if failures:
        print(f"  {C.RED}{len(failures)} failure(s){C.RESET}\n")
        for name, snippet, exp, got, cl in failures:
            print(f"  --- {name} ---")
            print(f"      input:    {snippet!r}")
            print(f"      cleaned:  {cl!r}")
            print(f"      expected: {exp}, got: {got}")
            print()
        return 1
    print(f"  {C.GREEN}All {len(_FIXTURES)} tests passed.{C.RESET}\n")
    return 0


# ----------------------------------------------------------------------------
# Entry point
# ----------------------------------------------------------------------------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", type=Path, nargs="?",
                    help="Path to the .typ thesis file.")
    ap.add_argument("--json", action="store_true",
                    help="Emit JSON instead of the pretty terminal report.")
    ap.add_argument("--debug", action="store_true",
                    help="Print the cleaned text per section (for inspection).")
    ap.add_argument("--strict", action="store_true",
                    help="Drop #text(fill: red)[...] author notes from the count.")
    ap.add_argument("--self-test", action="store_true", dest="self_test",
                    help="Run golden-fixture tests and exit.")
    ap.add_argument("--min", type=int, default=TARGET_MIN, dest="target_min",
                    help=f"Minimum target words (default {TARGET_MIN:,}).")
    ap.add_argument("--max", type=int, default=TARGET_MAX, dest="target_max",
                    help=f"Maximum target words (default {TARGET_MAX:,}).")
    args = ap.parse_args(argv)

    if args.self_test:
        return run_self_test()

    if args.file is None:
        ap.error("file is required (or pass --self-test)")

    if not args.file.exists():
        print(f"Error: file not found: {args.file}", file=sys.stderr)
        return 1

    if args.file.suffix.lower() != ".typ":
        print(f"Error: expected a .typ file, got '{args.file.suffix}'.",
              file=sys.stderr)
        sibling = args.file.with_suffix(".typ")
        if sibling.exists():
            print(f"  Did you mean: {sibling} ?", file=sys.stderr)
        return 1

    try:
        text = args.file.read_text(encoding="utf-8")
    except UnicodeDecodeError as err:
        print(f"Error: {args.file} is not valid UTF-8 text "
              f"(byte 0x{err.object[err.start]:02x} at position {err.start}).",
              file=sys.stderr)
        print("  This tool reads .typ source files, not compiled PDFs.",
              file=sys.stderr)
        return 1

    s, e = find_body_bounds(text)
    body = text[s:e]
    sections = split_sections(body)

    results = []
    for sec in sections:
        cleaned_text = clean(sec["raw"], strict=args.strict)
        words = count_words(cleaned_text)
        results.append({
            "name": sec["name"],
            "words": words,
            "_clean": cleaned_text,
        })

    total = sum(r["words"] for r in results)

    if args.json:
        out = {
            "file": str(args.file),
            "strict": args.strict,
            "total_words": total,
            "target_min": args.target_min,
            "target_max": args.target_max,
            "in_range": args.target_min <= total <= args.target_max,
            "sections": [
                {"name": r["name"], "words": r["words"]} for r in results
            ],
        }
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0

    print_pretty_report(args.file.name, total, results,
                        args.target_min, args.target_max, strict=args.strict)

    if args.debug:
        for r in results:
            print(f"\n{C.BOLD}=== {r['name']} ({r['words']} words) ==={C.RESET}\n")
            print(r["_clean"])

    return 0


if __name__ == "__main__":
    sys.exit(main())
