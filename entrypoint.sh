#!/bin/bash

# Terminate execution if any setup command fails before monitoring starts
set -e

echo "[INIT] Starting AdGuard Home + Unbound Multi-Arch Container..."

# Cleanup function handles termination signals gracefully
cleanup() {
    echo "[INIT] Caught termination signal (SIGTERM/SIGINT). Initiating graceful shutdown..."
    
    # Gracefully terminate Unbound if running
    if [ -n "$UNBOUND_PID" ] && kill -0 "$UNBOUND_PID" 2>/dev/null; then
        echo "[INIT] Sending SIGTERM to Unbound (PID: $UNBOUND_PID)..."
        kill -TERM "$UNBOUND_PID"
    fi

    # Gracefully terminate AdGuard Home if running
    if [ -n "$ADGUARD_PID" ] && kill -0 "$ADGUARD_PID" 2>/dev/null; then
        echo "[INIT] Sending SIGTERM to AdGuard Home (PID: $ADGUARD_PID)..."
        kill -TERM "$ADGUARD_PID"
    fi

    # Wait for child processes to finish flushing data and exit
    wait "$UNBOUND_PID" 2>/dev/null
    wait "$ADGUARD_PID" 2>/dev/null
    
    echo "[INIT] All services stopped cleanly. Container exiting."
    exit 0
}

# Register the cleanup function to trap signals
trap cleanup SIGTERM SIGINT

# Ensure necessary runtime directory structures are initialized
mkdir -p /opt/AdGuardHome/work /opt/AdGuardHome/data /var/run/unbound

# 1. Start Unbound in the foreground using Alpine's native configuration address
echo "[INIT] Launching Unbound DNS Resolver..."
unbound -d -c /etc/unbound/unbound.conf &
UNBOUND_PID=$!

# 2. Start AdGuard Home directly, mapping persistent directories explicitly
echo "[INIT] Launching AdGuard Home..."
cd /opt/AdGuardHome
./AdGuardHome \
    --work-dir /opt/AdGuardHome/work \
    --config /opt/AdGuardHome/data/AdGuardHome.yaml \
    --no-check-update &
ADGUARD_PID=$!

# Disable exit-on-error so the script doesn't abort before executing cleanup actions
set +e

echo "[INIT] Both services are running. Monitoring process lifecycles..."
echo "       -> Unbound PID: $UNBOUND_PID"
echo "       -> AdGuard Home PID: $ADGUARD_PID"

# Wait -n blocks until EITHER process exits
wait -n

# Capture the exit code of the failing service
EXIT_CODE=$?
echo "[CRITICAL] A critical service has terminated unexpectedly with exit status $EXIT_CODE."

# Run cleanup to stop the surviving process so Docker can cleanly restart the container
cleanup