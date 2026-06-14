# GitHub Copilot Instructions for InvoicePlane-Docker

## Project Context

This repository provides a Docker-based development environment for InvoicePlane, forked from Laradock. The primary goal is to maintain a stable, performant, and easy-to-use containerized environment for InvoicePlane development.

## Core Principles

### 1. Minimalism
- Make the smallest possible changes to achieve the goal
- Avoid unnecessary refactoring or feature additions
- Keep configurations simple and maintainable

### 2. Compatibility
- Support PHP versions: 7.4, 8.0, 8.1, 8.2, 8.3, 8.4
- Maintain backward compatibility with existing configurations
- Test changes across all supported PHP versions

### 3. Documentation
- Document all configuration changes
- Update README.md for user-facing changes
- Add inline comments for complex Dockerfile logic

## Code Style Guidelines

### Dockerfile Best Practices

```dockerfile
# Good: Clear section headers and comments
###########################################################################
# Redis Extension:
###########################################################################

ARG INSTALL_REDIS=false
RUN if [ ${INSTALL_REDIS} = true ]; then \
    # Install Redis extension for PHP
    pecl install redis && \
    docker-php-ext-enable redis \
;fi

# Bad: No comments, unclear purpose
ARG INSTALL_REDIS=false
RUN if [ ${INSTALL_REDIS} = true ]; then \
    pecl install redis && \
    docker-php-ext-enable redis \
;fi
```

### Shell Scripts

```bash
# Good: Error handling and validation
#!/bin/bash
set -euo pipefail

if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    exit 1
fi

# Bad: No error handling
#!/bin/bash
docker-compose up -d
```

### Environment Variables

```bash
# Good: Descriptive names with sensible defaults
WORKSPACE_INSTALL_XDEBUG=true
WORKSPACE_XDEBUG_PORT=9003
PHP_VERSION=8.1

# Bad: Unclear names or no defaults
XDBG=true
PORT=9003
VER=8.1
```

## Common Tasks

### Adding a New PHP Extension

1. **Update Dockerfile** (e.g., `.docker/php-fpm/Dockerfile`):
   ```dockerfile
   ###########################################################################
   # Extension Name:
   ###########################################################################
   
   ARG INSTALL_EXTENSION=false
   
   RUN if [ ${INSTALL_EXTENSION} = true ]; then \
       # Install dependencies if needed
       apt-get install -yqq lib-dependency && \
       # Install extension
       pecl install extension-name && \
       docker-php-ext-enable extension-name \
   ;fi
   ```

2. **Update docker-compose.yml**:
   ```yaml
   php-fpm:
     build:
       args:
         - INSTALL_EXTENSION=${PHP_FPM_INSTALL_EXTENSION}
   ```

3. **Update .env.example**:
   ```bash
   ### PHP-FPM ##############################################
   PHP_FPM_INSTALL_EXTENSION=false
   ```

4. **Test across PHP versions**:
   ```bash
   # Test with different PHP versions
   sed -i 's/PHP_VERSION=8.1/PHP_VERSION=8.2/' .env.docker
   docker compose --env-file .env.docker build php-fpm
   ```

### Modifying Xdebug Configuration

- **Always use trigger mode** to prevent build-time warnings
- **Never use autostart** for Xdebug 3 or remote_autostart=1 for Xdebug 2
- **Document trigger methods** in README and inline comments

Example:
```dockerfile
# Configure Xdebug settings based on PHP version
# For Xdebug 3 (PHP 7.3+, 7.4, 8.x): Use trigger mode to prevent connection warnings during build
# For Xdebug 2 (older PHP): Keep autostart disabled to prevent connection warnings during build
RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
  sed -i "s/xdebug.remote_autostart=0/xdebug.start_with_request=trigger/" /usr/local/etc/php/conf.d/xdebug.ini \
;fi
```

### Adding New Services

1. Create Dockerfile in `.docker/<service-name>/`
2. Add service to `docker-compose.yml`
3. Add configuration options to `.env.example`
4. Document in README.md
5. Add to CI/CD if appropriate

## Testing Requirements

### Before Committing

1. **Build test**:
   ```bash
   docker compose --env-file .env.docker build <service>
   ```

2. **Start test**:
   ```bash
   docker compose --env-file .env.docker up -d <service>
   docker compose --env-file .env.docker ps
   ```

3. **Functionality test**:
   ```bash
   docker compose --env-file .env.docker exec <service> php -v
   docker compose --env-file .env.docker exec <service> php -m | grep <extension>
   ```

### CI/CD Integration

- All changes trigger GitHub Actions workflows
- Tests run for PHP 8.2, 8.3, 8.4
- Ensure builds pass before merging

## Security Considerations

### Xdebug in Production

- Xdebug should NEVER be enabled in production
- Always use trigger mode, never autostart
- Document security implications

### Secrets Management

- Never commit `.env.docker` files - this is a local configuration file that may contain sensitive data
- Add `.env.docker` to `.gitignore` to prevent accidental commits
- Use `.env.example` as the committed template for users to copy and modify
- Use environment variables for sensitive data
- Document required secrets in `.env.example`

### Container Security

- Run as non-root user where possible
- Keep base images updated
- Minimize installed packages

## Performance Optimization

### Docker Layer Caching

Order Dockerfile commands from least to most frequently changing:

```dockerfile
# Good: Stable commands first
RUN apt-get update && apt-get install -yqq stable-package
COPY rarely-changed-file /dest/
RUN frequently-changing-command
COPY frequently-changed-file /dest/

# Bad: Frequent changes invalidate cache for everything below
COPY frequently-changed-file /dest/
RUN apt-get update && apt-get install -yqq stable-package
```

### Build Arguments

- Use build arguments for configurability
- Cache builds with different argument values
- Document all build arguments

## Documentation Standards

### README Updates

When changing functionality, update README.md:

1. **Quick Start** - If setup process changes
2. **Configuration** - If new env vars added
3. **Troubleshooting** - If new issues arise
4. **Examples** - If new features added

### Inline Comments

Use comments for:
- Complex conditional logic
- Version-specific workarounds
- Security considerations
- Performance optimizations

```dockerfile
# Good: Explains why
RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
  # PHP 5 requires older version of extension
  pecl install extension-2.0.0; \
else \
  pecl install extension; \
fi

# Bad: States obvious
RUN pecl install extension  # Install extension
```

## Common Pitfalls to Avoid

### 1. Breaking Changes
- Don't change default values without considering existing users
- Maintain backward compatibility
- Version breaking changes appropriately

### 2. Build-Time Warnings
- Always test builds completely
- Address all warnings, especially Xdebug connection warnings
- Clean build output is important

### 3. Cross-Platform Issues
- Test on Linux, macOS, and Windows when possible
- Use cross-platform path separators
- Document platform-specific considerations

### 4. Version Compatibility
- Don't assume latest PHP version features
- Support the full range of declared PHP versions
- Test edge cases (oldest and newest versions)

## Git Workflow

### Commit Messages

Format: `<type>: <short description>`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

Examples:
```
fix: Resolve Xdebug connection warnings during build
docs: Add Xdebug trigger mode documentation
feat: Add Redis container support
```

### Pull Request Template

1. **Title**: Clear, descriptive
2. **Description**: Explain the change and why
3. **Testing**: Describe testing performed
4. **Breaking Changes**: List any breaking changes
5. **Screenshots**: For UI/output changes

## AI Assistance Best Practices

When using GitHub Copilot or similar tools:

1. **Review all suggestions** - Don't blindly accept
2. **Understand the code** - Know what you're committing
3. **Test thoroughly** - AI can miss edge cases
4. **Document decisions** - Explain non-obvious choices
5. **Security first** - Verify security implications

## Resources

- [Laradock Documentation](https://laradock.io)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [PHP Docker Images](https://hub.docker.com/_/php)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)

## Support Channels

- GitHub Issues: Bug reports and feature requests
- GitHub Discussions: Questions and community support
- Pull Requests: Code contributions

---

**Last Updated**: 2025-01-05  
**Maintainer**: InvoicePlane Team
