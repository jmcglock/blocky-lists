# Blocky Lists

DNS allowlist and blocklist configurations for Blocky and NextDNS to manage domain filtering.

## Overview

Two curated lists for DNS filtering—alphabetized, deduplicated, and maintained for Blocky/NextDNS compatibility.

| List        | Domains | Description                    |
|-------------|---------|--------------------------------|
| Allowlist   | 57      | Bypass blocking for essential services |
| Blocklist   | 90      | Block ads, trackers, and telemetry     |

### Allowlist (`allowlist.txt`)
Domains that bypass DNS blocking rules. Includes:
- **Streaming**: Hulu, ESPN, Spotify, Tidal, SoundCloud, YouTube
- **Cloud & CDNs**: Cloudflare, Akamai, Oracle, Google APIs
- **Development**: GitHub, GitLab, ghcr.io, Rancher
- **OS updates**: Windows, Ubuntu, Apple
- **IoT & devices**: Tesla, Ubiquiti, Discord

### Blocklist (`blocklist.txt`)
Domains blocked for privacy and performance. Targets:
- **Ad networks**: DoubleClick, AdColony, Criteo, Outbrain, Taboola, PubMatic
- **Analytics**: Google Analytics, Hotjar, Mouseflow, Comscore, Chartbeat
- **Telemetry**: Apple, Samsung, Xiaomi, Roku metrics
- **Social trackers**: Facebook Pixel, TikTok/LinkedIn ads
- **Attribution**: AppsFlyer, Branch.io, Bugsnag, Sentry

## Usage

### Blocky

Add both lists to your `config.yml`:

```yaml
blocking:
  blackLists:
    ads:
      - https://raw.githubusercontent.com/jmcglock/blocky-lists/main/blocklist.txt
  whiteLists:
    ads:
      - https://raw.githubusercontent.com/jmcglock/blocky-lists/main/allowlist.txt
```

### NextDNS

- **Denylist**: Add the blocklist URL to block ads and trackers
- **Allowlist**: Add the allowlist URL to permit essential domains

## Format

Both lists use wildcard notation (`*.domain.tld`) to match the base domain and all subdomains.

## Contributing

Pull requests welcome. Domains are kept alphabetized and deduplicated.

## License

Public domain — use freely.
