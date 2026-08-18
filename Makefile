.PHONY: help build build-no-cache build-workspace build-php-fpm build-nginx \
	build-mariadb build-redis build-phpmyadmin build-php-worker build-beanstalkd \
	start stop down down-volumes restart status validate \
	logs logs-workspace logs-php-fpm logs-nginx logs-mariadb logs-redis \
	logs-phpmyadmin logs-php-worker logs-beanstalkd \
	shell root-shell exec redis-cli clean clean-all fix-permissions \
	test-workspace test-multi \
	install-composer install-npm install-yarn install-all dev-setup \
	php-version node-version yarn-version npm-version \
	db-init db-shell config-info lint-dockerfile

# Deliberately NOT `-include .env.docker` here: GNU Make auto-re-exports any
# variable that originated in the environment once a makefile assignment
# touches it, so including the whole file would silently clobber a
# shell-level override like `MARIADB_PORT=3316 make start` for every target,
# not just the couple that need a secret out of it. Targets that need one
# value out of .env.docker (db-init, db-shell, redis-cli, fix-permissions)
# read it at recipe run time with grep instead, scoped to just that recipe's
# own subshell.
# Every other script in this repo assumes bash (#!/bin/bash); pin it here
# too since /bin/sh is dash on Debian/Ubuntu and doesn't support the
# parameter-expansion syntax used in fix-permissions below.
SHELL := /bin/bash

DOCKER_COMPOSE := docker-compose --env-file .env.docker
PHP_VERSION ?= 8.4

# Keep in sync with buildmeup.sh/builddmeup.sh/starmeup.sh/startmeup.sh and
# docker-compose.yml. docker-in-docker is intentionally excluded — it has no
# build step of its own and is only ever pulled in as a dependency.
CORE_SERVICES := workspace php-fpm nginx mariadb redis phpmyadmin php-worker beanstalkd beanstalkd-console

help: ## Display this help message
	@echo "InvoicePlane Docker (ivpldock) - Available Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build                        # Build all images for PHP $(PHP_VERSION)"
	@echo "  make build PHP_VERSION=8.3        # Build all images for PHP 8.3"
	@echo "  make start                        # Start all core services"
	@echo "  make shell                        # Enter workspace shell (as ivpldock)"
	@echo "  make exec CMD=\"composer -V\"        # Run a one-off command in workspace"
	@echo "  make install-composer PROJECT=app # composer install in projects/app"
	@echo ""

build: ## Build all core images (default: PHP $(PHP_VERSION))
	@echo "Building images for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build $(CORE_SERVICES)

build-no-cache: ## Build all core images without cache (slower but fresh)
	@echo "Building images (no cache) for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache $(CORE_SERVICES)

build-workspace: ## Build only the workspace image
	@echo "Building workspace image for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache workspace

build-php-fpm: ## Build only the php-fpm image
	@echo "Building PHP-FPM image for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache php-fpm

build-nginx: ## Build only the nginx image
	@echo "Building Nginx image..."
	$(DOCKER_COMPOSE) build --no-cache nginx

build-mariadb: ## Build only the mariadb image
	@echo "Building MariaDB image..."
	$(DOCKER_COMPOSE) build --no-cache mariadb

build-redis: ## Build only the redis image
	@echo "Building Redis image..."
	$(DOCKER_COMPOSE) build --no-cache redis

build-phpmyadmin: ## Build only the phpmyadmin image
	@echo "Building phpMyAdmin image..."
	$(DOCKER_COMPOSE) build --no-cache phpmyadmin

build-php-worker: ## Build only the php-worker image
	@echo "Building PHP Worker image for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache php-worker

build-beanstalkd: ## Build only the beanstalkd + beanstalkd-console images
	@echo "Building Beanstalkd images..."
	$(DOCKER_COMPOSE) build --no-cache beanstalkd beanstalkd-console

start: ## Start all core services (workspace, php-fpm, nginx, mariadb, redis, phpmyadmin, php-worker, beanstalkd)
	@echo "Starting services..."
	$(DOCKER_COMPOSE) up -d $(CORE_SERVICES)
	@echo ""
	@echo "Services started! Access (see 'make config-info' for exact ports):"
	@echo "  Web:        http://localhost"
	@echo "  PhpMyAdmin: http://localhost:<PMA_PORT>"
	@echo "  MariaDB:    localhost:<MARIADB_PORT>"
	@echo "  Redis:      localhost:<REDIS_PORT>"
	@echo ""

stop: ## Stop all running services
	@echo "Stopping services..."
	$(DOCKER_COMPOSE) stop

down: ## Stop and remove all containers (keeps volumes)
	@echo "Taking down services..."
	$(DOCKER_COMPOSE) down

down-volumes: ## Stop and remove all containers AND volumes (destructive)
	@echo "Taking down services with volumes..."
	$(DOCKER_COMPOSE) down -v

restart: down start ## Restart all services

status: ## Show status of all services
	$(DOCKER_COMPOSE) ps

validate: ## Validate docker-compose.yml + .env.docker resolve cleanly
	@$(DOCKER_COMPOSE) config --quiet && echo "docker-compose.yml + .env.docker: OK"

logs: ## Show real-time logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-workspace: ## Show logs from the workspace service
	$(DOCKER_COMPOSE) logs -f workspace

logs-php-fpm: ## Show logs from the php-fpm service
	$(DOCKER_COMPOSE) logs -f php-fpm

logs-nginx: ## Show logs from the nginx service
	$(DOCKER_COMPOSE) logs -f nginx

logs-mariadb: ## Show logs from the mariadb service
	$(DOCKER_COMPOSE) logs -f mariadb

logs-redis: ## Show logs from the redis service
	$(DOCKER_COMPOSE) logs -f redis

logs-phpmyadmin: ## Show logs from the phpmyadmin service
	$(DOCKER_COMPOSE) logs -f phpmyadmin

logs-php-worker: ## Show logs from the php-worker service
	$(DOCKER_COMPOSE) logs -f php-worker

logs-beanstalkd: ## Show logs from the beanstalkd + beanstalkd-console services
	$(DOCKER_COMPOSE) logs -f beanstalkd beanstalkd-console

# NOTE: shell/exec/install-* run as the `ivpldock` user (UID/GID from
# WORKSPACE_PUID/WORKSPACE_PGID, matching the host user) on purpose. The
# workspace image's default user is root; running composer/npm/artisan as
# root here would create root-owned files under the shared project mount
# that your host user then can't touch without sudo. Use root-shell for the
# rare case you actually need root inside the container.
shell: ## Enter workspace container shell as ivpldock (matches host UID/GID)
	$(DOCKER_COMPOSE) exec -u ivpldock workspace bash

root-shell: ## Enter workspace container shell as root
	$(DOCKER_COMPOSE) exec -u root workspace bash

exec: ## Run a command in workspace as ivpldock (use: make exec CMD="your command")
	$(DOCKER_COMPOSE) exec -u ivpldock workspace bash -c "$(CMD)"

redis-cli: ## Open a redis-cli session against the redis service
	@$(DOCKER_COMPOSE) exec redis redis-cli -a "$$(grep -m1 '^REDIS_PASSWORD=' .env.docker | cut -d= -f2-)"

clean: ## Remove ivpldock's own stopped containers + dangling images (safe on shared hosts)
	@echo "Cleaning ivpldock containers and images..."
	$(DOCKER_COMPOSE) down --remove-orphans
	docker image prune -f --filter "label=com.docker.compose.project=ivpldock"

clean-all: ## Prune ALL unused Docker images/volumes/build-cache on this host (affects every project, not just ivpldock)
	@echo "WARNING: this prunes Docker state for every project on this host, not just ivpldock."
	@echo "Cleaning all Docker artifacts..."
	docker system prune -f
	docker volume prune -f

fix-permissions: ## Chown host-mounted data/log dirs back to WORKSPACE_PUID:WORKSPACE_PGID
	@echo "Fixing ownership of logs/nginx, DATA_PATH_HOST, and mariadb/nginx config dirs..."
	@PUID=$$(grep -m1 '^WORKSPACE_PUID=' .env.docker | cut -d= -f2-); \
	PGID=$$(grep -m1 '^WORKSPACE_PGID=' .env.docker | cut -d= -f2-); \
	DATA_HOST=$$(grep -m1 '^DATA_PATH_HOST=' .env.docker | cut -d= -f2-); \
	DATA_HOST=$${DATA_HOST/#\~/$$HOME}; \
	docker run --rm \
		-v "$$(pwd)/logs/nginx:/fix/logs-nginx" \
		-v "$$(pwd)/nginx:/fix/nginx" \
		-v "$$(pwd)/mariadb:/fix/mariadb" \
		-v "$$DATA_HOST:/fix/data-path-host" \
		alpine chown -R "$$PUID:$$PGID" \
			/fix/logs-nginx /fix/nginx /fix/mariadb /fix/data-path-host
	@echo "Done. Nginx site configs should log to stdout/stderr (see nginx.conf), not per-site files, to avoid this recurring."

test-workspace: ## Test workspace image (PHP version, Node, Yarn, etc)
	@echo "Testing workspace image..."
	$(DOCKER_COMPOSE) up -d workspace
	@sleep 3
	$(DOCKER_COMPOSE) exec -T -u ivpldock workspace bash -c " \
		echo '=== PHP Version ===' && \
		php -v && \
		echo '=== Node Version ===' && \
		node --version && \
		echo '=== Yarn Version ===' && \
		yarn --version && \
		echo '=== Npm Version ===' && \
		npm --version && \
		echo '=== Workspace User ===' && \
		id && \
		echo '=== Tests Passed! ==='\
	"
	@$(DOCKER_COMPOSE) stop workspace

test-multi: ## Test build across PHP 8.2, 8.3, 8.4
	@echo "Testing PHP 8.2, 8.3, 8.4..."
	@for version in 8.2 8.3 8.4; do \
		echo ""; \
		echo "===== Testing PHP $$version ====="; \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version build --no-cache workspace && \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version up -d workspace && \
		sleep 2 && \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version exec -T workspace php -v && \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version stop workspace; \
	done

# PROJECT selects a subdirectory of APP_CODE_PATH_CONTAINER (/var/www/projects
# by default) to install into — there's no single composer.json/package.json
# at the shared projects root, so PROJECT is required.
ifndef PROJECT
define PROJECT_REQUIRED_MSG
Set PROJECT to the project directory under /var/www/projects, e.g.:
  make install-composer PROJECT=myapp
endef
endif

install-composer: ## Install composer packages (use: make install-composer PROJECT=name)
ifndef PROJECT
	$(error $(PROJECT_REQUIRED_MSG))
endif
	$(DOCKER_COMPOSE) exec -u ivpldock workspace bash -c "cd /var/www/projects/$(PROJECT) && composer install"

install-npm: ## Install npm packages (use: make install-npm PROJECT=name)
ifndef PROJECT
	$(error $(PROJECT_REQUIRED_MSG))
endif
	$(DOCKER_COMPOSE) exec -u ivpldock workspace bash -c "cd /var/www/projects/$(PROJECT) && npm install"

install-yarn: ## Install yarn packages (use: make install-yarn PROJECT=name)
ifndef PROJECT
	$(error $(PROJECT_REQUIRED_MSG))
endif
	$(DOCKER_COMPOSE) exec -u ivpldock workspace bash -c "cd /var/www/projects/$(PROJECT) && yarn install"

install-all: ## Install composer, npm, and yarn packages (use: make install-all PROJECT=name)
	@$(MAKE) install-composer PROJECT=$(PROJECT)
	@$(MAKE) install-npm PROJECT=$(PROJECT)
	@$(MAKE) install-yarn PROJECT=$(PROJECT)

dev-setup: build start ## Complete development setup (build + start)
	@echo ""
	@echo "Development environment ready!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Enter workspace: make shell"
	@echo "  2. Install deps:    make install-all PROJECT=yourproject"
	@echo "  3. View logs:       make logs"
	@echo ""

php-version: ## Show PHP version in container
	$(DOCKER_COMPOSE) exec workspace php -v

node-version: ## Show Node version in container
	$(DOCKER_COMPOSE) exec workspace node --version

yarn-version: ## Show Yarn version in container
	$(DOCKER_COMPOSE) exec workspace yarn --version

npm-version: ## Show Npm version in container
	$(DOCKER_COMPOSE) exec workspace npm --version

db-init: ## Create the MARIADB_DATABASE database if it doesn't exist
	@ROOT_PW=$$(grep -m1 '^MARIADB_ROOT_PASSWORD=' .env.docker | cut -d= -f2-); \
	DB_NAME=$$(grep -m1 '^MARIADB_DATABASE=' .env.docker | cut -d= -f2-); \
	$(DOCKER_COMPOSE) exec mariadb mysql -uroot -p"$$ROOT_PW" -e "CREATE DATABASE IF NOT EXISTS \`$$DB_NAME\`;"

db-shell: ## Enter MariaDB shell as root
	@ROOT_PW=$$(grep -m1 '^MARIADB_ROOT_PASSWORD=' .env.docker | cut -d= -f2-); \
	$(DOCKER_COMPOSE) exec mariadb mysql -uroot -p"$$ROOT_PW"

config-info: ## Show current configuration from .env.docker
	@echo "Current Configuration:"
	@grep -E "^(PHP_VERSION|WORKSPACE_|MARIADB_|REDIS_|NGINX_|PMA_)" .env.docker | sed 's/^/  /'

lint-dockerfile: ## Lint all Dockerfiles under .docker/
	@echo "Linting Dockerfiles..."
	@for dockerfile in .docker/*/Dockerfile; do \
		echo "Checking $$dockerfile..."; \
		docker run --rm -i hadolint/hadolint < "$$dockerfile" || true; \
	done
