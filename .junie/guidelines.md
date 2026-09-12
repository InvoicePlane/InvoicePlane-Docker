# Project guidelines for Junie — ivpldock

**Read [`../AGENTS.md`](../AGENTS.md) first** — it is the canonical brief for
every AI agent on this repo (what ivpldock is, the service set, how to run
it, the permissions model, the full hard-rules list). This file is the short
version with the essentials inline so you don't have to chase the pointer.

## What this repo is

A **Docker Compose development stack for InvoicePlane**, forked and heavily
slimmed from [Laradock](https://laradock.io). It is infrastructure, not an
application: the PHP / MariaDB / Redis / nginx / Beanstalkd layer that
InvoicePlane and sibling PHP projects run on top of.

- Nine services only: `workspace`, `php-fpm`, `php-worker`, `nginx`,
  `mariadb`, `redis`, `beanstalkd`, `beanstalkd-console`, `phpmyadmin`
  (plus a deliberately-deferred `docker-in-docker`). Upstream Laradock's
  other 80+ services have been deleted from `docker-compose.yml` and
  `.docker/` — do not copy one back without a concrete need.
- PHP 8.4 target (7.4–8.4 supported via `PHP_VERSION`). MariaDB pinned at
  **10.11** — 11 broke the stack.
- The fork exists to make **file permissions painless**: containers write
  host-mounted paths as the host user (`1000:1001`), no `sudo chown` after.
  Every change must preserve that.

## How to run it

- Scripts: `./startmeup.sh` / `./starmeup.sh` (start), `./buildmeup.sh` /
  `./builddmeup.sh` (rebuild + start), `./workmeup.sh` (shell into
  `workspace` as the `ivpldock` user). All four "up" scripts start the same
  nine services — change one, change all + the `Makefile`.
- `Makefile` is the fuller interface: `make help`, `make start`,
  `make build`, `make build-workspace`, `make shell`, `make logs`,
  `make db-shell`, `make validate`, …
- Raw commands: modern `docker compose` (space, not `docker-compose`), always
  `--env-file .env.docker`, e.g.
  `docker compose --env-file .env.docker exec --user=ivpldock workspace php -v`.

## Hard rules (do not violate)

1. **`./down.sh` runs plain `docker compose down` (no `-v`)** — it keeps the
   MariaDB volume (the database). For the explicit destructive variant use
   `make down-volumes` or `docker compose --env-file .env.docker down -v`,
   and confirm which `COMPOSE_PROJECT_NAME` a checkout resolves to first —
   a scratch clone loading the same `.env.docker` targets this stack's own
   volumes, not its own.
2. **No `access_log` / `error_log` file paths in `sites/*.conf`.** nginx's
   root master opens them before dropping privileges, creating root-owned
   files on the host `logs/nginx/` mount. nginx already logs to
   stdout/stderr globally. Base new sites on `sites/default.conf`.
3. **This host runs many unrelated Compose projects.** Never look up
   containers with `docker ps -aqf "name=<substring>"`; use
   `docker compose exec <service>`. Never run global `docker system prune` /
   `volume prune` — `make clean` is scoped; `make clean-all` is the opt-in.
   Port 3306 is often contended — check before blaming ivpldock.
4. **Permissions model — don't mix the two mechanisms.** `php-fpm` and
   `redis` use a container-level `user:`. `mariadb`, `php-worker`, and
   `workspace` must start as root and drop privileges internally — adding
   `user:` to those breaks them (`mariadb` init fails; `php-worker`
   supervisord crashes with "Can't drop privilege as nonroot user").
5. **No `#` comments inside `\`-continued shell command blocks** — bash
   swallows the rest of the joined line (this silently broke the up-scripts
   once).
6. **`.env.docker` is gitignored; `.env.example` is the tracked template.**
   Keep them structurally identical apart from `APP_CODE_PATH_HOST`.

## Making changes

- Minimal changes — this is infrastructure. Only touch a Dockerfile for a
  required capability.
- New workspace/php-fpm capability = `ARG INSTALL_<THING>=false` + guarded
  `RUN` (with a `#####` header and a *why* comment) + build arg in
  `docker-compose.yml` + flag in **both** `.env.example` and `.env.docker`.
- Env vars: service-prefixed and descriptive (`WORKSPACE_INSTALL_CHROMIUM`).
- Xdebug never autostarts — trigger mode only.
- Verify with `docker compose config --quiet`, then actually build/run the
  affected service. Report honestly what you did and didn't test.
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
