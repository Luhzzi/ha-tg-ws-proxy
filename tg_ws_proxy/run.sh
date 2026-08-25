#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

echo "[tg_ws_proxy] Starting with Supervisor configuration..."

# Проверяем наличие конфига
if [ ! -f "$CONFIG_PATH" ]; then
    echo "[tg_ws_proxy] ERROR: Configuration file not found at $CONFIG_PATH"
    exit 1
fi

# Читаем конфигурацию
SECRET=$(jq --raw-output '.secret // ""' "$CONFIG_PATH")
DC_IPS=$(jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' "$CONFIG_PATH")
CF_WORKER=$(jq --raw-output '.cf_worker // ""' "$CONFIG_PATH")

# Формируем аргументы
ARGS="--host 0.0.0.0 --port 1443"

# Добавляем DC IPs
for dc in $DC_IPS; do
    if [ -n "$dc" ] && [ "$dc" != "null" ]; then
        ARGS="$ARGS --dc-ip $dc"
    fi
done

# Добавляем секрет
if [ -n "$SECRET" ] && [ "$SECRET" != "null" ] && [ "$SECRET" != "" ]; then
    ARGS="$ARGS --secret $SECRET"
    echo "[tg_ws_proxy] Secret configured (length: ${#SECRET})"
fi

# Добавляем Cloudflare Worker
if [ -n "$CF_WORKER" ] && [ "$CF_WORKER" != "null" ] && [ "$CF_WORKER" != "" ]; then
    ARGS="$ARGS --cfproxy-worker-domain $CF_WORKER"
    echo "[tg_ws_proxy] Cloudflare Worker configured: $CF_WORKER"
fi

echo "[tg_ws_proxy] Starting with arguments: $ARGS"

# Проверяем наличие скрипта
if [ ! -f "proxy/tg_ws_proxy.py" ]; then
    echo "[tg_ws_proxy] ERROR: proxy/tg_ws_proxy.py not found!"
    echo "[tg_ws_proxy] Contents of /app:"
    ls -la
    exit 1
fi

# Запускаем прокси
exec python -u proxy/tg_ws_proxy.py $ARGS