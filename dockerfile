FROM ubuntu:24.04

# Install curl, unbound, and wget
RUN apt-get update \
&& apt-get install -y curl wget unbound \
&& rm -rf /var/lib/apt/lists/*

# Download the AdGuardHome script
RUN curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

# Install the unbound root hints file
RUN wget https://www.internic.net/domain/named.root -qO- | tee /var/lib/unbound/root.hints

# Configure Unbound
COPY adguard.conf /etc/unbound/unbound.conf.d/adguard.conf

# Clean up and set the default user
RUN rm -rf /var/lib/apt/lists/* 