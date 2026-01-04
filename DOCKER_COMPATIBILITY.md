# Docker Container Compatibility Check

This document tracks potential incompatibilities found across all Docker containers.

## Summary

All Dockerfiles have been reviewed for potential cross-platform compatibility issues similar to the php-zip installation problem on Mac.

## Findings by Container

### ✅ workspace (Fixed)
**Issue:** `php${IVPLDOCK_PHP_VERSION}-zip` package not available on Mac
**Status:** FIXED with PECL fallback
**Location:** `.docker/workspace/Dockerfile:76-81`

**Potential Similar Issues:**
The workspace Dockerfile uses several version-specific PHP packages that might not be available on all platforms:
- Line 222: `php${IVPLDOCK_PHP_VERSION}-bz2`
- Line 229: `php${IVPLDOCK_PHP_VERSION}-gmp`
- Line 235: `php${IVPLDOCK_PHP_VERSION}-gnupg`
- Line 242: `php${IVPLDOCK_PHP_VERSION}-ssh2`
- Line 249: `php${IVPLDOCK_PHP_VERSION}-soap`
- Line 256: `php${IVPLDOCK_PHP_VERSION}-xsl`
- Line 271: `php${IVPLDOCK_PHP_VERSION}-imap`
- Line 287: `php${IVPLDOCK_PHP_VERSION}-xml`
- Line 333: `php${IVPLDOCK_PHP_VERSION}-redis`

**Recommendation:** These are conditional installs (only when INSTALL_* flags are true), so they are lower priority. If issues arise, similar PECL fallbacks can be implemented.

### ✅ php-fpm
**Status:** NO ISSUES FOUND
**Reason:** Uses `docker-php-ext-install` and `docker-php-ext-configure` commands which are the standard, cross-platform way to install PHP extensions in official PHP Docker images.
**Location:** `.docker/php-fpm/Dockerfile`

### ✅ php-worker
**Status:** NO ISSUES FOUND
**Reason:** Uses `docker-php-ext-install` and `docker-php-ext-configure` commands for extension management.
**Location:** `.docker/php-worker/Dockerfile`

### ✅ laravel-horizon
**Status:** NO ISSUES FOUND
**Reason:** Uses `docker-php-ext-install` and `docker-php-ext-configure` commands.
**Location:** `.docker/laravel-horizon/Dockerfile`

### ✅ nginx
**Status:** NO ISSUES FOUND
**Reason:** Standard nginx image, no custom PHP compilation.
**Location:** `.docker/nginx/Dockerfile`

### ✅ mariadb
**Status:** NO ISSUES FOUND
**Reason:** Standard MariaDB image, no custom compilation.
**Location:** `.docker/mariadb/Dockerfile`

### ✅ redis
**Status:** NO ISSUES FOUND
**Reason:** Standard Redis image.
**Location:** `.docker/redis/Dockerfile`

### ✅ beanstalkd
**Status:** NO ISSUES FOUND
**Reason:** Standard beanstalkd image.
**Location:** `.docker/beanstalkd/Dockerfile`

### ✅ beanstalkd-console
**Status:** NO ISSUES FOUND
**Reason:** Simple PHP application, no complex dependencies.
**Location:** `.docker/beanstalkd-console/Dockerfile`

### ✅ phpmyadmin
**Status:** NO ISSUES FOUND
**Reason:** Official phpMyAdmin image.
**Location:** `.docker/phpmyadmin/Dockerfile`

## Testing Coverage

### Automated CI/CD Testing
All containers are now tested individually in CI/CD:
- `docker-build-test.yml` - Tests workspace, php-fpm, php-worker together
- `test-individual-containers.yml` - Tests each container separately with detailed checks

### Manual Testing Recommendations
1. Test on both Mac (ARM64 and Intel) and Linux platforms
2. Test with PHP versions 8.2, 8.3, and 8.4
3. Test with various optional extensions enabled

## Future Improvements

If issues arise with conditional PHP extensions in workspace:
1. Implement PECL fallbacks similar to the zip extension fix
2. Add specific CI tests for optional extensions
3. Document known platform limitations

## Conclusion

The critical issue (php-zip on Mac) has been fixed. Other containers use standard, cross-platform methods. The workspace container has potential similar issues with optional extensions, but these are rarely used and can be addressed if problems occur.
