#!/usr/bin/env bash
# update-readme-counts.sh — refresh domain counts in README.md.

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
allow=$(grep -v '^#' "$root/allowlist.txt" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
block=$(grep -v '^#' "$root/blocklist.txt" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')

python3 - "$root/README.md" "$allow" "$block" <<'PY'
import re, sys
path, allow, block = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path).read()
s = re.sub(r"(\| Allowlist\s*\|\s*)\d+(\s*\|)", rf"\g<1>{allow}\2", s)
s = re.sub(r"(\| Blocklist\s*\|\s*)\d+(\s*\|)", rf"\g<1>{block}\2", s)
open(path, "w").write(s)
PY
echo "Updated counts: allowlist=$allow blocklist=$block"
