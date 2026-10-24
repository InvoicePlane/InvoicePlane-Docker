# GitHub Actions: Docker Image Rebuild Workflows

## Overview

Two workflows are now available for building and testing Docker images with different PHP versions:

1. **Automatic Builds** (`build-images.yml`) — Triggered on push to master/develop
2. **Manual Rebuilds** (`rebuild-php-versions.yml`) — On-demand via GitHub Actions UI

---

## Automatic Builds (build-images.yml)

### Trigger
- Any push to `master` or `develop` branches that modifies:
  - `.docker/**` (Dockerfile changes)
  - `.env.docker`
  - `docker-compose.yml`
  - The workflow itself

### Matrix
Automatically builds for: **8.2, 8.3, 8.4, 8.5**

### Jobs
Each PHP version gets:
1. **workspace** image — PHP CLI + Composer + dev tools
2. **php-fpm** image — PHP-FPM application runtime
3. **nginx** — Web server (runs once, not per version)

### Tests
- PHP version verification
- Core extensions check (gd, pdo_mysql, pdo_pgsql, zip, intl)
- Composer availability
- User permissions

### Artifacts
Built images stay in the GitHub Actions runner (not pushed to registry by default).

---

## Manual Rebuilds (rebuild-php-versions.yml)

### Trigger
1. Go to GitHub repo → **Actions** tab
2. Select **"Rebuild Images for Specific PHP Version"**
3. Click **"Run workflow"**

### Options

**PHP Version** (required)
```
- 8.2
- 8.3
- 8.4 (current default, with latest security patches)
- 8.5
```

**Build Scope** (required)
```
- all              → Rebuild all services (workspace, php-fpm, nginx, etc.)
- php-fpm-only    → Just the PHP-FPM image
- workspace-only  → Just the workspace image
```

### Example Scenarios

**Scenario 1: PHP 8.5 is released, you want to test it**
```
PHP Version: 8.5
Build Scope: all
→ Builds complete stack, verifies PHP 8.5 in all images
```

**Scenario 2: You fixed an issue in php-fpm only**
```
PHP Version: 8.4
Build Scope: php-fpm-only
→ Quick rebuild of just php-fpm (faster, ~30 min)
```

**Scenario 3: You want to backtest old PHP 8.2 with latest patches**
```
PHP Version: 8.2
Build Scope: all
→ Pulls latest PHP 8.2 patch and rebuilds everything
```

---

## Workflow Details

### Build Process

Each rebuild:
1. Checks out code from branch
2. Creates `.env.docker` from `.env.example`
3. Runs `docker compose build --no-cache <service>`
4. Verifies PHP version matches requested version
5. Checks core extensions are installed
6. Verifies Composer (for workspace)
7. Cleans up after tests

### Timeouts
- Full build (all services): **120 minutes**
- Single service (php-fpm/workspace): **60 minutes**
- Tests: **15 minutes**

### Logs
View build output in GitHub Actions UI:
```
Actions → Rebuild Images → [Run name] → [Job name] → Build step
```

---

## What Gets Built

### Services Built Per Version
- **workspace** — PHP CLI, Composer, dev tools (optional: Node, npm, yarn, etc.)
- **php-fpm** — Application runtime
- **php-worker** — Background job processor
- **nginx** — Web server
- **mariadb** — Database
- **redis** — Cache store
- Other services — beanstalkd, phpmyadmin, etc.

### What NOT Built
- Docker-in-Docker (`docker-in-docker`) — deferred service, requires extra setup
- Anything explicitly disabled in `.env.docker`

---

## Integration with Your Development

### Local Testing
After a successful GitHub Actions run, the workflow logs show:
- PHP version confirmed
- Extensions verified
- Test results

Example output:
```
✓ PHP 8.4.26 confirmed
✓ Extensions: gd, pdo_mysql, pdo_pgsql, zip, intl
✓ Composer: 2.10.3
✓ All checks passed!
```

### Pushing to Registry (Not Yet Configured)

Current setup builds locally but **does not push** to Docker Hub or GitHub Container Registry.

To add registry push capability:
1. Add Docker Hub credentials to GitHub Secrets
2. Uncomment push steps in workflow (when ready)
3. Example: `ghcr.io/your-org/ivpldock-php-fpm:8.4`

---

## Troubleshooting

### Build Fails on PHP 8.5
**Reason:** PHP 8.5 might not be released yet or Docker Hub hasn't published it.

**Solution:** Check [hub.docker.com/_/php](https://hub.docker.com/_/php/tags) for available tags. Use the highest available version.

### Optional Extensions Missing (Node, Yarn, etc.)
**Reason:** Disabled in `.env.docker` to streamline base build.

**Solution:** Edit `.env.docker` before pushing, or modify the build script to enable them.

### Build Takes > 2 Hours
**Reason:** Full rebuild (all services) can be resource-intensive on shared runners.

**Solution:** Use `php-fpm-only` or `workspace-only` scope to rebuild individual images.

---

## Future Enhancements

Possible additions:
1. **Docker Hub Push** — Auto-publish built images to registry
2. **Scheduled Builds** — Weekly rebuilds to catch latest patches
3. **SBOM Generation** — Security software bill of materials
4. **Registry Matrix** — Push to multiple registries (Docker Hub + GHCR)
5. **ARM64 Support** — Build for arm64 (M1 Mac, etc.)

---

## Quick Reference

### One-Liner: Rebuild PHP 8.4
```bash
# Via GitHub UI:
Actions → "Rebuild Images for Specific PHP Version" → 
  PHP 8.4 → all → Run
```

### View All Builds
```
GitHub repo → Actions tab → View all workflow runs
```

### Check Image Status Locally
```bash
# After pulling latest code:
cd ivpldock
docker compose --env-file .env.docker build --no-cache php-fpm
docker compose --env-file .env.docker exec php-fpm php -v
```
