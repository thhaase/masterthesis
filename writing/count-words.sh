#!/usr/bin/env bash
# count-words.sh — word count for main body of a Typst thesis
set -euo pipefail

MAIN_FILE="${1:?Usage: $0 <main.typ>}"
BASE_DIR="$(dirname "$MAIN_FILE")"

# --- Resolve #include directives recursively (one pass) ---
resolve_includes() {
  local file="$1" base="$2" line inc
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*#include[[:space:]]+\"([^\"]+)\" ]]; then
      inc="${BASH_REMATCH[1]}"
      [[ "$inc" != /* ]] && inc="$base/$inc"
      [[ -f "$inc" ]] && resolve_includes "$inc" "$(dirname "$inc")"
    else
      printf '%s\n' "$line"
    fi
  done < "$file"
}

RESOLVED=$(mktemp)
trap 'rm -f "$RESOLVED"' EXIT
resolve_includes "$MAIN_FILE" "$BASE_DIR" > "$RESOLVED"

# --- Single awk pass: body extraction + markup stripping + per-section count ---
COUNTS=$(awk '
  BEGIN { in_body=0; in_code=0; in_figure=0; section="" }
  {
    if (!in_body) {
      if ($0 ~ /^[[:space:]]*=[[:space:]]+Introduction/) in_body=1
      else next
    }
    if ($0 ~ /^[[:space:]]*=[[:space:]]+Appendix/) exit
    if ($0 ~ /^[[:space:]]*\/\/[[:space:]]*=+[[:space:]]*(APPENDIX|APPENDICES|BACK MATTER)/) exit

    if ($0 ~ /^```/) { in_code = !in_code; next }
    if (in_code) next

    if ($0 ~ /^[[:space:]]*#figure\(/) { in_figure=1; next }
    if (in_figure) { if ($0 ~ /^\)/) in_figure=0; next }

    if ($0 ~ /^[[:space:]]*#long-caption/) next

    # Top-level section heading (= Foo, not == Foo)
    if ($0 ~ /^[[:space:]]*=[[:space:]]+/ && $0 !~ /^[[:space:]]*==/) {
      hd = $0; sub(/^[[:space:]]*=[[:space:]]+/, "", hd)
      if (!(hd in count)) { order[++nsec] = hd; count[hd] = 0 }
      section = hd
      count[section] += wcount(hd)
      next
    }

    if ($0 ~ /^[[:space:]]*#(set|show|let|import|include|counter|pagebreak|align|block|v|context)[[:space:](]/) next
    if (section == "") next

    line = $0
    sub(/\/\/.*/, "", line)
    gsub(/<[a-zA-Z_][a-zA-Z0-9_:.-]*>/, "", line)
    gsub(/#image\([^)]*\)/, "", line)
    gsub(/#[a-zA-Z_]+\([^)]*\)/, "", line)
    gsub(/#[a-zA-Z_]+\[/, "", line)
    gsub(/[\[\]]/, "", line)
    gsub(/\$[^$]*\$/, "", line)
    gsub(/\*/, "", line)
    sub(/^[[:space:]]*=+[[:space:]]*/, "", line)
    if (line ~ /^[[:space:]]*#/) next

    count[section] += wcount(line)
  }
  END {
    total = 0
    for (i=1; i<=nsec; i++) {
      printf "%s\t%d\n", order[i], count[order[i]]
      total += count[order[i]]
    }
    printf "__TOTAL__\t%d\n", total
  }
  function wcount(s,    arr, n, i, c) {
    n = split(s, arr, /[[:space:]]+/)
    c = 0
    for (i=1; i<=n; i++) if (arr[i] != "") c++
    return c
  }
' "$RESOLVED")

# --- Render ---
echo "========================================="
echo "  Thesis Word Count (main body only)"
echo "========================================="
echo
echo "  Section breakdown:"
echo "  -----------------------------------------"

WORD_COUNT=0
while IFS=$'\t' read -r name n; do
  if [[ "$name" == "__TOTAL__" ]]; then
    WORD_COUNT="$n"
  else
    printf "  %-30s %6d words\n" "$name" "$n"
  fi
done <<< "$COUNTS"

echo "  -----------------------------------------"
printf "  %-30s %6d words\n" "TOTAL" "$WORD_COUNT"
echo

if   (( WORD_COUNT < 10000 )); then echo "  ⚠️  Under minimum (10,000). ~$((10000 - WORD_COUNT)) words to go."
elif (( WORD_COUNT > 12000 )); then echo "  ⚠️  Over maximum (12,000) by ~$((WORD_COUNT - 12000)) words."
else                                echo "  ✅ Within target range (10,000–12,000)."
fi
echo
