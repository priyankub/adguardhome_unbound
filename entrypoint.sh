#!/bin/bash

# Start the Unbound service
service unbound start
# Start the AdGuardHome service
cd /opt/AdGuardHome
./AdGuardHome -s install -c /opt/AdGuardHome/data/AdGuardHome.yaml 

# Keep the container running
tail -f /dev/null
