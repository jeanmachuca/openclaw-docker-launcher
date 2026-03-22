# openclaw-docker-agent

A sandboxed [OpenClaw](https://github.com/openclaw/openclaw) agent running in Docker. The image builds OpenClaw from source, runs the gateway in watch mode, and persists all runtime state under `/home/openclaw` in a named volume.

## Why Docker and Docker Compose?

**Docker** provides the **container runtime**: a packaged filesystem and process tree for OpenClaw (Node, pnpm, the built gateway, and OS libraries) that runs **isolated from your host** by default. You get a **repeatable image** so every machine runs the same stack, and you can **tear down or recreate** the environment without installing OpenClaw globally on macOS or Linux.

**Docker Compose** is the **orchestrator** for that container: it reads `docker-compose.yml`, wires **build context**, **environment** (`.env`), **published ports**, **named volumes**, and **networks**, and starts the service with one command. Without Compose you would script the same flags by hand (`docker build`, `docker run`, volume names, port maps, profiles). Compose keeps the setup **versioned, reviewable, and shareable** in this repo.

### Security and safer development with OpenClaw

OpenClaw is an **agent**: it can run tools, touch the filesystem it can see, and use the network according to its configuration. Running it **inside a container** is a practical way to **limit blast radius** compared to running the gateway **directly on your host user account**, where a mistake, a malicious skill/plugin, or a bad prompt could more easily affect your full home directory, SSH keys, and other projects.

Concrete benefits:

- **Filesystem boundary** — By default, the agent sees the container’s filesystem and the **`openclaw_home` volume**, not your entire host disk. You stay safer as long as you **avoid bind-mounting** sensitive host paths unless you intend to expose them.
- **Credential handling** — API keys and tokens can be supplied via Compose **`env_file`** (or environment blocks) so the **host shell** does not need OpenClaw’s global config; you can keep secrets in `.env` (gitignored) and **rotate or drop the container** without leftover global installs.
- **Network control** — You choose **which ports** are published and **where** (e.g. `127.0.0.1:18789:18789` on the host) so the gateway is not accidentally exposed beyond your machine.
- **Reproducibility** — A fixed **base image + Dockerfile** reduces “works on my laptop” drift and makes it easier to **review** what is installed before you trust it with keys or channels.

**Limits (keep expectations honest):** Containers **share the host kernel**; they are **not** the same as a separate VM. A determined attacker or a kernel-level issue is outside what Docker alone can fix. For **stronger** isolation, people combine Docker with **minimal mounts**, **read-only root filesystems**, **rootless Docker**, or run agents in **dedicated machines / VMs**—this repo targets a **sensible default** for **daily development** and **contained** agent use.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2
- An **Anthropic** API key for the default Claude stack (see [OpenClaw environment variables](https://clawdocs.org/reference/environment-variables/) for other providers)

## Quick start

### 1. Configure environment

Create a `.env` file in this directory (Compose loads it via `env_file`). Minimal example:

```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENCLAW_HOST=0.0.0.0
```

`OPENCLAW_HOST=0.0.0.0` lets the gateway accept traffic from outside the container so port publishing works. The default `127.0.0.1` bind is loopback-only inside the container.

Optional:

```bash
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_AUTH_TOKEN=your-long-random-secret
OPENAI_API_KEY=sk-...
```

Use `OPENAI_API_KEY` (or another embedding provider key) if you want **semantic memory search**; see `pnpm openclaw doctor` output for details.

### 2. Build and start

From the repository root:

```bash
chmod +x restart.sh setup.sh doctor.sh
./restart.sh
```

Or explicitly:

```bash
docker compose --profile openclaw up --build -d --remove-orphans --force-recreate
```

The `openclaw` **profile** is required because the service is declared under `profiles: [openclaw]`.

### 3. First-time OpenClaw setup (new volume)

On a fresh volume, run onboarding once **while the container is running**:

```bash
./setup.sh
```

This runs `pnpm openclaw setup` inside the app tree (`/app/openclaw`). The global `openclaw` binary is not on `PATH` in the image; always use `pnpm openclaw …` or these scripts.

### 4. Use the gateway

- Gateway WebSocket port inside the container: **18789** (override with `OPENCLAW_PORT` if needed).
- Host mapping: `localhost:${OPENCLAW_GATEWAY_PORT:-18789}`.
- Read **`gateway.auth.token`** from `/home/openclaw/.openclaw/openclaw.json` in the volume (or set `OPENCLAW_AUTH_TOKEN` before start) for Control UI / client auth.

### 5. Health check

```bash
./doctor.sh
```

Runs `pnpm openclaw doctor`. For deeper memory diagnostics: `docker compose exec -w /app/openclaw openclaw pnpm openclaw memory status --deep`.

## Helper scripts

| Script       | Purpose |
| ------------ | ------- |
| `restart.sh` | Build (if needed) and start the stack with the `openclaw` profile |
| `setup.sh`   | Run `pnpm openclaw setup` in the running container |
| `doctor.sh`  | Run `pnpm openclaw doctor` in the running container |

## Arbitrary CLI commands

```bash
docker compose exec -w /app/openclaw openclaw pnpm openclaw <subcommand> [args]
```

## Persistence

Named volume **`openclaw_home`** is mounted at **`/home/openclaw`**. Config, credentials, sessions, and canvas data live there and survive container recreation. The OpenClaw git checkout lives under **`/app/openclaw`** in the image and is not meant to be edited for day-to-day use.

## Troubleshooting

- **`exec: "openclaw": executable file not found`** — Use `pnpm openclaw` or the scripts above, not bare `openclaw`.
- **Host cannot connect to port 18789** — Set `OPENCLAW_HOST=0.0.0.0` in `.env` and recreate the container.
- **`setup` fails on Discord / `npm install`** — Often network or native build deps in slim images; memory and core gateway can still work without that optional channel. Inspect the full npm error inside the container.
- **Compose “no such service”** — Start with `--profile openclaw` (or use `./restart.sh`).

## References

- [OpenClaw repository](https://github.com/openclaw/openclaw)
- [OpenClaw environment variables](https://clawdocs.org/reference/environment-variables/)
- [OpenClaw configuration](https://clawdocs.org/reference/configuration/)
