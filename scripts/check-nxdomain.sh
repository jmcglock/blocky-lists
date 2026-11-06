#!/usr/bin/env bash
#
# Check that every listed domain still resolves.
#
#   NXDOMAIN    → domain is gone; prune candidate
#   NO-A-RECORD → registered, but no A record; review
#   UNRESOLVED  → SERVFAIL / timeout (may be local DNS, re-run before pruning)
#
# Report-only by default (exit 0). With --fail, exits 1 when any NXDOMAIN
# is found, so the check can gate CI if wanted.
#
# Queries a neutral public resolver, NOT the local one — on a network that
# runs Blocky, blocked domains answer NXDOMAIN and every blocklist entry
# would look dead. Override with RESOLVER=<ip> if needed.

set -uo pipefail

RESOLVER=${RESOLVER:-1.1.1.1}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Internal mode: resolve one domain (used for parallel fan-out via xargs).
if [ "${1:-}" = "--check-one" ]; then
  src=$2 d=$3
  out=$(dig @"$RESOLVER" +time=3 +tries=1 +noall +comments A "$d" 2>/dev/null)
  status=$(printf '%s' "$out" | sed -n 's/.*status: \([A-Z-]*\).*/\1/p' | head -1)
  answers=$(printf '%s' "$out" | sed -n 's/.* ANSWER: \([0-9][0-9]*\),.*/\1/p' | head -1)
  case "$status" in
    NXDOMAIN) printf 'NXDOMAIN\t%s\t%s\n' "$d" "$src" ;;
    NOERROR)
      if [ "${answers:-0}" -eq 0 ]; then
        printf 'NO-A-RECORD\t%s\t%s\n' "$d" "$src"
      fi
      ;;
    *) printf 'UNRESOLVED\t%s\t%s\n' "$d" "$src" ;;
  esac
  exit 0
fi

fail_on_nx=0
[ "${1:-}" = "--fail" ] && fail_on_nx=1

# Emit "source-file domain" for every entry in both lists.
entries() {
  local f
  for f in "$root/allowlist.txt" "$root/blocklist.txt"; do
    sed -e 's/#.*$//' -e 's/^\*\.//' "$f" \
      | grep -E '^[A-Za-z0-9.-]+$' \
      | sed "s|^|$(basename "$f") |"
  done | sort -u
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

entries | xargs -P 8 -n 2 "$0" --check-one >"$tmp"

sort "$tmp" -o "$tmp"

nx=$(grep -c '^NXDOMAIN' "$tmp" || true)
na=$(grep -c '^NO-A-RECORD' "$tmp" || true)
un=$(grep -c '^UNRESOLVED' "$tmp" || true)

if [ -s "$tmp" ]; then
  printf 'STATUS\tDOMAIN\tLIST\n'
  cat "$tmp"
fi
printf '\nNXDOMAIN: %s · no A record: %s · unresolved: %s\n' "$nx" "$na" "$un"

[ "$fail_on_nx" -eq 1 ] && [ "$nx" -gt 0 ] && exit 1
exit 0
