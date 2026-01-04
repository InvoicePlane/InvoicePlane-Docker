# InvoicePlane Docker

Docker-compose with a webserver, MySQL, phpmyadmin and redis
- docker-compose.yml
- .env

## Quick Start

1. Create your environment file:
   ```bash
   cp .env.example .env.docker
   ```

2. Build and start containers:
   ```bash
   ./builddmeup.sh
   ```

## Helper Scripts

All scripts include error handling and validation to ensure a smooth experience.

### Building

Build and start containers:
- `./buildmeup.sh` - Build and start in foreground (with logs)
- `./builddmeup.sh` - Build and start in background (detached mode)

### Starting/Stopping

Start existing containers (without rebuilding):
- `./startmeup.sh` - Start in foreground (with logs)
- `./startmeup.sh` - Start in background (detached mode)
- `./down.sh` - Stop and remove all containers and volumes

### Accessing Containers

Enter a running container:
- `./workmeup.sh` - Enter workspace as ivpldock user
- `./rootmeup.sh` - Enter workspace as root
- `./phpmeup.sh` - Enter php-fpm container
- `./worker.sh` - Enter php-worker container

### Running Commands

Execute commands inside containers from your host:
```bash
./docker-exec.sh <container> <project> <command>
```

Examples:
```bash
# Run composer install
./docker-exec.sh workspace myproject "composer install"

# Run Laravel migrations
./docker-exec.sh php-fpm invoiceplane "php artisan migrate --force"

# Run tests
./docker-exec.sh workspace myproject "php artisan test"

# Build assets
./docker-exec.sh workspace myapp "npm run build"
```

## Continuous Integration

This repository includes GitHub Actions workflows that automatically test Docker builds for:
- PHP 8.2
- PHP 8.3
- PHP 8.4

The CI pipeline verifies:
- All containers build successfully
- PHP extensions (including zip) are properly installed
- Services start correctly

## Directories

| Directory	|      Purpose   																											|
|----------	|:--------------------------------------------------------------:			|
| ./.docker 	|  For all the DockerFiles 	|																																				|
| ./sites 	|  For all the sites (for the nginx webserver)												|
| ./.github/workflows | GitHub Actions CI/CD pipelines |

## Configuration

Edit `.env.docker` to customize:
- PHP version (8.1, 8.2, 8.3, 8.4)
- Database settings
- Port mappings
- Service options

## Troubleshooting

### Container not starting?
Check if the .env.docker file exists:
```bash
ls -la .env.docker
```

### Want to see running containers?
```bash
docker compose --env-file .env.docker ps
```

### View container logs?
```bash
docker compose --env-file .env.docker logs -f <container_name>
```

> **Note**: The helper scripts use `docker-compose` for backward compatibility, but `docker compose` (v2) is recommended for manual commands.

## Origins

This script was originally called Laradock. We've forked it to target just the specific images that are needed to run InvoicePlane.

Link to Laradock: [laradock](https://github.com/laradock/laradock/)
We've included their license file in this repository.
