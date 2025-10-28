#!/bin/sh
set -e

BLUE_URL="http://app_blue:8080/healthz"
GREEN_URL="http://app_green:8080/healthz"
CONF_TEMPLATE="/etc/nginx/templates/nginx.conf.template"
CONF_FINAL="/etc/nginx/nginx.conf"

ACTIVE=$ACTIVE_POOL

echo "[health-agent] Starting with ACTIVE_POOL=$ACTIVE"

while true; do
  if curl -sf --max-time 2 "$BLUE_URL" >/dev/null; then
      # Blue is healthy
      if [ "$ACTIVE" != "blue" ]; then
          echo "[health-agent] Blue recovered → switching back"
          ACTIVE="blue"
          export ACTIVE_POOL=blue
          envsubst '$ACTIVE_POOL $RELEASE_ID' < "$CONF_TEMPLATE" > "$CONF_FINAL"
          nginx -s reload
      fi
  else
      # Blue is down
      if [ "$ACTIVE" != "green" ]; then
          echo "[health-agent] Blue unhealthy → switching to green"
          ACTIVE="green"
          export ACTIVE_POOL=green
          envsubst '$ACTIVE_POOL $RELEASE_ID' < "$CONF_TEMPLATE" > "$CONF_FINAL"
          nginx -s reload
      fi
  fi
  sleep 5
done
