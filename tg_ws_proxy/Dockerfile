# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/venv

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential cargo libffi-dev libssl-dev git \
    && python -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/pip" install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN "$VIRTUAL_ENV/bin/pip" install cryptography==46.0.5

# Репозиторий с исходниками proxy-сервера.
# Если вы форкнули проект — замените TG_WS_PROXY_REPO на URL своего форка.
ARG TG_WS_PROXY_REPO=https://github.com/Flowseal/tg-ws-proxy.git
ARG TG_WS_PROXY_REF=main
RUN git clone --depth 1 --branch "${TG_WS_PROXY_REF}" "${TG_WS_PROXY_REPO}" /tmp/src \
    && cp -r /tmp/src/proxy ./proxy

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/proxy ./proxy
COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 1443/tcp

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/run.sh"]
