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
if [ -r "$CONFIG_PATH" ]; then
    HOST=$(jq --raw-output '.host // "0.0.0.0"' "$CONFIG_PATH" 2>/dev/null || echo "0.0.0.0")
    PORT=$(jq --raw-output '.port // 1443' "$CONFIG_PATH" 2>/dev/null || echo "1443")
    SECRET=$(jq --raw-output '.secret // ""' "$CONFIG_PATH" 2>/dev/null || echo "")
    DC_IPS=$(jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' "$CONFIG_PATH" 2>/dev/null || echo "2:149.154.167.220 4:149.154.167.220")
    CF_WORKER=$(jq --raw-output '.cf_worker // ""' "$CONFIG_PATH" 2>/dev/null || echo "")
else
    echo "[tg_ws_proxy] WARNING: Cannot read config directly, trying with cat..."
    CONFIG_CONTENT=$(cat "$CONFIG_PATH" 2>/dev/null || echo "")
    if [ -n "$CONFIG_CONTENT" ]; then
        HOST=$(echo "$CONFIG_CONTENT" | jq --raw-output '.host // "0.0.0.0"' 2>/dev/null || echo "0.0.0.0")
        PORT=$(echo "$CONFIG_CONTENT" | jq --raw-output '.port // 1443' 2>/dev/null || echo "1443")
        SECRET=$(echo "$CONFIG_CONTENT" | jq --raw-output '.secret // ""' 2>/dev/null || echo "")
        DC_IPS=$(echo "$CONFIG_CONTENT" | jq --raw-output '.dc_ips // "2:149.154.167.220 4:149.154.167.220"' 2>/dev/null || echo "2:149.154.167.220 4:149.154.167.220")
        CF_WORKER=$(echo "$CONFIG_CONTENT" | jq --raw-output '.cf_worker // ""' 2>/dev/null || echo "")
    else
        echo "[tg_ws_proxy] ERROR: Cannot read config file"
        HOST="0.0.0.0"
        PORT="1443"
        SECRET=""
        DC_IPS="2:149.154.167.220 4:149.154.167.220"
        CF_WORKER=""
    fi
fi

# Логируем прочитанные значения
echo "[tg_ws_proxy] Config loaded:"
echo "[tg_ws_proxy]   HOST: ${HOST}"
echo "[tg_ws_proxy]   PORT: ${PORT}"
echo "[tg_ws_proxy]   SECRET: ${SECRET:-<empty>}"
echo "[tg_ws_proxy]   DC_IPS: ${DC_IPS}"
echo "[tg_ws_proxy]   CF_WORKER: ${CF_WORKER:-<empty>}"

# Формируем аргументы
ARGS="--host ${HOST} --port ${PORT}"

# Добавляем DC IPs
if [ -n "$DC_IPS" ] && [ "$DC_IPS" != "null" ]; then
    for dc in $DC_IPS; do
        if [ -n "$dc" ] && [ "$dc" != "null" ]; then
            ARGS="$ARGS --dc-ip $dc"
        fi
    done
fi

# Добавляем секрет (если указан)
if [ -n "$SECRET" ] && [ "$SECRET" != "null" ] && [ "$SECRET" != "" ]; then
    ARGS="$ARGS --secret $SECRET"
    echo "[tg_ws_proxy] Secret configured (length: ${#SECRET})"
fi

# Добавляем Cloudflare Worker (если указан)
if [ -n "$CF_WORKER" ] && [ "$CF_WORKER" != "null" ] && [ "$CF_WORKER" != "" ]; then
    ARGS="$ARGS --cfproxy-worker-domain $CF_WORKER"
    echo "[tg_ws_proxy] Cloudflare Worker configured: $CF_WORKER"
fi

echo "[tg_ws_proxy] Final arguments: $ARGS"

# Проверяем наличие скрипта
if [ ! -f "proxy/tg_ws_proxy.py" ]; then
    echo "[tg_ws_proxy] ERROR: proxy/tg_ws_proxy.py not found!"
    exit 1
fi

# Запускаем прокси
exec python -u proxy/tg_ws_proxy.py $ARGS