#!/usr/bin/env bash
#
# Flag list entries that are already covered by another entry in the same list.
# e.g. "ads.example.com" when "*.example.com" (or "example.com") is also present.
#
# Report-only by default (exit 0). With --fail, exits 1 when any redundant
# entry is found.

set -uo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail_on=0
[ "${1:-}" = "--fail" ] && fail_on=1

errs=0
for list in allowlist.txt blocklist.txt; do
  file="$root/$list"
  tmp=$(mktemp)
  sed -e 's/#.*$//' -e 's/^\*\.//' "$file" | grep -E '^[A-Za-z0-9.-]+$' | sort -u >"$tmp"
  # nested loop over file lines
  while IFS= read -r x; do
    [ -z "$x" ] && continue
    while IFS= read -r y; do
      [ -z "$y" ] && continue
      [ "$x" = "$y" ] && continue
      if [[ "$x" == *."$y" ]]; then
        printf '%s: redundant: %s is covered by %s\n' "$list" "$x" "$y"
        errs=$((errs + 1))
        break
      fi
    done <"$tmp"
  done <"$tmp"
  rm -f "$tmp"
done

[ "$fail_on" -eq 1 ] && [ "$errs" -gt 0 ] && exit 1
exit 0
