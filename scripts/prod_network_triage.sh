#!/usr/bin/env bash
# Run this the SECOND someone says "it works locally"
# 
# Usage:
# ./prod_network_triage.sh api.prod.com 443 /health
# 
# Or SSH'd into a box:
# ./prod_network_triage.sh internal-api 8000 /status
# 

# === CONFIG ===
SERVICE_HOST="${1:-service.com}"
SERVICE_PORT="${2:-443}"
HEALTH_PATH="${3:-/health}"

echo "======================================="
echo "🐻 PROD NETWORK TRIAGE MODE ACTIVATED"
echo "Host: $SERVICE_HOST"
echo "Port: $SERVICE_PORT"
echo "Path: $HEALTH_PATH"
echo "======================================="
echo

# 1. DNS
echo "🧬 [1/7] DNS Resolution"
dig +short "$SERVICE_HOST" || echo "❌ DNS FAILED"
echo

# 2. Ping
echo "🏓 [2/7] Basic Connectivity (ping)"
ping -c 3 "$SERVICE_HOST" || echo "⚠️ Ping failed (may be blocked)"
echo

# 3. Port Reachability
echo "🔌 [3/7] Port Check"
nc -zv "$SERVICE_HOST" "$SERVICE_PORT" || echo "❌ Port NOT reachable"
echo

# 4. Traceroute
echo "🧭 [4/7] Traceroute (first 10 hops)"
traceroute "$SERVICE_HOST" | head -n 10
echo

# 5. HTTPS / API Health
echo "💓 [5/7] API Reachability Check"
curl -Iv --max-time 10 "https://$SERVICE_HOST$HEALTH_PATH" \
  || curl -Iv --max-time 10 "https://$SERVICE_HOST/" \
  || echo "❌ No HTTP response"
echo

# 6. Local Listening Ports
echo "👂 [6/7] Local Listening Services"
ss -tulpn
echo

# 7. Outbound Connectivity
echo "🌍 [7/7] Outbound Internet Test"
curl -I --max-time 5 https://google.com || echo "❌ Outbound traffic blocked"
echo

echo "======================================="
echo "✅ TRIAGE COMPLETE"
echo "======================================="
