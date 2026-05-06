#!/usr/bin/env python3
"""Word counter for Typst master thesis (IAS Linköping spec: 10,000–12,000 words).

Counts words in body matter (Introduction → Conclusion), excluding front matter,
back matter, figures, captions (incl. #long-caption), math, code, citations, and
comments. Author-side notes (e.g. #text(fill: red)[...]) are kept by default since
they are still prose that will be edited later.

Usage:
    python wordcount.py master-thesis.typ
    python wordcount.py master-thesis.typ --json
    python wordcount.py master-thesis.typ --debug    # dump cleaned text per section
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

# Typst functions whose [body] should be kept (unwrapped). Everything else
# beginning with '#' is stripped together with its arguments and body.
KEEP_BODY_FUNCS = {
    "text", "emph", "link", "quote", "underline",
    "footnote", "strong", "highlight", "smallcaps",
}


class C:
    """ANSI escape codes for terminal styling.

    Auto-disabled when stdout is not a TTY (e.g. piped to file/pager) or when
    NO_COLOR env var is set (https://no-color.org)."""
    import os as _os
    _enabled = sys.stdout.isatty() and "NO_COLOR" not in _os.environ
    RESET = "\033[0m" if _enabled else ""
    BOLD = "\033[1m" if _enabled else ""
    DIM = "\033[2m" if _enabled else ""
    RED = "\033[31m" if _enabled else ""
    YELLOW = "\033[33m" if _enabled else ""
    GREEN = "\033[32m" if _enabled else ""
    BLUE = "\033[34m" if _enabled else ""
    CYAN = "\033[36m" if _enabled else ""
    MAGENTA = "\033[35m" if _enabled else ""


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
    """Strip /* ... */ block comments and // line comments."""
    t = re.sub(r'/\*.*?\*/', ' ', t, flags=re.DOTALL)
    t = re.sub(r'//[^\n]*', '', t)
    return t


def strip_func_call(t, name):
    """Strip every `#name(...)` invocation, including nested brackets."""
    out = []
    i, n = 0, len(t)
    lit = '#' + name + '('
    L = len(lit)
    while i < n:
        if t[i:i + L] == lit:
            close = find_matching(t, i + L - 1, '(', ')')
            if close != -1:
                i = close + 1
                continue
        out.append(t[i])
        i += 1
    return ''.join(out)


def strip_directive(t, prefix_re):
    """Strip directives like `#set ...`, `#show ...`, `#let ...` consuming
    balanced (), [], {} until end-of-line at depth zero."""
    out = []
    i, n = 0, len(t)
    while i < n:
        m = re.match(prefix_re, t[i:])
        if m:
            j = i + m.end()
            d = {'(': 0, '[': 0, '{': 0}
            in_str = False
            while j < n:
                ch = t[j]
                if in_str:
                    if ch == '\\':
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
                if ch == '(':
                    d['('] += 1
                elif ch == ')':
                    d['('] -= 1
                elif ch == '[':
                    d['['] += 1
                elif ch == ']':
                    d['['] -= 1
                elif ch == '{':
                    d['{'] += 1
                elif ch == '}':
                    d['{'] -= 1
                elif ch == '\n' and all(v == 0 for v in d.values()):
                    break
                j += 1
            i = j
            continue
        out.append(t[i])
        i += 1
    return ''.join(out)


def strip_figure_blocks(t):
    """Strip `#figure(...)` blocks together with an optional trailing
    `<label>` and an optional immediately-following `#long-caption[...]`."""
    out = []
    i, n = 0, len(t)
    while i < n:
        if t[i:i + 8] == '#figure(':
            close = find_matching(t, i + 7, '(', ')')
            if close != -1:
                j = close + 1
                # optional trailing whitespace + <label>
                while j < n and t[j] in ' \t':
                    j += 1
                if j < n and t[j] == '<':
                    end_lbl = t.find('>', j)
                    if end_lbl != -1:
                        j = end_lbl + 1
                # optional immediately-following long-caption
                k = j
                while k < n and t[k] in ' \t\r\n':
                    k += 1
                if t[k:k + 14] == '#long-caption[':
                    lc_close = find_matching(t, k + 13, '[', ']')
                    if lc_close != -1:
                        j = lc_close + 1
                i = j
                continue
        out.append(t[i])
        i += 1
    return ''.join(out)


def strip_long_caption(t):
    """Strip standalone `#long-caption[...]` blocks not handled by figure pass."""
    out = []
    i, n = 0, len(t)
    while i < n:
        if t[i:i + 14] == '#long-caption[':
            close = find_matching(t, i + 13, '[', ']')
            if close != -1:
                i = close + 1
                continue
        out.append(t[i])
        i += 1
    return ''.join(out)


def unwrap_keep_body(t):
    """For functions in KEEP_BODY_FUNCS, replace `#funcname(args)[body]` with
    the body content. Args (if any) are dropped. Run multiple times for nesting."""
    out = []
    i, n = 0, len(t)
    while i < n:
        if t[i] == '#':
            m = re.match(r'#(\w+)', t[i:])
            if m and m.group(1) in KEEP_BODY_FUNCS:
                j = i + m.end()
                if j < n and t[j] == '(':
                    cp = find_matching(t, j, '(', ')')
                    if cp == -1:
                        out.append(t[i]); i += 1; continue
                    j = cp + 1
                if j < n and t[j] == '[':
                    cb = find_matching(t, j, '[', ']')
                    if cb != -1:
                        out.append(' ')
                        out.append(t[j + 1:cb])
                        out.append(' ')
                        i = cb + 1
                        continue
                # No body — drop the whole call (e.g. `#emph` w/o args is invalid)
                out.append(' ')
                i = j
                continue
        out.append(t[i])
        i += 1
    return ''.join(out)


def strip_remaining_funcs(t):
    """Strip any leftover `#funcname(...)`, `#funcname[...]`, and chained
    `.method(...)` accesses."""
    out = []
    i, n = 0, len(t)
    while i < n:
        if t[i] == '#':
            m = re.match(r'#(\w+)', t[i:])
            if m:
                j = i + m.end()
                if j < n and t[j] == '(':
                    c = find_matching(t, j, '(', ')')
                    if c != -1:
                        j = c + 1
                if j < n and t[j] == '[':
                    c = find_matching(t, j, '[', ']')
                    if c != -1:
                        j = c + 1
                # field accesses / method chains
                while j < n and t[j] == '.':
                    j += 1
                    m2 = re.match(r'\w+', t[j:])
                    if m2:
                        j += m2.end()
                    if j < n and t[j] == '(':
                        c = find_matching(t, j, '(', ')')
                        if c != -1:
                            j = c + 1
                i = j
                continue
        out.append(t[i])
        i += 1
    return ''.join(out)


def clean(text):
    """Apply the full cleaning pipeline to a body section. Comments must
    already be stripped before this is called (so we can split on `=` safely)."""
    t = text
    # Calls whose entire content (including any captions) should disappear:
    t = strip_func_call(t, 'raw')
    t = strip_func_call(t, 'bibliography')
    t = strip_func_call(t, 'image')
    # Setup directives
    t = strip_directive(t, r'#set\s+')
    t = strip_directive(t, r'#show\s+')
    t = strip_directive(t, r'#let\s+')
    t = strip_directive(t, r'#counter\(')
    t = re.sub(r'#include\s+"[^"]*"', '', t)
    t = re.sub(r'#import\s+"[^"]*"[^\n]*', '', t)
    t = re.sub(r'#pagebreak\s*\([^)]*\)', '', t)
    # Figures: spec says exclude figures+captions; this also drops long-caption
    t = strip_figure_blocks(t)
    t = strip_long_caption(t)
    # Unwrap keep-body funcs (#text, #emph, #link, #quote, #footnote, ...)
    # repeated for nesting like #text(...)[#emph[x] and #quote[y]]
    for _ in range(5):
        prev = t
        t = unwrap_keep_body(t)
        if t == prev:
            break
    # Math (display & inline) – per user: equations are objects, exclude
    t = re.sub(r'\$[^$]*\$', ' ', t, flags=re.DOTALL)
    # Citations: @key (with optional [supplement]) and #cite(<key>, ...)
    # Typst keys allow letters, digits, hyphens, dots, underscores
    t = re.sub(r'@[A-Za-z][\w.\-]*(?:\[[^\]]*\])?', '', t)
    t = strip_func_call(t, 'cite')
    # Labels <fig:foo>, <sec:bar>, ...
    t = re.sub(r'<[a-zA-Z][\w:.\-]*>', '', t)
    # Anything else starting with '#' (counter().update, sym.x, image, etc.)
    t = strip_remaining_funcs(t)
    # Heading markers — keep heading text (it counts toward its section)
    t = re.sub(r'^=+\s+', '', t, flags=re.MULTILINE)
    return t


# ----------------------------------------------------------------------------
# Section splitting
# ----------------------------------------------------------------------------

_RE_LEVEL1 = re.compile(r'^=\s+(.+?)\s*$', re.MULTILINE)


def split_sections(body_text):
    """Split body into level-1 sections by `= Heading` lines. Comments are
    stripped first so commented-out headings inside ASCII banners don't count."""
    cleaned = strip_comments(body_text)
    matches = list(_RE_LEVEL1.finditer(cleaned))
    sections = []
    for i, m in enumerate(matches):
        name = m.group(1).strip()
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(cleaned)
        sections.append({"name": name, "raw": cleaned[start:end]})
    return sections


def count_words(text):
    """Count whitespace-separated tokens that contain at least one alphanumeric
    character. Hyphenated words ('anti-elite') and digit-bearing tokens
    ('Qwen3-235B', '693,015') count as one word each."""
    return sum(1 for tok in text.split() if any(ch.isalnum() for ch in tok))


# ----------------------------------------------------------------------------
# Reporting
# ----------------------------------------------------------------------------

def render_bar(total, target_min, target_max, width=40):
    """Render a colored progress bar from 0 to target_max (with overshoot ▌)."""
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


def print_pretty_report(file_name, total, sections, target_min, target_max):
    print()
    print(f"  {C.BOLD}Word Count{C.RESET}  {C.DIM}— {file_name}{C.RESET}")
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
# Entry point
# ----------------------------------------------------------------------------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", type=Path, help="Path to the .typ thesis file.")
    ap.add_argument("--json", action="store_true",
                    help="Emit JSON instead of the pretty terminal report.")
    ap.add_argument("--debug", action="store_true",
                    help="Print the cleaned text per section (for inspection).")
    ap.add_argument("--min", type=int, default=TARGET_MIN, dest="target_min",
                    help=f"Minimum target words (default {TARGET_MIN:,}).")
    ap.add_argument("--max", type=int, default=TARGET_MAX, dest="target_max",
                    help=f"Maximum target words (default {TARGET_MAX:,}).")
    args = ap.parse_args(argv)

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
        print("  This tool reads .typ source files, not compiled PDFs or "
              "binary formats.", file=sys.stderr)
        return 1
    s, e = find_body_bounds(text)
    body = text[s:e]
    sections = split_sections(body)

    results = []
    for sec in sections:
        cleaned_text = clean(sec["raw"])
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
                        args.target_min, args.target_max)

    if args.debug:
        for r in results:
            print(f"\n{C.BOLD}=== {r['name']} ({r['words']} words) ==={C.RESET}\n")
            print(r["_clean"])

    return 0


if __name__ == "__main__":
    sys.exit(main())
