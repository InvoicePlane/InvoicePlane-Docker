.PHONY: help build build-no-cache start stop down logs clean restart shell test dev-setup

DOCKER_COMPOSE := docker-compose --env-file .env.docker
PHP_VERSION ?= 8.2

help: ## Display this help message
	@echo "InvoicePlane Docker (ivpldock) - Available Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build                  # Build all images for PHP 8.2"
	@echo "  make build PHP_VERSION=8.3  # Build all images for PHP 8.3"
	@echo "  make start                  # Start core services"
	@echo "  make shell                  # Enter workspace shell"
	@echo ""

build: ## Build Docker images (default: PHP 8.2)
	@echo "Building images for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build workspace php-fpm nginx

build-no-cache: ## Build Docker images without cache (slower but fresh)
	@echo "Building images (no cache) for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache workspace php-fpm nginx

build-workspace: ## Build only workspace image
	@echo "Building workspace image for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache workspace

build-php-fpm: ## Build only PHP-FPM image
	@echo "Building PHP-FPM image for PHP $(PHP_VERSION)..."
	$(DOCKER_COMPOSE) -e PHP_VERSION=$(PHP_VERSION) build --no-cache php-fpm

build-nginx: ## Build only Nginx image
	@echo "Building Nginx image..."
	$(DOCKER_COMPOSE) build --no-cache nginx

start: ## Start core services (workspace, php-fpm, nginx, mariadb, redis, php-worker)
	@echo "Starting services..."
	$(DOCKER_COMPOSE) up -d workspace php-fpm nginx mariadb redis php-worker
	@echo ""
	@echo "Services started! Access:"
	@echo "  Web:       http://localhost"
	@echo "  PhpMyAdmin: http://localhost:8081"
	@echo ""

stop: ## Stop all running services
	@echo "Stopping services..."
	$(DOCKER_COMPOSE) stop

down: ## Stop and remove all containers (keeps volumes)
	@echo "Taking down services..."
	$(DOCKER_COMPOSE) down

down-volumes: ## Stop and remove all containers AND volumes
	@echo "Taking down services with volumes..."
	$(DOCKER_COMPOSE) down -v

logs: ## Show real-time logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-workspace: ## Show logs from workspace service
	$(DOCKER_COMPOSE) logs -f workspace

logs-php-fpm: ## Show logs from PHP-FPM service
	$(DOCKER_COMPOSE) logs -f php-fpm

logs-nginx: ## Show logs from Nginx service
	$(DOCKER_COMPOSE) logs -f nginx

shell: ## Enter workspace container shell
	$(DOCKER_COMPOSE) exec workspace bash

root-shell: ## Enter workspace container as root
	$(DOCKER_COMPOSE) exec -u root workspace bash

exec: ## Execute a command in workspace (use: make exec CMD="your command")
	$(DOCKER_COMPOSE) exec workspace bash -c "$(CMD)"

clean: ## Remove unused Docker images and dangling volumes
	@echo "Cleaning Docker artifacts..."
	docker system prune -f
	docker volume prune -f

restart: down start ## Restart all services

status: ## Show status of all services
	$(DOCKER_COMPOSE) ps

test-workspace: ## Test workspace image (PHP version, Node, Yarn, etc)
	@echo "Testing workspace image..."
	$(DOCKER_COMPOSE) up -d workspace
	@sleep 3
	$(DOCKER_COMPOSE) exec -T workspace bash -c " \
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
	@$(DOCKER_COMPOSE) stop

test-multi: ## Test build for multiple PHP versions
	@echo "Testing PHP 8.2, 8.3, 8.4..."
	@for version in 8.2 8.3 8.4; do \
		echo ""; \
		echo "===== Testing PHP $$version ====="; \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version build --no-cache workspace && \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version up -d workspace && \
		sleep 2 && \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version exec -T workspace php -v && \
		$(DOCKER_COMPOSE) -e PHP_VERSION=$$version stop; \
	done

install-composer: ## Install composer packages in workspace
	$(DOCKER_COMPOSE) exec workspace bash -c "cd /var/www/projects && composer install"

install-npm: ## Install npm packages in workspace
	$(DOCKER_COMPOSE) exec workspace bash -c "cd /var/www/projects && npm install"

install-yarn: ## Install yarn packages in workspace
	$(DOCKER_COMPOSE) exec workspace bash -c "cd /var/www/projects && yarn install"

install-all: ## Install composer, npm, and yarn packages
	@make install-composer
	@make install-npm
	@make install-yarn

dev-setup: build start ## Complete development setup (build + start)
	@echo ""
	@echo "✅ Development environment ready!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Enter workspace: make shell"
	@echo "  2. Install deps:   make install-all"
	@echo "  3. View logs:      make logs"
	@echo ""

php-version: ## Show PHP version in container
	$(DOCKER_COMPOSE) exec workspace php -v

node-version: ## Show Node version in container
	$(DOCKER_COMPOSE) exec workspace node --version

yarn-version: ## Show Yarn version in container
	$(DOCKER_COMPOSE) exec workspace yarn --version

npm-version: ## Show Npm version in container
	$(DOCKER_COMPOSE) exec workspace npm --version

db-init: ## Initialize MariaDB database
	$(DOCKER_COMPOSE) exec mariadb mysql -uroot -p$(MARIADB_ROOT_PASSWORD) -e "CREATE DATABASE IF NOT EXISTS $(MARIADB_DATABASE);"

db-shell: ## Enter MariaDB shell
	$(DOCKER_COMPOSE) exec mariadb mysql -uroot -p$(MARIADB_ROOT_PASSWORD)

config-info: ## Show current configuration from .env.docker
	@echo "Current Configuration:"
	@grep -E "^(PHP_VERSION|WORKSPACE_|MARIADB_|REDIS_|NGINX_)" .env.docker | sed 's/^/  /'

lint-dockerfile: ## Lint all Dockerfiles
	@echo "Linting Dockerfiles..."
	@for dockerfile in .docker/*/Dockerfile; do \
		echo "Checking $$dockerfile..."; \
		docker run --rm -i hadolint/hadolint < "$$dockerfile" || true; \
	done
