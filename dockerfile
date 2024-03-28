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

# Expose port 80, 443, 53, 3000 to the outside world
EXPOSE 53
EXPOSE 80
EXPOSE 443
EXPOSE 3000

# Clean up and set the default user
RUN rm -rf /var/lib/apt/lists/* 