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

```

### Initial Bootstrap Step

1. Start the stack: `docker compose up -d`
2. Navigate to `http://<YOUR_SERVER_IP>:3000` to run the one-time AdGuard setup wizard.
3. **Crucial Dashboard Settings:** Inside the wizard or later under Settings, configure the **Upstream DNS Server** entry to point exclusively to:
```text
127.0.0.1:53

```


This locks AdGuard Home into forcing its resolving tracking downward through the local Unbound recursion path.

---

## Automated Repository Lifecycle

This repository utilizes fully automated GitOps pipelines to stay up to date and clean of security vulnerabilities:

### 1. Automated Dependency Tracking (Renovate)

* **Frequency:** Checks for upstream releases continuously.
* **Stability Gate:** Implements a strict `3 days` minimum release maturity window. Renovate will not touch a release until it has sat unchanged for 72 hours, insulating your infrastructure from day-one regressions.
* **Auto-Merge:** If upstream minor or patch releases pass full validation, Renovate automatically handles the merge back into the main branch.

### 2. Multi-Architecture Compilation (GitHub Actions)

On every commit to `main`, the `.github/workflows/deploy.yml` pipeline triggers:

* Emulates environment layouts via `QEMU`.
* Leverages `Docker Buildx` to build and tag `linux/amd64` and `linux/arm64` image profiles concurrently.
* Publishes a combined manifest to the GitHub Container Registry (`ghcr.io`).

---

## Development & Manual Builds

If you need to make changes to `entrypoint.sh` or `adguard.conf` and test locally:

### Prerequisites

Ensure your local Docker installation has Buildx active. If building across architectures manually on your machine, register QEMU handlers:

```bash
docker run --privileged --rm tonistiigi/binfmt --install all

```

### Build Image Locally

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/priyankub/adguardhome_unbound:local \
  --load .

```

---

## Security Policy

Please consult [SECURITY.md](SECURITY.md) to report vulnerabilities or configuration bugs privately. Public issues exposing active exploit logic are explicitly discouraged.