# InvoicePlane Docker

> **Complete Docker-based development environment for InvoicePlane**

A containerized development stack featuring PHP, Nginx, MariaDB, Redis, and more. Built on Laradock and optimized for InvoicePlane development with support for PHP 7.4 through 8.4.

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/InvoicePlane/InvoicePlane-Docker.git
   cd InvoicePlane-Docker
   ```

2. **Create your environment file**
   ```bash
   cp .env.example .env.docker
   ```

3. **Configure your setup** (optional)
   ```bash
   # Edit .env.docker to customize:
   # - PHP version (8.1, 8.2, 8.3, 8.4)
   # - Database settings
   # - Port mappings
   nano .env.docker
   ```

4. **Build and start containers**
   ```bash
   ./builddmeup.sh
   ```

5. **Verify installation**
   ```bash
   docker compose --env-file .env.docker ps
   ```

Your development environment is now ready! 🎉

## 📖 Setting Up Your First Project (InvoicePlane)

This guide will walk you through setting up InvoicePlane v1 step by step.

### Step 1: Prepare Your Project Directory

First, make sure your projects directory exists. By default, this is `~/projects`:

```bash
# Create the projects directory if it doesn't exist
mkdir -p ~/projects

# Clone InvoicePlane v1 into your projects directory
cd ~/projects
git clone https://github.com/InvoicePlane/InvoicePlane.git ivplv1
cd ivplv1
```

> 💡 **Note**: The folder name `ivplv1` will be used in the next steps. You can choose any name you like, but remember to use it consistently.

### Step 2: Configure Your Environment

Open your `.env.docker` file in the InvoicePlane-Docker directory:

```bash
cd /path/to/InvoicePlane-Docker
nano .env.docker
```

Find the line that says `APP_CODE_PATH_HOST` and make sure it points to your projects directory:

```bash
# This should match where you created your projects folder
APP_CODE_PATH_HOST=~/projects/
```

> 💡 **Tip**: If you used a different path for your projects, update this line accordingly. For example, if your projects are in `/home/username/myprojects/`, use that path instead.

### Step 3: Create Your Nginx Configuration

Now we'll tell Nginx how to serve your InvoicePlane project:

1. **Copy the example configuration:**
   ```bash
   cd /path/to/InvoicePlane-Docker
   cp sites/copyme.conf.example sites/ivplv1.conf
   ```

2. **Open the configuration file:**
   ```bash
   nano sites/ivplv1.conf
   ```

3. **Replace all instances of `copyme` with `ivplv1`** and **remove `/public` from the root path** (there are 4 places to change):
   - Line 5: `server_name copyme.local;` → `server_name ivplv1.test;`
   - Line 6: `root /var/www/projects/copyme/public;` → `root /var/www/projects/ivplv1;` *(also remove /public)*
   - Line 34: `error_log /var/log/nginx/copyme_error.log;` → `error_log /var/log/nginx/ivplv1_error.log;`
   - Line 35: `access_log /var/log/nginx/copyme_access.log;` → `access_log /var/log/nginx/ivplv1_access.log;`

   > 💡 **Why remove `/public`?** InvoicePlane v1 doesn't use a public directory like some frameworks. The main files are in the root of the project.
   
   > 💡 **Why use `.test` instead of `.local`?** The `.test` domain is reserved for testing and won't conflict with real domains. You can use `.local` if you prefer, just be consistent.

4. **Save and close the file** (in nano: press `Ctrl+X`, then `Y`, then `Enter`)

### Step 4: Add Domain to Your Hosts File

Tell your computer that `ivplv1.test` should point to your local Docker environment:

**On Linux/Mac:**
```bash
sudo nano /etc/hosts
```

**On Windows:**
Open Notepad as Administrator, then open:
```
C:\Windows\System32\drivers\etc\hosts
```

Add this line:
```
127.0.0.1    ivplv1.test
```

Save and close the file.

### Step 5: Start Docker

Now start your Docker environment:

```bash
cd /path/to/InvoicePlane-Docker
./starmeup.sh
```

> 💡 **What's happening?** Docker is:
> - Building the containers (first time takes 5-10 minutes)
> - Starting PHP, Nginx, MariaDB, and other services
> - Reading your `ivplv1.conf` file to know how to serve your project
> - Making your project available at `http://ivplv1.test`

You'll see lots of output in your terminal. This is normal! Look for messages saying containers are starting.

### Step 6: Verify Everything is Running

In a new terminal window (keep Docker running in the first one):

```bash
cd /path/to/InvoicePlane-Docker
docker compose --env-file .env.docker ps
```

You should see all services with "Up" status:
```
NAME                STATUS
workspace           Up
php-fpm             Up
nginx               Up
mariadb             Up
redis               Up
```

### Step 7: Access Your Project

Open your web browser and go to:
```
http://ivplv1.test
```

You should see your InvoicePlane installation! 🎉

### Step 8: Stop Docker When Done

When you're finished working, stop Docker:

**Option 1: Stop from terminal** (if Docker is running in foreground)
- Press `Ctrl+C` in the terminal where Docker is running

**Option 2: Stop and remove everything**
```bash
./down.sh
```

This stops all containers and removes them (but keeps your code safe).

### Step 9: Restart Docker Later

When you want to work again, just run:
```bash
./starmeup.sh
```

This is much faster than the first build! ⚡

---

### 🆘 Troubleshooting

**Problem**: Can't access `http://ivplv1.test`
- **Solution**: Make sure you added `127.0.0.1 ivplv1.test` to your hosts file
- **Solution**: Make sure Docker is running (`docker compose ps`)
- **Solution**: Try `http://localhost` instead

**Problem**: "Port already in use"
- **Solution**: Another service is using port 80. Either stop it, or change the port in `.env.docker`:
  ```bash
  NGINX_HOST_HTTP_PORT=8080
  ```
  Then **restart Docker** for the change to take effect:
  ```bash
  ./down.sh
  ./starmeup.sh
  ```
  Access your site at `http://ivplv1.test:8080`

**Problem**: "Permission denied" errors
- **Solution**: Check your `PUID` and `PGID` in `.env.docker` match your user:
  ```bash
  id -u  # This is your PUID
  id -g  # This is your PGID
  ```

**Problem**: Changes to nginx config not working
- **Solution**: Restart Docker to reload the configuration:
  ```bash
  ./down.sh
  ./starmeup.sh
  ```

## 📦 What's Included

### Services
- **PHP-FPM** - PHP 7.4, 8.0, 8.1, 8.2, 8.3, 8.4 (configurable)
- **Workspace** - CLI tools, Composer, Node.js, Git
- **Nginx** - Web server with optimized configuration
- **MariaDB** - Database server
- **Redis** - Caching and session storage
- **Beanstalkd** - Queue management
- **phpMyAdmin** - Database management interface
- **Redis Web UI** - Redis monitoring interface

### Features
- ✅ Multiple PHP versions support
- ✅ Xdebug with trigger mode
- ✅ Pre-configured for Laravel and CodeIgniter
- ✅ Helper scripts for common tasks
- ✅ GitHub Actions CI/CD
- ✅ Optimized Docker layer caching

## 🛠️ Helper Scripts

All scripts include error handling and validation to ensure a smooth experience.

### 🔨 Building

**Build and start containers:**
| Script | Mode | Description |
|--------|------|-------------|
| `./buildmeup.sh` | Foreground | Build and start with live logs |
| `./builddmeup.sh` | Background | Build and start in detached mode |

### ▶️ Starting/Stopping

**Control existing containers:**
| Script | Mode | Description |
|--------|------|-------------|
| `./starmeup.sh` | Foreground | Start with live logs |
| `./startmeup.sh` | Background | Start in detached mode |
| `./down.sh` | - | Stop and remove all containers and volumes |

### 🖥️ Accessing Containers

**Enter a running container:**
| Script | Container | User | Use Case |
|--------|-----------|------|----------|
| `./workmeup.sh` | workspace | ivpldock | Development tasks, Composer, NPM |
| `./rootmeup.sh` | workspace | root | System administration |
| `./phpmeup.sh` | php-fpm | root | PHP-FPM debugging |
| `./worker.sh` | php-worker | root | Queue worker debugging |

### 🚀 Running Commands

Execute commands inside containers from your host using `docker-exec.sh`:

**Syntax:**
```bash
./docker-exec.sh <container> <project> <command>
```

**Common Examples:**

```bash
# 📦 Composer Operations
./docker-exec.sh workspace myproject "composer install"
./docker-exec.sh workspace myproject "composer update"
./docker-exec.sh workspace myproject "composer require vendor/package"

# 🎨 Laravel/Artisan Commands
./docker-exec.sh php-fpm invoiceplane "php artisan migrate"
./docker-exec.sh php-fpm invoiceplane "php artisan migrate --force"
./docker-exec.sh workspace invoiceplane "php artisan test"
./docker-exec.sh workspace invoiceplane "php artisan db:seed"

# 📊 Database Operations
./docker-exec.sh workspace invoiceplane "php artisan migrate:fresh --seed"
./docker-exec.sh workspace invoiceplane "php artisan migrate:rollback"

# 🔧 NPM Operations
./docker-exec.sh workspace myapp "npm install"
./docker-exec.sh workspace myapp "npm run build"
./docker-exec.sh workspace myapp "npm run dev"
./docker-exec.sh workspace myapp "npm run watch"

# 🧪 Testing
./docker-exec.sh workspace myproject "php artisan test"
./docker-exec.sh workspace myproject "vendor/bin/phpunit"
./docker-exec.sh workspace myproject "php artisan test --filter UserTest"
```

## 🔄 Continuous Integration

This repository includes automated GitHub Actions workflows that test Docker builds.

**Tested PHP Versions:**
- ✅ PHP 8.2
- ✅ PHP 8.3
- ✅ PHP 8.4

**CI Pipeline Verifies:**
- ✅ All containers build successfully
- ✅ PHP extensions are properly installed (zip, etc.)
- ✅ Services start correctly
- ✅ Basic functionality works

**Workflow Triggers:**
- Push to main branches
- Pull requests
- Manual dispatch

## 📁 Directory Structure

| Directory | Purpose |
|-----------|---------|
| `.docker/` | All Dockerfile definitions for services |
| `sites/` | Nginx site configurations |
| `.github/workflows/` | GitHub Actions CI/CD pipelines |
| `*.sh` | Helper scripts for common operations |

## ⚙️ Configuration

### Basic Setup

Edit `.env.docker` to customize your environment:

**Core Settings:**
```bash
# PHP Version
PHP_VERSION=8.1  # Options: 7.4, 8.0, 8.1, 8.2, 8.3, 8.4

# Project Path
APP_CODE_PATH_HOST=../projects/

# Database
MARIADB_VERSION=latest
MARIADB_DATABASE=default
MARIADB_USER=default
MARIADB_PASSWORD=secret

# Ports
NGINX_HOST_HTTP_PORT=80
MARIADB_PORT=3306
REDIS_PORT=6379
```

### 🐳 Docker Build Caching

Docker automatically caches build layers to speed up subsequent builds.

**How It Works:**
1. Docker Compose checks if dependent services need building
2. Uses cached layers if Dockerfile and context haven't changed
3. Only rebuilds layers that have changed

**Benefits:**
- ⚡ Faster rebuild times
- 💾 Efficient resource usage
- 🔄 Smart dependency management

**Tips for Better Caching:**
```bash
# Docker keeps built images in cache even after stopping containers
docker compose --env-file .env.docker ps

# Force complete rebuild only when necessary
docker compose --env-file .env.docker build --no-cache php-fpm

# Build specific service
docker compose --env-file .env.docker build workspace

# Parallel builds for multiple services
docker compose --env-file .env.docker build --parallel
```

**Example Workflow:**
```bash
# First build (takes longer)
docker compose --env-file .env.docker build php-fpm
# ⏱️ 5 minutes

# Build dependent service (uses cache)
docker compose --env-file .env.docker build beanstalkd
# ⏱️ 30 seconds (php-fpm cached!)
```

### 🐛 Xdebug Configuration

Xdebug is configured in **trigger mode** to prevent connection warnings during builds while maintaining full debugging capability.

#### Activation Methods

**1️⃣ Browser Debugging (Web Requests)**

Using Browser Extension:
- Install [Xdebug Helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc) for Chrome
- Or [Xdebug Helper](https://addons.mozilla.org/en-US/firefox/addon/xdebug-helper-for-firefox/) for Firefox
- Click the extension icon to enable debugging

Using Query Parameter:
```
http://your-app.local?XDEBUG_TRIGGER=1
```

Using Cookie:
```javascript
document.cookie = "XDEBUG_TRIGGER=1; path=/";
```

**2️⃣ CLI Debugging (Command Line)**

Inside Container:
```bash
# Enter workspace
./workmeup.sh

# Run with Xdebug
XDEBUG_TRIGGER=1 php artisan test
XDEBUG_TRIGGER=1 php script.php
XDEBUG_TRIGGER=1 vendor/bin/phpunit
```

From Host:
```bash
# Single command with Xdebug
./docker-exec.sh workspace myproject "XDEBUG_TRIGGER=1 php artisan test"

# Composer with Xdebug
./docker-exec.sh workspace myproject "XDEBUG_TRIGGER=1 composer install"
```

**3️⃣ Persistent Debugging (Environment Variable)**

```bash
# Inside container
export XDEBUG_TRIGGER=1
php artisan test  # Now always uses Xdebug
```

#### IDE Configuration

**PHPStorm Setup:**
1. Go to `Settings → PHP → Debug`
2. Set port to `9003`
3. Go to `Settings → PHP → Servers`
4. Add server named `ivpldock`
5. Set path mappings:
   - Local: `/path/to/your/project`
   - Remote: `/var/www/projects/yourproject`
6. Click "Start Listening for PHP Debug Connections" (phone icon)

**VS Code Setup:**
1. Install [PHP Debug extension](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug)
2. Create `.vscode/launch.json`:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Listen for Xdebug",
         "type": "php",
         "request": "launch",
         "port": 9003,
         "pathMappings": {
           "/var/www/projects/yourproject": "${workspaceFolder}"
         }
       }
     ]
   }
   ```
3. Press F5 to start debugging

#### Configuration Files

```bash
# Xdebug settings locations
.docker/php-fpm/xdebug.ini       # PHP-FPM container
.docker/workspace/xdebug.ini     # Workspace container
```

**Default Port:** 9003 (configurable in `.env.docker`)

#### Troubleshooting Xdebug

```bash
# Verify Xdebug is installed
docker compose --env-file .env.docker exec workspace php -v
# Should show: "with Xdebug v3.x.x"

# Check Xdebug configuration
docker compose --env-file .env.docker exec workspace php -i | grep xdebug

# Test Xdebug trigger
docker compose --env-file .env.docker exec workspace bash -c "XDEBUG_TRIGGER=1 php -v"

# View Xdebug logs
docker compose --env-file .env.docker exec workspace cat /tmp/xdebug.log
```

## 🔧 Troubleshooting

### Common Issues

#### ❌ Container Won't Start

**Check environment file exists:**
```bash
ls -la .env.docker
```

**View detailed logs:**
```bash
docker compose --env-file .env.docker logs -f <container_name>
# Examples:
docker compose --env-file .env.docker logs -f workspace
docker compose --env-file .env.docker logs -f php-fpm
```

**Check container status:**
```bash
docker compose --env-file .env.docker ps
docker compose --env-file .env.docker ps -a  # Include stopped containers
```

#### 🔌 Port Already in Use

**Check what's using the port:**
```bash
# Linux/Mac
sudo lsof -i :80
sudo lsof -i :3306

# Or use netstat
netstat -tlnp | grep :80
```

**Solution: Change port in `.env.docker`:**
```bash
NGINX_HOST_HTTP_PORT=8080  # Instead of 80
MARIADB_PORT=3307          # Instead of 3306
```

#### 🔐 Permission Denied Errors

**Check and fix PUID/PGID:**
```bash
# Get your user and group ID
id -u  # Your user ID
id -g  # Your group ID

# Update .env.docker
WORKSPACE_PUID=1000  # Your user ID
WORKSPACE_PGID=1000  # Your group ID
PHP_FPM_PUID=1000
PHP_FPM_PGID=1000

# Rebuild containers
docker compose --env-file .env.docker build workspace php-fpm
docker compose --env-file .env.docker up -d
```

#### 🐌 Slow Performance (macOS/Windows)

**Use cached volume flag:**
```bash
# In .env.docker
APP_CODE_CONTAINER_FLAG=:cached
```

**Consider Docker Sync for large projects:**
- Significant performance improvement
- See [docker-sync documentation](https://docker-sync.readthedocs.io/)

#### 🗄️ Database Connection Failed

**Verify database is running:**
```bash
docker compose --env-file .env.docker ps mariadb
```

**Check database credentials:**
```bash
# In .env.docker
MARIADB_DATABASE=default
MARIADB_USER=default
MARIADB_PASSWORD=secret

# In your app's .env
DB_HOST=mariadb  # Not localhost!
DB_PORT=3306
DB_DATABASE=default
DB_USERNAME=default
DB_PASSWORD=secret
```

**Test connection:**
```bash
docker compose --env-file .env.docker exec workspace mysql -h mariadb -u default -psecret
```

#### 🧹 Clean Up Issues

**Remove all containers and volumes:**
```bash
# WARNING: This deletes all data!
docker compose --env-file .env.docker down -v
```

**Full Docker cleanup:**
```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove all volumes (BE CAREFUL!)
docker volume prune
```

#### 📦 Build Failures

**Clear build cache and rebuild:**
```bash
docker compose --env-file .env.docker build --no-cache --pull <service>
```

**Check Docker disk space:**
```bash
docker system df
```

### Getting Help

**Collect diagnostic information:**
```bash
# Docker version
docker --version
docker compose version

# Container status
docker compose --env-file .env.docker ps

# Recent logs
docker compose --env-file .env.docker logs --tail=50 workspace php-fpm

# System info
docker info
```

**When reporting issues, include:**
1. Steps to reproduce
2. Error messages (full output)
3. Docker and compose versions
4. Operating system
5. Relevant configuration from `.env.docker`

## 📚 Additional Resources

### Documentation
- **Project Guidelines**: [.junie/guidelines.md](.junie/guidelines.md) - Comprehensive development guidelines
- **Copilot Instructions**: [.github/copilot-instructions.md](.github/copilot-instructions.md) - AI coding assistant guidelines
- **Docker Compatibility**: [DOCKER_COMPATIBILITY.md](DOCKER_COMPATIBILITY.md) - Version compatibility matrix

### External Links
- **Laradock**: Original upstream project - [github.com/laradock/laradock](https://github.com/laradock/laradock)
- **InvoicePlane**: Main application - [github.com/InvoicePlane/InvoicePlane](https://github.com/InvoicePlane/InvoicePlane)
- **Docker Documentation**: [docs.docker.com](https://docs.docker.com)
- **Docker Compose Documentation**: [docs.docker.com/compose](https://docs.docker.com/compose)

### Community & Support
- **Issues**: [GitHub Issues](https://github.com/InvoicePlane/InvoicePlane-Docker/issues) - Report bugs and request features
- **Discussions**: [GitHub Discussions](https://github.com/InvoicePlane/InvoicePlane-Docker/discussions) - Ask questions and share ideas
- **Pull Requests**: [Contributing Guidelines](.junie/guidelines.md#contributing) - Submit code improvements

## 🤝 Contributing

We welcome contributions! Please see our [development guidelines](.junie/guidelines.md) for:
- Code standards
- Testing requirements
- Pull request process
- Docker best practices

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly across PHP versions
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📝 License

This project inherits its license from Laradock. See [LICENSE](LICENSE) for details.

## 🙏 Origins & Credits

This project was originally called **Laradock** and has been forked to target specifically the images needed to run InvoicePlane.

- **Laradock**: [github.com/laradock/laradock](https://github.com/laradock/laradock/)
- **License**: Original license file included in this repository

---

**Version**: 2.0  
**Last Updated**: 2025-01-05  
**Maintained by**: [InvoicePlane Team](https://github.com/InvoicePlane)

> **Note**: Helper scripts use `docker-compose` for backward compatibility, but `docker compose` (v2) is recommended for manual commands.
