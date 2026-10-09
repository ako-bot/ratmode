#!/usr/bin/env bash
# Verifies that every `identifier` or `path/` in backticks in the index
# physically exists in the repository.
# Usage: ./scripts/verify_index.sh [INDEX.md] [root]
# Exit code: 0 if all match, 1 if discrepancies exist.

idx="${1:-INDEX.md}"
root="${2:-.}"

if [ ! -f "$idx" ]; then
  echo "Index file not found: $idx" >&2
  exit 2
fi

total=0
miss=0
excl=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
      --exclude-dir=build --exclude-dir=venv --exclude-dir=.venv \
      --exclude-dir=__pycache__ --exclude-dir=.next --exclude-dir=coverage \
      --exclude="$(basename "$idx")" --exclude="*.md" \
      --exclude-dir=indices)

while IFS= read -r tok; do
  [ -z "$tok" ] && continue
  total=$((total + 1))

  # Physical path or directory that exists
  [ -e "$root/$tok" ] && continue

  # Path ending with slash that does not exist
  if [[ "$tok" == */ ]]; then
    echo "MISSING path: $tok"
    miss=$((miss + 1))
    continue
  fi

  # Symbol: whole-word matching if alphanumeric identifier
  w=""  # intentionally unquoted below: empty means no flag
  [[ "$tok" =~ ^[A-Za-z0-9_]+$ ]] && w="-w"

  if ! grep -rqF $w "${excl[@]}" -- "$tok" "$root" 2>/dev/null; then
    echo "MISSING symbol: $tok"
    miss=$((miss + 1))
  fi
done < <(grep -o '`[^`]*`' "$idx" | tr -d '`' | sort -u)

echo "Verified: $total | Discrepancies: $miss"
[ "$miss" -eq 0 ]
