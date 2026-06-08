FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
# Explicitly track the version so Renovate can see it
ARG ADGUARD_VERSION=v0.107.77
# Native Docker variable populated automatically during build (amd64, arm64)
ARG TARGETARCH

# Install system dependencies
RUN apt-get update \
    && apt-get install -y curl wget unbound dnsutils iproute2 traceroute nano htop tcpdump iputils-ping telnet \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt \
    && apt-get clean

# Download the architecture-appropriate AdGuardHome binary dynamically
WORKDIR /tmp
RUN wget https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADGUARD_VERSION}/AdGuardHome_linux_${TARGETARCH}.tar.gz \
    && mkdir -p /opt \
    && tar -C /opt -f AdGuardHome_linux_${TARGETARCH}.tar.gz -x -z \
    && rm -rf /tmp/*

WORKDIR /opt/AdGuardHome
RUN ./AdGuardHome -s install -c /opt/AdGuardHome/data/AdGuardHome.yaml 

# Install the unbound root hints file
RUN wget https://www.internic.net/domain/named.root -qO- | tee /var/lib/unbound/root.hints

# Configure Unbound
COPY adguard.conf /etc/unbound/unbound.conf.d/adguard.conf
COPY entrypoint.sh /home/entrypoint.sh

WORKDIR /home

EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 3000
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["bash", "./entrypoint.sh"]