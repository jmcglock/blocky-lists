# Blocky Lists

DNS allowlist configuration for Blocky and NextDNS to permit essential domains.

## Overview

This repository contains a curated allowlist of domains that should bypass DNS blocking rules. These domains are commonly required for:

- Streaming services (Hulu, ESPN, Spotify, etc.)
- Cloud services and CDNs (Cloudflare, Akamai, etc.)
- Development tools (GitHub, GitLab, Docker registries)
- Operating system updates (Windows, Ubuntu, macOS)
- Smart home and IoT devices (Tesla, Ubiquiti)

## Usage

### Blocky

Add the allowlist to your `config.yml`:

```yaml
blocking:
  whiteLists:
    ads:
      - https://raw.githubusercontent.com/jmcglock/blocky-lists/main/allowlist.txt
```

### NextDNS

Import the allowlist directly in your NextDNS configuration or manually add domains from the list.

## Format

The allowlist uses wildcard notation (`*.domain.tld`) to permit both the base domain and all subdomains.

## Contributing

Feel free to submit pull requests to add or remove domains as needed.

## License

Public domain - use freely.
