# Blocky Lists

DNS allowlist and blocklist configurations for Blocky and NextDNS to manage domain filtering.

## Overview

This repository contains two curated lists for DNS filtering:

### Allowlist (`allowlist.txt`)
Domains that should bypass DNS blocking rules. Commonly required for:
- Streaming services (Hulu, ESPN, Spotify, etc.)
- Cloud services and CDNs (Cloudflare, Akamai, etc.)
- Development tools (GitHub, GitLab, Docker registries)
- Operating system updates (Windows, Ubuntu, macOS)
- Smart home and IoT devices (Tesla, Ubiquiti)

### Blocklist (`blocklist.txt`)
Domains to block for privacy and performance. Targets:
- Advertising networks (DoubleClick, AdColony, etc.)
- Analytics trackers (Google Analytics, Hotjar, Mouseflow)
- Telemetry services (Apple, Samsung, Xiaomi metrics)
- Social media trackers (Facebook Pixel, TikTok ads)
- Error reporting services (Bugsnag, Sentry)

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

Import the lists directly in your NextDNS configuration:
- **Denylist**: Add the blocklist URL to block ads and trackers
- **Allowlist**: Add the allowlist URL to permit essential domains

Alternatively, manually add domains from either list as needed.

## Format

Both lists use wildcard notation (`*.domain.tld`) to match the base domain and all subdomains:
- **Allowlist**: Permits matched domains and subdomains
- **Blocklist**: Blocks matched domains and subdomains

## Contributing

Feel free to submit pull requests to add or remove domains as needed.

## License

Public domain - use freely.
