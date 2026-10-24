#!/bin/bash
#
# Check PHP versions and extensions in ivpldock containers
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ivpldock PHP Version Check ===${NC}\n"

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo -e "${YELLOW}⚠ .env.docker not found. Using .env.example as fallback.${NC}"
    ENV_FILE=".env.example"
else
    ENV_FILE=".env.docker"
fi

# Function to check a container
check_container() {
    local service=$1
    local label=$2

    echo -e "${BLUE}▶ $label${NC}"

    # Check if container is running
    if ! docker compose --env-file "$ENV_FILE" ps "$service" 2>/dev/null | grep -q "Up"; then
        echo -e "${YELLOW}  ⚠ Container not running. Starting...${NC}"
        docker compose --env-file "$ENV_FILE" up -d "$service" > /dev/null 2>&1
        sleep 2
    fi

    # Get PHP version
    docker compose --env-file "$ENV_FILE" exec -T "$service" php -v 2>/dev/null | head -1
    echo ""
}

# Function to check extensions
check_extensions() {
    local service=$1
    local label=$2

    echo -e "${BLUE}▶ $label (Core Extensions)${NC}"
    docker compose --env-file "$ENV_FILE" exec -T "$service" php -m 2>/dev/null | \
        grep -E "gd|pdo|zip|intl|xml|curl|json" || echo "  (No core extensions found)"
    echo ""
}

# Check each PHP service
check_container "php-fpm" "PHP-FPM"
check_extensions "php-fpm" "PHP-FPM"

check_container "workspace" "Workspace (CLI)"
check_extensions "workspace" "Workspace (CLI)"

if docker compose --env-file "$ENV_FILE" config --services 2>/dev/null | grep -q "php-worker"; then
    check_container "php-worker" "PHP-Worker"
    check_extensions "php-worker" "PHP-Worker"
fi

# Summary
echo -e "${GREEN}✓ PHP version check complete${NC}"
