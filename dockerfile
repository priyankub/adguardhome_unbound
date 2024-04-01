FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Install curl, unbound, and wget
RUN apt-get update \
&& apt-get install -y curl wget unbound dnsutils iproute2 traceroute nano htop tcpdump \
&& rm -rf /var/lib/apt/lists/*

# Download the AdGuardHome script
#RUN curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v -c /opt/AdGuardHome/data/AdGuardHome.yaml
WORKDIR /tmp
RUN wget https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz
RUN mkdir /opt/AdGuardHome
RUN tar -C /opt -f AdGuardHome_linux_amd64.tar.gz -x -z
WORKDIR /opt/AdGuardHome
RUN ./AdGuardHome -s install -c /opt/AdGuardHome/data/AdGuardHome.yaml 
# Install the unbound root hints file
RUN wget https://www.internic.net/domain/named.root -qO- | tee /var/lib/unbound/root.hints

# Configure Unbound
COPY adguard.conf /etc/unbound/unbound.conf.d/adguard.conf
COPY entrypoint.sh /home/entrypoint.sh

# Set working directory and cleanup
RUN rm -rf /tmp/*
WORKDIR /home

EXPOSE 53

# Define entrypoint
ENTRYPOINT ["bash", "./entrypoint.sh"]