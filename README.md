# ivpldock

A slimmed-down Docker Compose development stack for [InvoicePlane](https://github.com/InvoicePlane/InvoicePlane) and sibling PHP/Laravel projects — forked from [Laradock](https://laradock.io) and cut down from its 90+ optional services to the nine this project actually needs.

[![Build & Test Docker Images](https://github.com/InvoicePlane/InvoicePlane-Docker/actions/workflows/build-images.yml/badge.svg?branch=develop)](https://github.com/InvoicePlane/InvoicePlane-Docker/actions/workflows/build-images.yml)
[![Test Individual Containers](https://github.com/InvoicePlane/InvoicePlane-Docker/actions/workflows/test-containers.yml/badge.svg?branch=develop)](https://github.com/InvoicePlane/InvoicePlane-Docker/actions/workflows/test-containers.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](#license)

This repository is infrastructure, not an application: it's the PHP / MariaDB / Redis / nginx / Beanstalkd layer that InvoicePlane runs on top of. If you're looking for InvoicePlane itself, see the [InvoicePlane](https://github.com/InvoicePlane/InvoicePlane) repository.

## Why a fork instead of plain Laradock

Upstream Laradock supports dozens of stacks and optional services most projects never touch. ivpldock keeps exactly what InvoicePlane-family projects need — nine core services plus a deliberately-deferred `docker-in-docker` — and deletes the rest, in exchange for:

- A much smaller surface area to keep patched and building.
- Painless host file permissions: everything a container writes to a host-mounted path comes out owned by your own user, no `sudo chown` afterward.
- PHP 7.4 through 8.4 support (target: 8.4), MariaDB pinned at 10.11.

## Core services

| Service              | Purpose                                                  | Host access                      |
|-----------------------|-----------------------------------------------------------|-----------------------------------|
| `workspace`           | CLI container: PHP, Composer, Node/npm/Yarn, headless Chromium | `./workmeup.sh`              |
| `php-fpm`             | Application PHP runtime (`PHP_VERSION`-selectable)        | via `nginx`                       |
| `php-worker`          | `supervisord` container for queue workers / schedulers    | background only                   |
| `nginx`               | Web server, one vhost per project under `sites/*.conf`     | `http://localhost` (80/443)      |
| `mariadb`             | MySQL-compatible database, 10.11 pinned                   | `localhost:${MARIADB_PORT}` (default 3306) |
| `redis`               | Cache / session store                                     | `localhost:6379`                  |
| `beanstalkd`          | Job queue                                                  | background                        |
| `beanstalkd-console`  | Beanstalkd web UI                                          | background                        |
| `phpmyadmin`          | Database admin UI                                          | `http://localhost:8081`          |

`docker-in-docker` is also defined and wired into `workspace`/`php-fpm`, kept as a deliberate, not-yet-decided exception rather than a tenth blessed service.

## Quick start

**Prerequisites:** Docker Engine with the Compose v2 plugin (`docker compose version`, not the legacy standalone `docker-compose` binary).

```bash
git clone <this-repo> ivpldock && cd ivpldock
cp .env.example .env.docker
./startmeup.sh
```

`.env.docker` is your local, uncommitted configuration — edit it (PHP version, which optional features to install, PUID/PGID, ports) before or after the first start. Notable defaults worth checking:

- `APP_CODE_PATH_HOST` — path to the directory holding the projects you want served (default `../projects`).
- `PHP_VERSION` — default `8.4`.
- `WORKSPACE_PUID` / `WORKSPACE_PGID` — default `1000:1001`; set these to match your host user so container-written files stay yours.

Once it's up, `./workmeup.sh` drops you into the `workspace` container as the `ivpldock` user for Composer/npm/artisan work.

## Everyday commands

Every helper script and Makefile target already passes `--env-file .env.docker` for you — do the same if you ever call `docker compose` directly, since that file is what pins the Compose project to *this* stack instead of some other project on the host:

```bash
docker compose --env-file .env.docker ps
docker compose --env-file .env.docker exec workspace bash
```

| Script             | Effect                                              |
|--------------------|------------------------------------------------------|
| `./startmeup.sh`   | Start the core stack, detached, no rebuild           |
| `./starmeup.sh`    | Same, in the foreground                               |
| `./builddmeup.sh`  | Rebuild images + start, detached                      |
| `./buildmeup.sh`   | Rebuild images + start, in the foreground             |
| `./workmeup.sh`    | Shell into `workspace` as the `ivpldock` user         |
| `./down.sh`        | Stop and remove containers (no `-v` — volumes, including the database, are kept; use `make down-volumes` for the destructive variant) |

The `Makefile` is the fuller interface (`make help` for the full list): `make start`, `make build`, `make shell`, `make logs`, `make status`, `make db-shell`, `make redis-cli`, `make down` (safe, keeps volumes), `make down-volumes` (explicit destructive variant), and more.

## Documentation

- **[AGENTS.md](AGENTS.md)** — the canonical, tool-neutral reference: full service list, permissions model, and the hard-learned rules (footguns) for working in this repo safely. Start here for anything beyond a quick start.
- **[CLAUDE.md](CLAUDE.md)** — Claude Code–specific depth on top of AGENTS.md.
- `.junie/guidelines.md` and `.github/copilot-instructions.md` — the same brief for Junie and GitHub Copilot.

## Contributing

Issues and pull requests are welcome. Please read [AGENTS.md](AGENTS.md) first — it documents several non-obvious constraints (permissions model, service parity across helper scripts, nginx logging) that have caused real regressions before.

## Credits

ivpldock is a fork of [Laradock](https://laradock.io), created by Mahmoud Zalt and maintained by its own community of contributors. All credit for the original architecture and the bulk of the Dockerfiles goes to that project — see the [Laradock repository](https://github.com/laradock/laradock) for its full list of maintainers, contributors, and sponsors.

## License

MIT, inherited unchanged from the upstream [Laradock license](https://github.com/laradock/laradock/blob/master/LICENSE).
