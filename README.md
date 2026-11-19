# Parapet Lists

Curated DNS blocklist and allowlist for [Parapet](https://github.com/jmcglock/parapet).

## Overview

Two curated lists for DNS filtering—alphabetized, deduplicated, and one domain pattern per line, usable by any resolver that reads plain domain lists.

| List        | Domains | Description                    |
|-------------|---------|--------------------------------|
| Allowlist   | 52      | Bypass blocking for essential services |
| Blocklist   | 126     | Block ads, trackers, and telemetry     |

### Allowlist (`allowlist.txt`)
Domains that bypass DNS blocking rules. Includes:
- **Streaming**: Hulu, ESPN, Spotify, Tidal, SoundCloud, YouTube
- **Cloud & CDNs**: Cloudflare, Akamai, Oracle, Google APIs
- **Development**: GitHub, GitLab, ghcr.io, Rancher
- **OS updates**: Windows, Ubuntu, Apple
- **IoT & devices**: Tesla, Ubiquiti, Discord

### Blocklist (`blocklist.txt`)
Domains blocked for privacy and performance. Targets:
- **Ad networks**: DoubleClick, Google Ad Services, Amazon AdSystem, AdColony, Criteo, Outbrain, Taboola, PubMatic, OpenX, Teads
- **Analytics**: Google Analytics, Hotjar, Mouseflow, Comscore, Chartbeat
- **Telemetry**: Apple, Samsung, Xiaomi, Roku metrics
- **Social trackers**: Facebook Pixel, TikTok/LinkedIn ads
- **Attribution**: AppsFlyer, Branch.io, Bugsnag, Sentry

## Usage

### Parapet

Point `blocking` at the raw files. Parapet re-fetches them every `refreshInterval`
(or immediately via **Refresh lists** in the admin UI / `POST /api/v1/lists/refresh`):

```yaml
blocking:
  denylists:
    - https://raw.githubusercontent.com/jmcglock/parapet-lists/main/blocklist.txt
  allowlists:
    - https://raw.githubusercontent.com/jmcglock/parapet-lists/main/allowlist.txt
```

## Format

Both lists use wildcard notation (`*.domain.tld`) to match the base domain and all subdomains.

## Contributing

Pull requests welcome. Domains are kept alphabetized and deduplicated.

### Validation

CI runs `scripts/lint-lists.sh` on every push and pull request. It enforces:

- alphabetized blocks (comments and blank lines start a new block)
- no duplicate entries
- lowercase, bare `*.domain.tld` wildcard format (no schemes, paths, or trailing dots)
- no bare IPs, `localhost`, or single-label names
- no domain present in both lists

Run it locally before opening a PR:

```bash
./scripts/lint-lists.sh
# or lint a single file
./scripts/lint-lists.sh allowlist.txt
```

Failures print `file:line: message`; fix the offending line and re-run until it reports `all lists valid`.

## List freshness

Domains die. `scripts/check-nxdomain.sh` resolves every entry against a neutral public resolver (`1.1.1.1`, override with `RESOLVER=`) and reports:

- **NXDOMAIN** — gone for good; prune candidate
- **NO-A-RECORD** — registered but no A record (common for ad apexes that only serve subdomains); review
- **UNRESOLVED** — SERVFAIL/timeout; re-run before acting

It deliberately bypasses the local resolver: on a network running a filtering resolver, blocked domains answer NXDOMAIN and every blocklist entry would look dead.

```bash
./scripts/check-nxdomain.sh          # report only
./scripts/check-nxdomain.sh --fail   # exit 1 if any NXDOMAIN
```

A weekly GitHub Actions job (`nxdomain-report.yml`) posts the report to the run summary.

## Redundancy

`scripts/check-redundant.sh` flags entries already covered by a parent in the same list (e.g. `ads.example.com` when `*.example.com` is present). Report-only by default:

```bash
./scripts/check-redundant.sh
./scripts/check-redundant.sh --fail   # exit 1 if any redundant entry
```

A weekly job (`redundancy-report.yml`) posts the report to the run summary.

## License

Public domain — use freely.
