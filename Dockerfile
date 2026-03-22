# Debian-based image: node-llama-cpp ships glibc prebuilds; Alpine/musl forces a
# source build that needs a full C++ toolchain and is slow and fragile in Docker.
FROM node:22-bookworm-slim
ARG OPENCLAW_GIT_URL=https://github.com/openclaw/openclaw.git
ARG OPENCLAW_GIT_REF=main
ARG OPENCLAW_GATEWAY_PORT=18789
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        bash \
        lsof \
        psmisc \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@latest-10

RUN groupadd --system openclaw \
    && useradd --system --gid openclaw --create-home --home-dir /home/openclaw --shell /bin/bash openclaw
RUN mkdir -p /app/openclaw && chown -R openclaw:openclaw /app/openclaw

RUN mkdir -p /etc/openclaw
RUN chmod +w /app/openclaw

USER openclaw
RUN git clone --depth 1 --branch "${OPENCLAW_GIT_REF}" "${OPENCLAW_GIT_URL}" /app/openclaw
WORKDIR /app/openclaw
RUN pnpm install
RUN pnpm ui:build # auto-installs UI deps on first run
RUN pnpm build

RUN pnpm openclaw onboard --install-daemon

COPY docker-entrypoint.sh /docker-entrypoint.sh
USER root
RUN chmod +x /docker-entrypoint.sh && chown openclaw:openclaw /docker-entrypoint.sh
USER openclaw

EXPOSE ${OPENCLAW_GATEWAY_PORT}
ENTRYPOINT ["/docker-entrypoint.sh"]
# Dev loop (auto-reload on source/config changes); must be CMD so the image can build
CMD ["pnpm", "gateway:watch"]
