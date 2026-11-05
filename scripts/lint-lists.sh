#!/usr/bin/env bash
#
# Lint allowlist.txt and blocklist.txt.
#
# Checks, per list:
#   - entries are either an apex domain (domain.tld) or exactly *.domain.tld
#   - no bare IP addresses, localhost, or reserved local TLDs
#   - no duplicate entries
#   - entries are alphabetized inside each comment-separated block
# And across lists:
#   - no domain appears in both lists
#
# Errors are printed as file:line: message and the script exits non-zero.

set -uo pipefail

# Byte-wise collation, otherwise [A-Z] can match lowercase in UTF-8 locales.
export LC_ALL=C

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
allowlist=${1:-$root/allowlist.txt}
blocklist=${2:-$root/blocklist.txt}

errs=0

fail() {
  printf '%s:%s: %s\n' "$1" "$2" "$3" >&2
  errs=$((errs + 1))
}

# IPv4 in any dotted-quad form, including shorthand hosts like 127.1.
is_ipv4() {
  local re='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
  [[ $1 =~ $re ]]
}

is_reserved() {
  case $1 in
    localhost|localhost.localdomain) return 0 ;;
    *.localhost|*.local|*.lan|*.internal|*.test|*.invalid|*.example|*.home.arpa) return 0 ;;
  esac
  return 1
}

# valid_domain <apex> — sets domain_err with a reason on failure
valid_domain() {
  local d=$1
  domain_err=

  if [[ $d != *[.]* ]]; then
    domain_err="missing a TLD, expected domain.tld"
    return 1
  fi
  if [[ $d == *[!a-z0-9.-]* ]]; then
    domain_err="invalid characters, only a-z, 0-9, '-' and '.' are allowed"
    return 1
  fi
  if [[ $d == .* || $d == *. || $d == *..* ]]; then
    domain_err="empty label"
    return 1
  fi

  local label tld
  local IFS=.
  # shellcheck disable=SC2206
  local labels=($d)
  unset IFS

  tld=${labels[${#labels[@]}-1]}
  if [[ ! $tld =~ ^[a-z]{2,63}$ ]]; then
    domain_err="invalid TLD '$tld'"
    return 1
  fi

  for label in "${labels[@]}"; do
    if [[ ${#label} -gt 63 ]]; then
      domain_err="label '$label' is longer than 63 characters"
      return 1
    fi
    if [[ $label == -* || $label == *- ]]; then
      domain_err="label '$label' starts or ends with '-'"
      return 1
    fi
  done

  return 0
}

# Entry lists used for cross-list comparison.
a_bases=(); a_lines=()
b_bases=(); b_lines=()

# lint_list <file> <allow|block>
lint_list() {
  local file=$1 which=$2
  local raw line base key prev_key prev_raw prev_line
  local lineno=0 count=0
  local -a seen_raw=() seen_lines=()

  while IFS= read -r raw || [[ -n $raw ]]; do
    lineno=$((lineno + 1))

    if [[ $raw == *$'\r'* ]]; then
      fail "$file" "$lineno" "CRLF line ending, expected LF"
      raw=${raw//$'\r'/}
    fi

    # Trim trailing whitespace but complain about it.
    line=${raw%"${raw##*[![:space:]]}"}
    if [[ $line != "$raw" ]]; then
      fail "$file" "$lineno" "trailing whitespace"
    fi

    # Comments and blank lines start a new sorting block.
    if [[ -z $line || $line == \#* ]]; then
      prev_key= prev_raw= prev_line=
      continue
    fi

    if [[ $line =~ [[:space:]] ]]; then
      fail "$file" "$lineno" "'$line' contains whitespace"
      continue
    fi

    if [[ $line == *[A-Z]* ]]; then
      fail "$file" "$lineno" "'$line' must be lowercase"
      continue
    fi

    case $line in
      *'*'*)
        if [[ $line != \*.* ]]; then
          fail "$file" "$lineno" "'$line' has a malformed wildcard, expected '*.domain.tld'"
          continue
        fi
        base=${line:2}
        if [[ $base == *'*'* ]]; then
          fail "$file" "$lineno" "'$line' has more than one wildcard, expected '*.domain.tld'"
          continue
        fi
        ;;
      *)
        base=$line
        ;;
    esac

    if [[ -z $base ]]; then
      fail "$file" "$lineno" "'$line' is empty after the wildcard, expected '*.domain.tld'"
      continue
    fi

    if is_ipv4 "$base" || [[ $base == *:* || $base == \[* ]]; then
      fail "$file" "$lineno" "'$line' is a bare IP address, use a domain name"
      continue
    fi

    if ! valid_domain "$base"; then
      fail "$file" "$lineno" "'$line': $domain_err"
      continue
    fi

    if is_reserved "$base"; then
      fail "$file" "$lineno" "'$line' is a local or reserved domain, not a public domain"
      continue
    fi

    local i duplicate=
    if [[ ${#seen_raw[@]} -gt 0 ]]; then
      for i in "${!seen_raw[@]}"; do
        if [[ ${seen_raw[$i]} == "$line" ]]; then
          duplicate="${seen_lines[$i]}"
          break
        fi
      done
    fi
    if [[ -n $duplicate ]]; then
      fail "$file" "$lineno" "duplicate entry '$line' (first seen on line $duplicate)"
      continue
    fi
    seen_raw+=("$line")
    seen_lines+=("$lineno")

    # Alphabetical order by apex domain. Ties (domain.tld and *.domain.tld)
    # may appear in either order.
    key="$base"
    if [[ -n $prev_key && $key != "$prev_key" && $key < $prev_key ]]; then
      fail "$file" "$lineno" "'$line' is out of order, should sort before '$prev_raw' (line $prev_line)"
    fi
    prev_key=$key prev_raw=$line prev_line=$lineno

    if [[ $which == allow ]]; then
      a_bases+=("$base"); a_lines+=("$lineno")
    else
      b_bases+=("$base"); b_lines+=("$lineno")
    fi
    count=$((count + 1))
  done < "$file"

  printf 'ok: %s (%d entries)\n' "$file" "$count"
}

for f in "$allowlist" "$blocklist"; do
  if [[ ! -f $f ]]; then
    printf '%s: file not found\n' "$f" >&2
    errs=$((errs + 1))
  fi
done

if [[ $errs -gt 0 ]]; then
  exit 1
fi

lint_list "$allowlist" allow
lint_list "$blocklist" block

# Cross-list check, compared by apex domain so *.example.com collides with
# example.com in the other list.
if [[ ${#a_bases[@]} -gt 0 && ${#b_bases[@]} -gt 0 ]]; then
  local_i=0
  for abase in "${a_bases[@]}"; do
    aline=${a_lines[$local_i]}
    local_i=$((local_i + 1))
    for j in "${!b_bases[@]}"; do
      if [[ ${b_bases[$j]} == "$abase" ]]; then
        fail "$allowlist" "$aline" "'$abase' is also in $blocklist line ${b_lines[$j]}"
        break
      fi
    done
  done
  unset local_i
fi

if [[ $errs -gt 0 ]]; then
  printf '\n%d problem(s) found\n' "$errs" >&2
  exit 1
fi

printf 'all lists valid\n'
