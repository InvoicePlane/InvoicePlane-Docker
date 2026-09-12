# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Start with [`AGENTS.md`](AGENTS.md)** — it is the canonical, tool-neutral
brief on what ivpldock is, the nine-service set, how to run it, the
permissions model, and the accumulated hard rules. This file adds
Claude-specific depth on top of it; `.junie/guidelines.md` and
`.github/copilot-instructions.md` are the equivalents for Junie and Copilot.
Keep all of them in sync when the service set, scripts, or permissions model
change.

## Project Overview

This is a **Docker Compose development stack for InvoicePlane**, forked and
heavily slimmed down from Laradock. It is infrastructure, not an
application: the PHP / MariaDB / Redis / nginx / Beanstalkd layer that
InvoicePlane and sibling PHP projects under `/data/Projects` run on top of.
Upstream Laradock ships 90+ optional services; this fork keeps **nine**
(plus a deliberately-deferred `docker-in-docker`) and has deleted the rest
from `docker-compose.yml` and `.docker/`. Do not reintroduce a service by
copying it back from upstream without a concrete need. It supports PHP
versions 7.4 through 8.4 (target: 8.4); MariaDB is pinned at 10.11 (11 broke
things).

### Architecture

**Core Services:**
- **Workspace**: Utility container for CLI tasks (Composer, Node, npm, yarn, headless Chromium)
- **PHP-FPM**: Application runtime (configurable PHP version)
- **Nginx**: Web server with per-site configuration
- **MariaDB**: Default database (MySQL compatible)
- **Redis**: Cache/session store (optional but commonly enabled)
- **PHP-Worker**: Background job processing

**Optional Services**: MongoDB, PostgreSQL, MySQL, Memcached, Elasticsearch, MailPit, PhpMyAdmin, and 40+ others defined in `.docker/`

### Other agents/systems working on sibling projects

`/data/prompt-ivpldock.md` (one directory up from this repo) is the
onboarding doc for other Claude/agent sessions working inside
`/data/Projects/*`: it tells them this stack already provides PHP,
Composer, Node, MariaDB, Redis, and a web server, so they should route work
through `./workmeup.sh` / `docker compose exec` rather than installing
anything on the host. Keep it in sync with this file when service names,
scripts, or the permissions model change.

This host runs several unrelated Docker Compose projects side by side. If
`mariadb` fails to start with "port is already allocated," another stack is
already bound to `MARIADB_PORT` (default `3306`) — check with `docker ps
--format '{{.Names}}\t{{.Ports}}' | grep 3306` before assuming ivpldock
itself is broken.

### File Structure

```
/data/ivpldock/
├── docker-compose.yml          # Main orchestration config
├── .env.example               # Template for local configuration
├── .env.docker                # Docker-specific environment (example)
├── .docker/                   # Service Dockerfiles organized by service
│   ├── php-fpm/
│   ├── nginx/
│   ├── workspace/
│   ├── mariadb/
│   └── ... (40+ other services)
├── sites/                      # Nginx virtual host configs (.conf files)
├── php-fpm/                    # PHP configuration mounts
├── nginx/                      # Nginx configuration mounts
├── .github/
│   ├── copilot-instructions.md # Detailed development guidelines
│   └── workflows/              # CI/CD pipelines
└── *.sh                        # Helper scripts (startmeup.sh, buildmeup.sh, etc.)
```

## Common Development Tasks

### Initial Setup

1. Copy `.env.example` to `.env.docker`:
   ```bash
   cp .env.example .env.docker
   ```

2. Update `.env.docker` with your configuration:
   - `APP_CODE_PATH_HOST`: Path to your application code (default: `../projects`)
   - `PHP_VERSION`: Version to use (default: `8.2`)
   - `WORKSPACE_INSTALL_XDEBUG`: Set to `true` for debugging

3. Start core services:
   ```bash
   ./startmeup.sh
   ```
   This starts: workspace, php-fpm, nginx, mariadb, redis, php-worker, phpmyadmin

### Helper Scripts

| Script | Effect |
|---|---|
| `./startmeup.sh` | Start core stack, detached, no rebuild |
| `./starmeup.sh` | Start core stack, foreground, no rebuild |
| `./builddmeup.sh` | Rebuild images + start, detached |
| `./buildmeup.sh` | Rebuild images + start, foreground |
| `./workmeup.sh` | Shell into `workspace` as the `ivpldock` user (`docker compose exec`) |
| `./down.sh` | Stop and remove containers (no `-v` — volumes, including MariaDB's, are kept; use `make down-volumes` for the destructive variant) |

All four `up` scripts start the same core set: `mariadb nginx php-fpm
php-worker phpmyadmin redis workspace` (plus `beanstalkd`/`beanstalkd-console`
in the `star*`/`start*` variants). Keep that service list identical across
all four scripts when editing them — they drifted out of sync before
(`buildmeup.sh`/`starmeup.sh` had a `#php-worker \` line-continuation
comment that silently swallowed `phpmyadmin`, `redis`, and `workspace` from
the command; `startmeup.sh` referenced a `boost` service that was never
defined in `docker-compose.yml`). If you add or rename a service, grep all
five scripts, not just one.

`workmeup.sh` uses `docker compose --env-file .env.docker exec --user=ivpldock
workspace bash`, not raw `docker exec` with a `docker ps -aqf "name=..."`
lookup — this host runs several unrelated Compose projects side by side, and
a substring name filter can match the wrong container or return more than
one ID.

**Every `docker compose` invocation against this stack — start, stop, exec,
ps, logs, down, all of it — must pass `--env-file .env.docker`.** That file
sets `COMPOSE_PROJECT_NAME=ivpldock`, which is what makes a given `docker
compose` command resolve to *this* stack's containers/networks/volumes
instead of some other Compose project. That's the entire reason `down.sh`
exists as a wrapper instead of telling people to type `docker compose down`
from memory: a bare `docker compose down -v` run without `--env-file
.env.docker` — including from a scratch clone or any other checkout of this
repo, since the project name comes from the env file's contents, not the
directory it's sitting in — can silently target and destroy *this* stack's
real running containers and volumes (mariadb's data included) if that other
checkout happens to load the same `.env.docker` (or a copy of it). Never run
a bare `docker-compose`/`docker compose down`, `up`, `stop`, or any other
lifecycle command against a clone of this repo without first confirming
which `COMPOSE_PROJECT_NAME` it resolves to — when in doubt, use `./down.sh`
or the other helper scripts in this directory rather than typing the
`docker compose` invocation by hand.

### Building & Running

**Build a single service:**
```bash
docker compose --env-file .env.docker build php-fpm
docker compose --env-file .env.docker build nginx
```

**Start all services:**
```bash
docker compose --env-file .env.docker up -d
```

**Stop all services:**
```bash
./down.sh
```

**View running containers:**
```bash
docker compose --env-file .env.docker ps
```

### Accessing Containers

**Execute commands in a container:**
```bash
docker compose --env-file .env.docker exec php-fpm php -v
docker compose --env-file .env.docker exec workspace composer install
docker compose --env-file .env.docker exec workspace npm install
```

**Interactive shell:**
```bash
docker compose --env-file .env.docker exec workspace bash
```

### Database Operations

**Access MariaDB:**
```bash
docker compose --env-file .env.docker exec mariadb mysql -uroot -proot
```

**PhpMyAdmin Web UI:**
Access at `http://localhost:8081` (if service is running)

### Nginx Virtual Hosts

Virtual host configurations are in `./sites/*.conf`. Each `.conf` file is automatically loaded.

**Example site config structure:**
```nginx
server {
    server_name myapp.local;
    root /var/www/projects/myapp/public;
    
    location ~ \.php$ {
        fastcgi_pass php-fpm:9000;
        # ... standard PHP-FPM directives
    }
}
```

Update your system's `/etc/hosts` (or Docker Host IP) to route domain names:
```
10.0.75.1 myapp.local
```

**Never add `access_log`/`error_log` directives pointing at
`/var/log/nginx/*.log` in a site config.** `nginx.conf` already logs
everything to `/dev/stdout`/`/dev/stderr` globally (`docker compose logs
nginx`). Nginx's master process runs as root inside the container and opens
any log file path *before* dropping to `www-data`, so a per-site log path
that doesn't already exist gets created root-owned on the host-mounted
`./logs/nginx/` directory — silently blocking you from writing/rotating/
deleting it later without `sudo`. This was the root cause of a real,
recurring permission bug (fixed 2026-08-18 across all `sites/*.conf` and the
`.conf.example` templates) — don't reintroduce it when copying a template
for a new site. Base new sites off `sites/default.conf`.

## Development Guidelines

### Dockerfile Changes

**Core Principle:** Minimal changes. Only modify if necessary for required functionality.

**When adding a PHP extension:**
1. Update the relevant Dockerfile in `.docker/php-fpm/` or `.docker/workspace/`
2. Update `docker-compose.yml` with a new build arg
3. Update `.env.example` with a new optional flag (e.g., `WORKSPACE_INSTALL_NEW_EXT=false`)
4. Use section headers and inline comments explaining why, not what
5. Test across supported PHP versions (at minimum 7.4, 8.1, 8.3)

**Dockerfile best practice:**
```dockerfile
###########################################################################
# My Extension:
###########################################################################

ARG INSTALL_MY_EXT=false
RUN if [ ${INSTALL_MY_EXT} = true ]; then \
    # Install required system dependencies first
    apt-get install -yqq lib-dependency && \
    # Then the PHP extension itself
    pecl install my-extension && \
    docker-php-ext-enable my-extension \
;fi
```

### Permissions Discipline (PUID/PGID)

The whole point of this fork's `WORKSPACE_PUID`/`WORKSPACE_PGID` (default
`1000:1001`, matching the host user) is that every container writing to a
host-mounted path produces files the host user can read/write/delete
without `sudo` afterward. Two different mechanisms achieve that, and
**mixing them on the same service breaks it**:

1. **Container-level `user: '${WORKSPACE_PUID}:${WORKSPACE_PGID}'`** — for
   services whose entrypoint runs application code directly with no
   privileged setup step (`php-fpm`, `workspace`, `redis`). The whole
   process tree runs as the host UID/GID from PID 1.
2. **Entrypoint starts as root, drops privileges internally per-write** —
   for services whose entrypoint needs root first (`mariadb`'s official
   entrypoint initializes the data dir as root then execs as `mysql`;
   `php-worker`'s `supervisord` starts as root — `supervisord.conf` has
   `user=root` — so it can `setuid()` each supervised program to whatever
   `user=` that program's own block specifies, e.g. `user=ivpldock` in
   `.docker/php-worker/supervisord.d/*.conf.example`).

Adding the container-level `user:` override to a service in category 2
breaks it outright: mariadb's entrypoint can't initialize `/var/lib/mysql`
as an unprivileged user (reverted in commit `01e1532`), and supervisord
fails immediately with `Error: Can't drop privilege as nonroot user` because
it's already non-root before it tries to `setuid` a child to `ivpldock`.
Before adding `user:` to a new service, check whether its entrypoint expects
to start as root.

### Xdebug Configuration

**Critical Security Rule:** Xdebug must NEVER autostart in containers.

- Always use **trigger mode** (not autostart) to prevent build-time connection warnings
- Document the trigger method in comments
- Xdebug 3 (PHP 8.x): Use `xdebug.start_with_request=trigger`
- Xdebug 2 (older PHP): Keep `remote_autostart=0`

### Headless Browser (Chromium)

The `workspace` container installs **Google Chrome stable** from Google's
official apt repo when `WORKSPACE_INSTALL_CHROMIUM=true` (the default),
symlinked as `chromium` / `chromium-browser` / `chrome` and exported as
`CHROME_BIN`. Ubuntu 24.04's own `chromium` apt package is a snap-transition
stub that can't run in a container, which is why it's the Google `.deb`
(amd64 only — Google publishes no arm64 build).

- Install lives in `.docker/workspace/Dockerfile` under the "Headless
  Chromium" section, gated on `ARG INSTALL_CHROMIUM`, wired through
  `docker-compose.yml` (`INSTALL_CHROMIUM=${WORKSPACE_INSTALL_CHROMIUM}`)
  and both `.env.example` / `.env.docker`.
- In a container Chrome needs `--no-sandbox` (no user namespaces), plus
  `--headless=new --disable-dev-shm-usage` for CI. The binary is left
  generic — callers pass those flags themselves.
- Verify after a rebuild:
  `docker compose --env-file .env.docker exec --user=ivpldock workspace chromium --version`

### Environment Variable Naming

Use clear, descriptive names with the service prefix:
```
WORKSPACE_INSTALL_XDEBUG=true        # Good
WORKSPACE_XDEBUG_PORT=9003           # Good
XDBG=true                             # Avoid
```

### Backward Compatibility

- Do not change default values without major version bump
- Support the full declared PHP version range (currently 7.4 through 8.4)
- Test breaking changes against oldest and newest versions
- Maintain existing configuration format and behavior

## Testing & Verification

Before committing changes:

1. **Build test** — Ensure the Dockerfile builds without warnings:
   ```bash
   docker compose --env-file .env.docker build <service>
   ```

2. **Functionality test** — Verify the feature works:
   ```bash
   docker compose --env-file .env.docker exec php-fpm php -m | grep installed-extension
   ```

3. **Cross-version test** — Test with at least 2 PHP versions:
   ```bash
   # Test with PHP 8.1
   sed -i 's/PHP_VERSION=.*/PHP_VERSION=8.1/' .env.docker
   docker compose --env-file .env.docker build php-fpm
   
   # Test with PHP 8.3
   sed -i 's/PHP_VERSION=.*/PHP_VERSION=8.3/' .env.docker
   docker compose --env-file .env.docker build php-fpm
   ```

4. **Service startup test** — Verify containers start cleanly:
   ```bash
   docker compose --env-file .env.docker up -d
   docker compose --env-file .env.docker logs php-fpm
   docker compose --env-file .env.docker down
   ```

## Secrets & Security

- **.env.docker is not committed** — It contains local environment overrides and may include sensitive data
- **.env.example is the template** — All users copy `.env.example` to `.env.docker` and customize locally
- **Never log sensitive data** — Be cautious with database passwords, API keys, tokens
- **Run containers as non-root** where possible (default for most services)
- **Keep base images updated** — Review upstream image updates regularly

## Commit Message Format

Follow conventional commit format:
```
<type>: <short description>

Types: feat, fix, docs, refactor, test, chore
Examples:
  feat: Add Redis container to compose
  fix: Resolve Xdebug build warnings
  docs: Update PHP extension installation guide
```

## References

- [Laradock Documentation](https://laradock.io)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [PHP Docker Official Images](https://hub.docker.com/_/php)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- Detailed guidelines: See `.github/copilot-instructions.md` for comprehensive development rules
