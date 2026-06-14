# InvoicePlane Docker Development Guidelines

## Overview

This repository provides a complete Docker-based development environment for InvoicePlane, forked from Laradock and optimized for InvoicePlane-specific needs.

## Project Structure

```
InvoicePlane-Docker/
├── .docker/              # All Dockerfile definitions
│   ├── php-fpm/         # PHP-FPM container configuration
│   ├── workspace/       # Workspace container for CLI operations
│   ├── nginx/           # Nginx web server
│   ├── mariadb/         # MariaDB database
│   └── ...              # Other service containers
├── .github/             # GitHub Actions CI/CD workflows
├── sites/               # Nginx site configurations
├── *.sh                 # Helper scripts for common operations
├── docker-compose.yml   # Main docker-compose configuration
└── .env.example         # Example environment configuration
```

## Development Workflow

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/InvoicePlane/InvoicePlane-Docker.git
   cd InvoicePlane-Docker
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env.docker
   ```

3. **Configure your environment**
   - Edit `.env.docker` to set PHP version, ports, and paths
   - Adjust `APP_CODE_PATH_HOST` to point to your projects directory

4. **Build and start containers**
   ```bash
   ./builddmeup.sh  # Build and start in background
   ```

### Working with Containers

#### Helper Scripts
Use the provided helper scripts for common operations:

- **Building**: `./buildmeup.sh` (foreground) or `./builddmeup.sh` (background)
- **Starting**: `./startmeup.sh` (foreground) or `./starmeup.sh` (background)
- **Stopping**: `./down.sh`
- **Shell Access**:
  - `./workmeup.sh` - Enter workspace as ivpldock user
  - `./rootmeup.sh` - Enter workspace as root
  - `./phpmeup.sh` - Enter php-fpm container
  - `./worker.sh` - Enter php-worker container

#### Executing Commands
Use `docker-exec.sh` to run commands in containers:
```bash
./docker-exec.sh <container> <project> <command>
```

Examples:
```bash
# Composer operations
./docker-exec.sh workspace invoiceplane "composer install"
./docker-exec.sh workspace invoiceplane "composer update"

# Laravel/Artisan commands
./docker-exec.sh php-fpm invoiceplane "php artisan migrate"
./docker-exec.sh workspace invoiceplane "php artisan test"

# NPM operations
./docker-exec.sh workspace invoiceplane "npm install"
./docker-exec.sh workspace invoiceplane "npm run build"
```

## Code Standards

### PHP Development

- **PHP Version**: Support PHP 7.4, 8.0, 8.1, 8.2, 8.3, 8.4
- **Framework**: Built for Laravel/CodeIgniter applications
- **Extensions**: All required PHP extensions are pre-installed

### Docker Standards

1. **Dockerfile Changes**
   - Keep changes minimal and well-documented
   - Test across all supported PHP versions
   - Add comments explaining complex configurations

2. **Build Optimization**
   - Leverage Docker layer caching
   - Order commands from least to most frequently changing
   - Use multi-stage builds where appropriate

3. **Environment Configuration**
   - Never commit `.env.docker` files
   - Document all new environment variables in `.env.example`
   - Use sensible defaults

## Debugging

### Xdebug Configuration

Xdebug is configured in **trigger mode** to prevent connection warnings during builds.

#### Activating Xdebug

**For Web Requests:**
1. Install Xdebug Helper browser extension
2. Set cookie: `XDEBUG_TRIGGER=1`
3. Or add query parameter: `?XDEBUG_TRIGGER=1`

**For CLI Commands:**
```bash
# Inside container
XDEBUG_TRIGGER=1 php artisan test

# From host
./docker-exec.sh workspace myproject "XDEBUG_TRIGGER=1 php artisan test"
```

#### IDE Configuration

**PHPStorm:**
1. Settings → PHP → Debug → Port: 9003
2. Settings → PHP → Servers → Name: ivpldock
3. Enable "Listen for PHP Debug Connections"

**VS Code:**
1. Install PHP Debug extension
2. Configure launch.json with port 9003
3. Set path mappings

### Common Issues

#### Container Won't Start
```bash
# Check if .env.docker exists
ls -la .env.docker

# View logs
docker compose --env-file .env.docker logs -f <container_name>

# Check running containers
docker compose --env-file .env.docker ps
```

#### Port Conflicts
- Check if ports are already in use: `netstat -tlnp | grep <port>`
- Modify ports in `.env.docker`

#### Permission Issues
- Ensure `PUID` and `PGID` in `.env.docker` match your user
- Run: `id -u` and `id -g` to get your user/group IDs

## Testing

### CI/CD Pipeline

GitHub Actions automatically test:
- PHP 8.2, 8.3, 8.4 builds
- Container startup
- PHP extension installation
- Basic functionality

### Local Testing

Before committing changes:

```bash
# Test build for specific PHP version
docker compose --env-file .env.docker build workspace php-fpm

# Start containers
docker compose --env-file .env.docker up -d

# Verify PHP version
docker compose --env-file .env.docker exec workspace php -v

# Run application tests
./docker-exec.sh workspace invoiceplane "php artisan test"
```

## Contributing

### Pull Request Guidelines

1. **Branch Naming**: Use descriptive names
   - `feature/add-redis-support`
   - `fix/xdebug-connection-warnings`
   - `docs/improve-readme`

2. **Commit Messages**: Be clear and descriptive
   - Start with verb: "Add", "Fix", "Update", "Remove"
   - Reference issues: "Fix #123: Resolve port conflict"

3. **Documentation**: Update relevant docs
   - README.md for user-facing changes
   - .env.example for new variables
   - Inline comments for complex code

4. **Testing**: Ensure all tests pass
   - Local testing before push
   - CI/CD must pass
   - Test across PHP versions if applicable

### Code Review Process

1. Automated checks must pass
2. Manual review by maintainers
3. Address feedback promptly
4. Squash commits if requested

## Performance Optimization

### Build Caching

Docker automatically caches layers:
- Built images persist even after stopping containers
- Only changed layers trigger rebuilds
- Use `--no-cache` sparingly

### Volume Performance

**macOS/Windows:**
- Use `:cached` flag for better performance
- Consider Docker Sync for large projects

**Linux:**
- Native performance, no special flags needed

## Security

### Best Practices

1. **Secrets Management**
   - Never commit sensitive data
   - Use environment variables
   - Rotate credentials regularly

2. **Container Security**
   - Keep base images updated
   - Run as non-root user where possible
   - Limit container capabilities

3. **Network Security**
   - Use internal networks for service communication
   - Expose only necessary ports
   - Configure firewalls appropriately

## Maintenance

### Regular Updates

1. **Base Images**: Update quarterly
2. **PHP Versions**: Support latest stable releases
3. **Dependencies**: Keep composer/npm packages current

### Cleanup

```bash
# Remove stopped containers
docker compose --env-file .env.docker down

# Remove volumes (WARNING: deletes data)
docker compose --env-file .env.docker down -v

# Clean up Docker system
docker system prune -a
```

## Resources

- **Laradock**: Original upstream project - [github.com/laradock/laradock](https://github.com/laradock/laradock)
- **InvoicePlane**: Main application - [github.com/InvoicePlane/InvoicePlane](https://github.com/InvoicePlane/InvoicePlane)
- **Docker Documentation**: [docs.docker.com](https://docs.docker.com)
- **PHP Docker Images**: [hub.docker.com/_/php](https://hub.docker.com/_/php)

## Support

For issues or questions:
1. Check existing GitHub issues
2. Review documentation thoroughly
3. Create detailed issue with reproduction steps
4. Include relevant logs and configuration
