# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Docker-based development environment for InvoicePlane**, forked from Laradock. It provides a containerized PHP development stack with support for multiple PHP versions (7.4 through 8.4).

### Architecture

**Core Services:**
- **Workspace**: Utility container for CLI tasks (Composer, Node, npm, yarn)
- **PHP-FPM**: Application runtime (configurable PHP version)
- **Nginx**: Web server with per-site configuration
- **MariaDB**: Default database (MySQL compatible)
- **Redis**: Cache/session store (optional but commonly enabled)
- **PHP-Worker**: Background job processing

**Optional Services**: MongoDB, PostgreSQL, MySQL, Memcached, Elasticsearch, MailPit, PhpMyAdmin, and 40+ others defined in `.docker/`

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

### Xdebug Configuration

**Critical Security Rule:** Xdebug must NEVER autostart in containers.

- Always use **trigger mode** (not autostart) to prevent build-time connection warnings
- Document the trigger method in comments
- Xdebug 3 (PHP 8.x): Use `xdebug.start_with_request=trigger`
- Xdebug 2 (older PHP): Keep `remote_autostart=0`

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
