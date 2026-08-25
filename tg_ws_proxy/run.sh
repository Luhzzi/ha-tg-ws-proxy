#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

# Читаем конфигурацию
SECRET=$(jq --raw-output '.secret // ""' $CONFIG_PATH)
DC_IPS=$(jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' $CONFIG_PATH)
CF_WORKER=$(jq --raw-output '.cf_worker // ""' $CONFIG_PATH)

# Формируем аргументы
ARGS="--host 0.0.0.0 --port 1443"

# Добавляем DC IPs
for dc in $DC_IPS; do
    ARGS="$ARGS --dc-ip $dc"
done

# Добавляем секрет
if [ ! -z "$SECRET" ] && [ "$SECRET" != "null" ]; then
    ARGS="$ARGS --secret $SECRET"
fi

# Добавляем Cloudflare Worker
if [ ! -z "$CF_WORKER" ] && [ "$CF_WORKER" != "null" ]; then
    ARGS="$ARGS --cfproxy-worker-domain $CF_WORKER"
fi

echo "[tg_ws_proxy] Starting proxy with arguments: $ARGS"

# Запускаем прокси (в готовом образе путь может отличаться)
exec python3 /app/proxy/tg_ws_proxy.py $ARGS