# ==========================================
# STAGE 1: Builder Layer
# ==========================================
FROM alpine:latest AS builder

# Track the version for Renovate automation visibility
ARG ADGUARD_VERSION=v0.107.77
# Populated automatically by Docker Buildx during compilation
ARG TARGETARCH

RUN apk add --no-cache curl wget tar

WORKDIR /tmp

# Download and extract the architecture-appropriate AdGuard Home binary
RUN wget -q https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADGUARD_VERSION}/AdGuardHome_linux_${TARGETARCH}.tar.gz \
    && mkdir -p /opt \
    && tar -C /opt -f AdGuardHome_linux_${TARGETARCH}.tar.gz -x -z \
    && rm -rf /tmp/*

# Securely grab the authoritative DNS root zone hints file
RUN wget -q https://www.internic.net/domain/named.root -O /tmp/named.root

# ==========================================
# STAGE 2: Ultra-Light Runtime Layer
# ==========================================
FROM alpine:latest

# Install only necessary runtime components:
# - unbound: Core caching resolver
# - bash: To reliably run our multi-process orchestration entrypoint script
# - ca-certificates: Required for secure external connections
# - bind-tools, tcpdump, htop: Stripped diagnostic utilities
RUN apk add --no-cache \
    unbound \
    bash \
    ca-certificates \
    bind-tools \
    tcpdump \
    htop

# Re-create optimized running target environment layout
WORKDIR /opt/AdGuardHome
RUN mkdir -p /opt/AdGuardHome/work /opt/AdGuardHome/data /var/lib/unbound

# Copy pre-packaged items directly from the Builder stage
COPY --from=builder /opt/AdGuardHome/AdGuardHome /opt/AdGuardHome/AdGuardHome
COPY --from=builder /tmp/named.root /var/lib/unbound/root.hints

# Inject local infrastructure configurations
COPY adguard.conf /etc/unbound/unbound.conf
COPY entrypoint.sh /home/entrypoint.sh

RUN chmod +x /home/entrypoint.sh

WORKDIR /home

# Expose standard DNS and management interfaces
EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 3000
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/home/entrypoint.sh"]