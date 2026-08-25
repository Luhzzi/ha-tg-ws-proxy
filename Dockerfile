# syntax=docker/dockerfile:1.7
FROM ghcr.io/flowseal/tg-ws-proxy:latest

# Копируем наш скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Используем наш run.sh вместо стандартного
ENTRYPOINT ["/run.sh"]