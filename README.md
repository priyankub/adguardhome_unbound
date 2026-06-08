# AdGuard Home + Unbound (Multi-Arch GitOps Container)

This repository maintains a high-performance, secure, and privacy-focused DNS resolving solution. It packages **AdGuard Home** for network-wide ad blocking, privacy tracking protection, and graphical logging alongside **Unbound** configured as a local validating, recursive caching DNS resolver.

This image is explicitly designed to natively target both Intel/AMD (`amd64`) and ARM (`arm64`/Raspberry Pi 5) architectures through a unified, automated container pipeline.

---

## Architecture Overview

Instead of forwarding DNS queries upstream to third-party public DNS providers (like Google or Cloudflare), this image isolates your query footprint:

1. **Client Request:** Your local device sends a DNS request to port `53`.
2. **Filtering Layer:** **AdGuard Home** intercepts the request and matches it against your configured blocklists.
3. **Recursive Resolution:** If allowed, AdGuard passes the query internally via localhost (`127.0.0.1:53`) to **Unbound**.
4. **Root Authority Queries:** Unbound utilizes a pre-baked root hints zone file to securely traverse the official DNS root authority chain directly, verifying DNSSEC cryptographic signatures on the way back down.

---

## Production GitOps Integration (docker-compose)

To integrate this pre-built, multi-architecture image smoothly alongside edge routers (like Traefik) without port collisions, use the following network blueprint.

Create a `docker-compose.yml` file within your infrastructure repository layout:

```yaml
services:
  adguard_unbound:
    image: ghcr.io/priyankub/adguardhome_unbound:latest
    container_name: adguard_unbound
    restart: unless-stopped
    # Required: Host network mode preserves the native client source IPs 
    # so AdGuard's dashboard logs show individual device names instead of the container gateway IP.
    network_mode: host
    volumes:
      - /host:/opt/AdGuardHome/work
      - /host:/opt/AdGuardHome/data