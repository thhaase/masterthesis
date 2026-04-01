#!/usr/bin/env bash
# count_thesis_words.sh — Count words in main body of a Typst thesis
#
# Counts words from = Introduction through = Conclusion (inclusive),
# INCLUDING footnotes, EXCLUDING:
#   - front matter & back matter (appendices, bibliography)
#   - #figure(...) blocks and #long-caption[...] blocks
#   - code blocks (```...```)
#   - Typst comments (// ...)
#   - Typst directives (#set, #show, #let, #import, #include, #counter, #pagebreak, #v, #align, #block, #text inside markup)
#   - labels like <fig:label>
#   - image references like #image(...)

set -euo pipefail

MAIN_FILE="${1:?Usage: $0 <main.typ> [section_dir]}"
SECTION_DIR="${2:-$(dirname "$MAIN_FILE")/sections}"

# --- Step 1: Resolve includes and extract main body ---
# We inline any #include files, then cut to the main body range.

resolve_includes() {
  local file="$1"
  local base_dir="$2"
  while IFS= read -r line; do
    # Match #include "path/to/file.typ"
    if [[ "$line" =~ ^[[:space:]]*\#include[[:space:]]+\"([^\"]+)\" ]]; then
      local inc_path="${BASH_REMATCH[1]}"
      # Resolve relative to the file's directory
      if [[ ! "$inc_path" = /* ]]; then
        inc_path="$base_dir/$inc_path"
      fi
      if [[ -f "$inc_path" ]]; then
        resolve_includes "$inc_path" "$(dirname "$inc_path")"
      else
        echo "// [WARNING: could not find $inc_path]"
      fi
    else
      echo "$line"
    fi
  done < "$file"
}

# --- Step 2: Extract main body (Introduction → before Appendices) ---
extract_main_body() {
  local in_body=0
  while IFS= read -r line; do
    # Start at = Introduction
    if [[ "$line" =~ ^[[:space:]]*=[[:space:]]+Introduction ]]; then
      in_body=1
    fi
    # Stop before appendices / bibliography
    if (( in_body )) && [[ "$line" =~ ^[[:space:]]*//[[:space:]]*=+[[:space:]]*APPENDIX|APPENDICES|BACK\ MATTER ]]; then
      break
    fi
    if (( in_body )) && [[ "$line" =~ ^[[:space:]]*=[[:space:]]+Appendix ]]; then
      break
    fi
    if (( in_body )); then
      echo "$line"
    fi
  done
}

# --- Step 3: Strip non-prose elements ---
strip_markup() {
  sed -E '
    # Remove full-line comments
    /^[[:space:]]*\/\//d

    # Remove inline comments (but keep text before //)
    s|//.*||

    # Remove code fences and everything between them
    /^```/,/^```/d

    # Remove #figure( ... ) blocks — handles multi-line via state
    /^[[:space:]]*#figure\(/,/^\)/d

    # Remove #long-caption lines and their bracket content (single-line)
    /^[[:space:]]*#long-caption/d

    # Remove labels like <fig:label>
    s/<[a-zA-Z_][a-zA-Z0-9_:.-]*>//g

    # Remove #image(...) references
    s/#image\([^)]*\)//g

    # Remove Typst directives on their own lines
    /^[[:space:]]*#(set|show|let|import|include|counter|pagebreak|align|block|v|context)[[:space:](]/d

    # Remove remaining # function calls like #emph(...), #text(...)
    s/#[a-zA-Z_]+\([^)]*\)//g

    # Remove bracket markup: #text[...], #emph[...] — keep inner text
    s/#[a-zA-Z_]+\[([^]]*)\]/\1/g

    # Remove lone [ ] that are Typst content blocks
    s/\[//g
    s/\]//g

    # Remove Typst math blocks $ ... $
    s/\$[^$]*\$//g

    # Remove emphasis markers * (Typst bold/italic)
    s/\*//g

    # Remove heading markers (= at start) but keep heading text for counting
    s/^[[:space:]]*=+[[:space:]]*//

    # Remove lines that are purely Typst markup residue
    /^[[:space:]]*#/d

    # Remove empty lines (they do not contribute words)
    /^[[:space:]]*$/d
  '
}

# --- Step 4: Count ---
FULL=$(resolve_includes "$MAIN_FILE" "$(dirname "$MAIN_FILE")")
BODY=$(echo "$FULL" | extract_main_body | strip_markup)

WORD_COUNT=$(echo "$BODY" | wc -w | tr -d '[:space:]')

# --- Per-section breakdown ---
echo "========================================="
echo "  Thesis Word Count (main body only)"
echo "========================================="
echo ""

# Count per top-level heading
current_section=""
section_words=0

while IFS= read -r line; do
  # Detect section headings (already stripped of = markers by strip_markup,
  # but let's re-parse from pre-stripped body for headings)
  true
done

# Simpler per-section: re-extract and count per heading
echo "  Section breakdown:"
echo "  -----------------------------------------"

resolve_includes "$MAIN_FILE" "$(dirname "$MAIN_FILE")" \
  | extract_main_body \
  | awk '
    /^[[:space:]]*=[[:space:]]/ && !/^[[:space:]]*==/ {
      if (section != "") print section
      # Remove leading = and whitespace
      sub(/^[[:space:]]*=[[:space:]]*/, "")
      section = $0
    }
  ' | while read -r section_name; do
    # Extract text for this section
    sec_text=$(
      resolve_includes "$MAIN_FILE" "$(dirname "$MAIN_FILE")" \
        | extract_main_body \
        | awk -v sec="$section_name" '
          BEGIN { found=0 }
          /^[[:space:]]*=[[:space:]]/ && !/^[[:space:]]*==/ {
            sub(/^[[:space:]]*=[[:space:]]*/, "")
            if ($0 == sec) { found=1; next }
            else if (found) { exit }
          }
          found { print }
        ' \
        | strip_markup
    )
    sec_count=$(echo "$sec_text" | wc -w | tr -d '[:space:]')
    printf "  %-25s %6s words\n" "$section_name" "$sec_count"
  done

echo "  -----------------------------------------"
printf "  %-25s %6s words\n" "TOTAL" "$WORD_COUNT"
echo ""

# --- Traffic light ---
if (( WORD_COUNT < 10000 )); then
  REMAINING=$(( 10000 - WORD_COUNT ))
  echo "  ⚠️  Under minimum (10,000). ~${REMAINING} words to go."
elif (( WORD_COUNT > 12000 )); then
  OVER=$(( WORD_COUNT - 12000 ))
  echo "  ⚠️  Over maximum (12,000) by ~${OVER} words. Consider trimming."
else
  echo "  ✅ Within target range (10,000–12,000)."
fi
echo ""