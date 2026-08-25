#!/bin/sh
set -eu

OPTIONS=/data/options.json

SECRET=$(jq -r '.secret // ""' "$OPTIONS")
DC_IPS=$(jq -r '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' "$OPTIONS")
CF_WORKER=$(jq -r '.cf_worker // ""' "$OPTIONS")

args="--host 0.0.0.0 --port 1443"

for dc in $DC_IPS; do
  args="$args --dc-ip $dc"
done

if [ -n "$SECRET" ]; then
  args="$args --secret $SECRET"
fi

if [ -n "$CF_WORKER" ]; then
  args="$args --cfproxy-worker-domain $CF_WORKER"
fi

echo "[tg_ws_proxy] Запуск: python proxy/tg_ws_proxy.py $args"
exec /opt/venv/bin/python -u proxy/tg_ws_proxy.py $args
