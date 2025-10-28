#!/bin/sh
set -eu

BLUE_URL="http://app_blue:8080/healthz"
GREEN_URL="http://app_green:8080/healthz"
CONF_TEMPLATE="/etc/nginx/templates/nginx.conf.template"
CONF_FINAL="/etc/nginx/nginx.conf"
STATE_FILE="/tmp/active_pool.state"

ACTIVE="${ACTIVE_POOL:-blue}"
echo "$ACTIVE" > "$STATE_FILE"

log() {
  echo "[health-agent][$(date '+%H:%M:%S')] $*"
}

log "Starting Health Agent | ACTIVE_POOL=$ACTIVE"

sleep 5  # give apps time to boot

while true; do
  if curl -sf --max-time 2 "$BLUE_URL" >/dev/null; then
      # Blue healthy
      if [ "$ACTIVE" != "blue" ]; then
          log "Blue recovered → switching back"
          ACTIVE="blue"
          echo "$ACTIVE" > "$STATE_FILE"
          export ACTIVE_POOL=$ACTIVE
          envsubst '$ACTIVE_POOL $RELEASE_ID' < "$CONF_TEMPLATE" > "$CONF_FINAL"
          if nginx -t; then
              nginx -s reload
              log "Switched to BLUE and reloaded Nginx ✅"
          else
              log "Nginx config invalid, keeping current config ❌"
          fi
      fi
  else
      # Blue unhealthy
      if [ "$ACTIVE" != "green" ]; then
          log "Blue unhealthy → switching to green"
          ACTIVE="green"
          echo "$ACTIVE" > "$STATE_FILE"
          export ACTIVE_POOL=$ACTIVE
          envsubst '$ACTIVE_POOL $RELEASE_ID' < "$CONF_TEMPLATE" > "$CONF_FINAL"
          if nginx -t; then
              nginx -s reload
              log "Switched to GREEN and reloaded Nginx ✅"
          else
              log "Nginx config invalid, keeping current config ❌"
          fi
      fi
  fi
  sleep 5
done
