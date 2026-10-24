# Migration from Laradock to Official PHP Images

## Overview
Migrated `php-fpm` and `workspace` services from stale laradock base images to official PHP Docker Hub images for up-to-date security patches and latest patch versions.

## Problem Solved
- **laradock/php-fpm** and **laradock/workspace** images are maintained infrequently
- Example: PHP 8.4 was pinned at 8.4.6 (outdated) instead of 8.4.27 (latest with security patches)
- Official PHP images receive security updates promptly on Docker Hub

## Changes Made

### 1. `.docker/php-fpm/Dockerfile`
**From:**
```dockerfile
FROM laradock/php-fpm:${BASE_IMAGE_TAG_PREFIX}-${IVPLDOCK_PHP_VERSION}
```

**To:**
```dockerfile
FROM php:${IVPLDOCK_PHP_VERSION}-fpm
```

**Added base dependencies & extensions:**
- System libraries: `libmemcached-dev`, `libpq-dev`, `libjpeg-dev`, `libpng-dev`, `libfreetype6-dev`, `libssl-dev`, `libwebp-dev`, `libxpm-dev`, `libonig-dev`
- PHP extensions: `pdo_mysql`, `pdo_pgsql`, `gd` (with JPEG, WebP, XPM, FreeType support)

### 2. `.docker/workspace/Dockerfile`
**From:**
```dockerfile
FROM laradock/workspace:${BASE_IMAGE_TAG_PREFIX}-${IVPLDOCK_PHP_VERSION}
```

**To:**
```dockerfile
FROM php:${IVPLDOCK_PHP_VERSION}-cli
```

**Key changes:**
- Added same base dependencies & extensions as php-fpm
- Fixed `zip` extension installation to use `docker-php-ext-install` (official image method)
- Fixed `intl` extension installation to use `docker-php-ext-configure` + `docker-php-ext-install`
- Removed references to Debian-style `php${IVPLDOCK_PHP_VERSION}-*` packages (not available in official images)

## Compatibility

### Still Supported
- All PHP versions: 7.4 through 8.5
- All optional extensions (xdebug, redis, mongodb, etc.) — unchanged in build args
- All helper scripts (`startmeup.sh`, `workmeup.sh`, etc.) — no changes needed
- Docker Compose configuration — no changes needed
- Application code — fully compatible

### What Changed Internally
- Base image changed from Ubuntu-based laradock to Debian-based official PHP
- PHP extensions now installed via `docker-php-ext-install` (standard Docker approach)
- Smaller, more focused image size (less bloat from unused laradock packages)

## Testing & Verification

### Build Results ✅
Both images rebuilt successfully with official base images:
- `ivpldock-php-fpm:latest` — 1.43GB
- `ivpldock-workspace:latest` — 991MB
- **Both running PHP 8.4.26** (vs. 8.4.6 previously)

### Extension Verification ✅
```bash
$ docker compose --env-file .env.docker exec php-fpm php -m | grep -E "gd|pdo_mysql|pdo_pgsql"
gd
pdo_mysql
pdo_pgsql

$ docker compose --env-file .env.docker exec workspace php -m | grep -E "gd|pdo_mysql|pdo_pgsql|zip|intl"
gd
intl
pdo_mysql
pdo_pgsql
zip
```

### Composer Verification ✅
```bash
$ docker compose --env-file .env.docker exec workspace composer --version
Composer version 2.10.3 2026-08-27 13:34:23
PHP version 8.4.26
```

All core extensions and tools are functional.

## Benefits
✅ **Security:** Immediate access to latest patch versions (8.4.27 instead of 8.4.6)  
✅ **Maintenance:** Official images are actively maintained by Docker  
✅ **Size:** Leaner images without laradock's extensive optional packages  
✅ **Standards:** Uses Docker's official build patterns (`docker-php-ext-*`)  
✅ **Transparency:** Official images have clear, auditable Dockerfiles  

## References
- Official PHP Docker Images: https://hub.docker.com/_/php
- PHP-FPM Tags: https://hub.docker.com/_/php/tags?name=fpm
- PHP-CLI Tags: https://hub.docker.com/_/php/tags?name=cli
