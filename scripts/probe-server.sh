#!/usr/bin/env bash
# Probe the mock server to verify it is reachable from the Copilot environment.
# Run this script to confirm that background services started in copilot-setup-steps
# are accessible at localhost within the agent session.
set -euo pipefail

URL="http://localhost:8080/ping.json"
OUT="server-probe.txt"

echo "Probing $URL ..."
RESPONSE=$(curl -sf "$URL")

echo "$RESPONSE" | tee "$OUT"
echo ""
echo "SUCCESS: mock server is reachable from this environment."
echo "Response written to $OUT"
