# AGENTS.md — ivpldock

Shared, tool-neutral brief for any AI agent (Claude Code, Junie, Copilot,
Cursor, …) working in this repository. Claude Code also reads `CLAUDE.md`
(deeper Claude-specific detail); Junie also reads `.junie/guidelines.md`;
GitHub Copilot also reads `.github/copilot-instructions.md`. **This file is
the canonical source for "what ivpldock is" and the hard rules** — the
others point back here. Keep them in sync when the service set, scripts, or
permissions model change.

---

## What ivpldock is

ivpldock is a **Docker Compose development stack for InvoicePlane**, forked
and heavily slimmed down from [Laradock](https://laradock.io). It is *not*
an application — it is the PHP/database/web infrastructure that InvoicePlane
(and sibling PHP projects on this host) run *on top of*.

- Upstream Laradock ships 90+ optional services. This fork keeps **nine**,
  plus `docker-in-docker` (see below). Everything else has been deleted from
  `docker-compose.yml` and `.docker/` on purpose — do not reintroduce a
  service by copying it back from upstream Laradock without a concrete need.
- Target runtime: **PHP 8.4** (the stack still supports 7.4–8.4 via
  `PHP_VERSION`), **MariaDB 10.11** (pinned — MariaDB 11 broke things),
  **Redis**, **nginx**, **Beanstalkd**.
- The whole point of the fork is **painless file permissions**: everything a
  container writes to a host-mounted path lands owned by the host user, with
  no `sudo chown` afterward. Preserving that property is a hard requirement
  of every change (see "Permissions model").

### Core services

| Service              | Purpose                                                    | Host access |
|----------------------|-----------------------------------------------------------|-------------|
| `workspace`          | CLI container: PHP, Composer, Node/npm/Yarn, headless Chromium | `./workmeup.sh` |
| `php-fpm`            | Application PHP runtime (`PHP_VERSION`)                    | via nginx |
| `php-worker`         | `supervisord` container for queue workers / schedulers    | background only |
| `nginx`              | Web server, one vhost per project under `sites/*.conf`    | `http://localhost` (80/443) |
| `mariadb`            | MySQL-compatible database, **10.11 pinned**               | `localhost:${MARIADB_PORT}` (default 3306) |
| `redis`              | Cache / session store                                     | `localhost:6379` |
| `beanstalkd`         | Job queue                                                 | background |
| `beanstalkd-console` | Beanstalkd web UI                                         | background |
| `phpmyadmin`         | Database admin UI                                         | `http://localhost:8081` |

`docker-in-docker` (image `docker:29-dind`) is still defined and wired into
`workspace`/`php-fpm` (via `DOCKER_HOST`, TLS env vars, `links`, and a
`/certs/client` volume). Upstream-plan intent was to remove it; it was kept
by an explicit decision. Treat it as "deliberately deferred, not blessed" —
if you are cleaning up, removing it and its `DOCKER_*` wiring is on the
table, but ask first.

---

## Running the stack

All four "up" scripts start the **identical** nine-service set
(`beanstalkd beanstalkd-console mariadb nginx php-fpm php-worker phpmyadmin
redis workspace`). If you add or rename a service, grep **all** the scripts
plus the `Makefile`, not just one — they have silently drifted apart before.

| Script            | Effect |
|-------------------|--------|
| `./startmeup.sh`  | start the 9 services, detached, no rebuild |
| `./starmeup.sh`   | same, foreground |
| `./builddmeup.sh` | rebuild images + start, detached |
| `./buildmeup.sh`  | rebuild images + start, foreground |
| `./workmeup.sh`   | shell into `workspace` as the `ivpldock` user |
| `./down.sh`       | stop and remove containers (no `-v` — volumes, including MariaDB's, are kept) |

The `Makefile` is the fuller interface — `make help` lists ~30 targets
(`make start`, `make build`, `make build-workspace`, `make shell`,
`make logs`, `make status`, `make db-shell`, `make redis-cli`,
`make fix-permissions`, `make validate`, …). `make down` stops **without**
`-v`; `make down-volumes` is the explicit destructive variant.

Raw commands always take the env file explicitly and use **modern**
`docker compose` (space, not the legacy `docker-compose` binary):

```bash
docker compose --env-file .env.docker ps
docker compose --env-file .env.docker build workspace
docker compose --env-file .env.docker exec --user=ivpldock workspace php -v
```

---

## Permissions model (PUID/PGID) — do not break this

`WORKSPACE_PUID` / `WORKSPACE_PGID` default to `1000:1001`, matching the host
user. Two different mechanisms deliver "files come out host-owned", and
**mixing them on one service breaks that service**:

1. **Container-level `user: '${WORKSPACE_PUID}:${WORKSPACE_PGID}'`** — for
   services whose entrypoint runs app code directly with no privileged setup
   step: `php-fpm`, `redis`. (The whole process tree runs as the host
   UID/GID from PID 1.)
2. **Entrypoint starts as root, drops privileges internally** — for services
   whose entrypoint needs root first:
   - `mariadb` — the official entrypoint initialises `/var/lib/mysql` as
     root, then `exec`s as `mysql`. Adding `user:` here makes init fail
     (this was reverted once already, commit `01e1532`).
   - `php-worker` — `supervisord.conf` has `user=root` so `supervisord` can
     `setuid()` each supervised program to `user=ivpldock`. Adding `user:`
     makes it crash instantly: `Error: Can't drop privilege as nonroot user`.
   - `workspace` — starts as root for build/setup, drops to `ivpldock` for
     interactive use; scripts and Make targets pass `--user=ivpldock`.

Before adding `user:` to any service, check whether its entrypoint expects
to start as root.

The Dockerfiles for `workspace`/`php-fpm`/`php-worker` recreate the
`ivpldock` user with the build-arg PUID/PGID, deleting any pre-existing
user/group that squats on those ids. Keep that logic intact.

---

## Hard rules / footguns (all learned the hard way — see git history)

1. **`./down.sh` runs plain `docker compose down` (no `-v`)** — it keeps the
   `ivpldock_mariadb` volume, i.e. the database. It used to pass `-v` and
   delete it; that has been fixed. For the explicit destructive variant use
   `make down-volumes` or
   `docker compose --env-file .env.docker down -v`, and always double-check
   which `COMPOSE_PROJECT_NAME` a given checkout resolves to before running
   `-v` by hand — a scratch clone that happens to load the same
   `.env.docker` targets *this* stack's volumes, not its own.

2. **Never add `access_log` / `error_log` directives pointing at
   `/var/log/nginx/*.log` in a `sites/*.conf` file.** nginx's master runs as
   root and opens the log path *before* dropping to `www-data`, so a
   not-yet-existing per-site log file is created root-owned on the
   host-mounted `logs/nginx/` directory and you can't rotate/delete it
   without `sudo`. `nginx.conf` already logs globally to
   `/dev/stdout` / `/dev/stderr` (`docker compose logs nginx`). Base new
   sites on `sites/default.conf`, not the other `*.conf.example` templates.

3. **This host runs several unrelated Docker Compose projects side by side.**
   - Do not look containers up with `docker ps -aqf "name=<substring>"` — it
     can match the wrong project or several at once. Use
     `docker compose --env-file .env.docker exec <service>`. (`workmeup.sh`
     was fixed this way; `phpmeup.sh`, `rootmeup.sh`, `worker.sh`,
     `redismeup.sh` still have the brittle pattern.)
   - `make clean` is scoped to ivpldock's own label. Do **not** run a global
     `docker system prune` / `docker volume prune` — that hits every stack
     on the host. (`make clean-all` exists for the deliberate case.)
   - If `mariadb` fails with "port is already allocated", another stack owns
     `MARIADB_PORT` (default 3306): `docker ps --format '{{.Names}}\t{{.Ports}}' | grep 3306`.

4. **Shell-continuation comments eat commands.** A `#comment \` line inside a
   backslash-continued command gets swallowed once bash joins the logical
   line. This silently dropped `phpmyadmin`/`redis`/`workspace` from two
   scripts. Don't put `#` comments inside `\`-continued command blocks.

5. **`MARIADB_VERSION=10.11` is a deliberate pin.** MariaDB 11 broke this
   stack. `docker-compose.yml` interpolates `${MARIADB_VERSION}`; keep the
   value at 10.11 unless you're doing a deliberate, tested upgrade.

6. **`.env.docker` is gitignored** (local, may hold secrets). `.env.example`
   is the tracked template — `cp .env.example .env.docker`. They should stay
   structurally identical apart from `APP_CODE_PATH_HOST` (local absolute
   path vs. the `../projects` default).

7. **Don't `-include .env.docker` in the `Makefile`.** GNU Make re-exports
   any variable that started in the environment once a makefile assignment
   touches it, which silently breaks overrides like
   `MARIADB_PORT=3316 make start`. Recipes that need a value read it from
   `.env.docker` at run time with `grep`.

---

## Making changes

- **Minimal changes.** This is infrastructure; churn is expensive. Only
  touch a Dockerfile if a required capability needs it.
- **Adding a workspace/php-fpm capability** (a PHP extension, a tool):
  1. Add an `ARG INSTALL_<THING>=false` + guarded `RUN` block with a
     `#####` section header and a comment explaining *why*, in the relevant
     `.docker/*/Dockerfile`.
  2. Add the build arg to `docker-compose.yml` under that service.
  3. Add the flag to `.env.example` **and** `.env.docker` (same key).
  4. Keep it opt-out-able; don't change existing defaults without reason.
  5. Sanity-check at least PHP 8.2 and 8.4 build.
- **Env var naming:** service prefix + descriptive name
  (`WORKSPACE_INSTALL_CHROMIUM`, not `CHROMIUM`).
- **Xdebug never autostarts** — trigger mode only
  (`xdebug.start_with_request=trigger`).
- **Verify, then report honestly.** `docker compose config --quiet` for
  syntax; actually build/run the affected service; if you couldn't test
  something, say so.
- **Commit style:** conventional commits (`feat:`, `fix:`, `docs:`,
  `refactor:`, `chore:`).

## Headless browser

`workspace` installs **Google Chrome stable** from Google's apt repo
(`WORKSPACE_INSTALL_CHROMIUM=true`), symlinked as `chromium` /
`chromium-browser` / `chrome`, with `CHROME_BIN` set. Ubuntu 24.04's own
`chromium` apt package is a broken snap stub, hence Google's `.deb`. amd64
only. In a container, callers must pass `--no-sandbox` (and
`--headless=new --disable-dev-shm-usage` for CI); the binary is left generic.

`WORKSPACE_INSTALL_PUPPETEER=true` additionally installs the `puppeteer` npm
package globally under `/usr/local` (on `NODE_PATH`), so Spatie Browsershot's
`node .../browser.cjs` can `require('puppeteer')`. It does **not** download
its own Chromium (`PUPPETEER_SKIP_DOWNLOAD`); `PUPPETEER_EXECUTABLE_PATH`
points it at the Chrome above. Requires `WORKSPACE_INSTALL_CHROMIUM=true`.

## Sibling projects on this host

`/data/prompt-ivpldock.md` is the onboarding doc for agents working in
`/data/Projects/*`. It tells them this stack already provides PHP, Composer,
Node, MariaDB, Redis, and a web server, so they route work through
`./workmeup.sh` / `docker compose exec` instead of installing anything on
the host. Keep it in sync with this file.
