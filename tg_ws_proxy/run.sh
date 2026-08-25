#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

echo "[tg_ws_proxy] Starting with Supervisor configuration..."

# Проверяем доступ к файлу
if [ ! -f "$CONFIG_PATH" ]; then
    echo "[tg_ws_proxy] ERROR: Configuration file not found at $CONFIG_PATH"
    exit 1
fi

# Проверяем права
if [ ! -r "$CONFIG_PATH" ]; then
    echo "[tg_ws_proxy] ERROR: Cannot read $CONFIG_PATH (Permission denied)"
    echo "[tg_ws_proxy] Trying to read with sudo..."
    # Пробуем прочитать через sudo если доступно
    if command -v sudo >/dev/null 2>&1; then
        CONFIG_CONTENT=$(sudo cat "$CONFIG_PATH" 2>/dev/null || echo "")
        if [ -n "$CONFIG_CONTENT" ]; then
            SECRET=$(echo "$CONFIG_CONTENT" | jq --raw-output '.secret // ""')
            DC_IPS=$(echo "$CONFIG_CONTENT" | jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"')
            CF_WORKER=$(echo "$CONFIG_CONTENT" | jq --raw-output '.cf_worker // ""')
        else
            echo "[tg_ws_proxy] ERROR: Cannot read config even with sudo"
            exit 1
        fi
    else
        # Пробуем напрямую
        SECRET=$(jq --raw-output '.secret // ""' "$CONFIG_PATH" 2>/dev/null || echo "")
        DC_IPS=$(jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' "$CONFIG_PATH" 2>/dev/null || echo "2:149.154.167.220 4:149.154.167.220")
        CF_WORKER=$(jq --raw-output '.cf_worker // ""' "$CONFIG_PATH" 2>/dev/null || echo "")
    fi
else
    # Нормальное чтение
    SECRET=$(jq --raw-output '.secret // ""' "$CONFIG_PATH")
    DC_IPS=$(jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' "$CONFIG_PATH")
    CF_WORKER=$(jq --raw-output '.cf_worker // ""' "$CONFIG_PATH")
fi

# Формируем аргументы
ARGS="--host 0.0.0.0 --port 1443"

for dc in $DC_IPS; do
    if [ -n "$dc" ] && [ "$dc" != "null" ]; then
        ARGS="$ARGS --dc-ip $dc"
    fi
done

if [ -n "$SECRET" ] && [ "$SECRET" != "null" ] && [ "$SECRET" != "" ]; then
    ARGS="$ARGS --secret $SECRET"
    echo "[tg_ws_proxy] Secret configured (length: ${#SECRET})"
fi

if [ -n "$CF_WORKER" ] && [ "$CF_WORKER" != "null" ] && [ "$CF_WORKER" != "" ]; then
    ARGS="$ARGS --cfproxy-worker-domain $CF_WORKER"
    echo "[tg_ws_proxy] Cloudflare Worker configured: $CF_WORKER"
fi

echo "[tg_ws_proxy] Starting with arguments: $ARGS"

if [ ! -f "proxy/tg_ws_proxy.py" ]; then
    echo "[tg_ws_proxy] ERROR: proxy/tg_ws_proxy.py not found!"
    echo "[tg_ws_proxy] Contents of /app:"
    ls -la
    exit 1
fi

exec python -u proxy/tg_ws_proxy.py $ARGS