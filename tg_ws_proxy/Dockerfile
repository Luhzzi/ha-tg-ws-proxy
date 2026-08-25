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

RUN "$VIRTUAL_ENV/bin/pip" install cryptography==46.0.5 certifi

ARG TG_WS_PROXY_REPO=https://github.com/Flowseal/tg-ws-proxy.git
ARG TG_WS_PROXY_REF=main
RUN git clone --depth 1 --branch "${TG_WS_PROXY_REF}" "${TG_WS_PROXY_REPO}" /tmp/src \
    && cp -r /tmp/src/proxy ./proxy \
    && cp -r /tmp/src/utils ./utils \
    && cp /tmp/src/LICENSE ./LICENSE \
    && rm -rf /tmp/src

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini ca-certificates jq \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system app \
    && useradd --system --gid app --create-home --home-dir /home/app app

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/proxy ./proxy
COPY --from=builder /app/utils ./utils
COPY --from=builder /app/LICENSE ./LICENSE

COPY run.sh /run.sh
RUN chmod a+x /run.sh

USER app

EXPOSE 1443/tcp

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/run.sh"]