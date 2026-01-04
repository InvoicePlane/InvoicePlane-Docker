#!/bin/bash
set -euo pipefail

# Helper script to run commands inside Docker containers from the command line
# Usage: ./docker-exec.sh <container_name> <project_directory> <command>
# Example: ./docker-exec.sh workspace myproject "composer install"
# Example: ./docker-exec.sh php-fpm invoiceplane "php artisan migrate --force"

show_usage() {
    echo "Usage: $0 <container_name> <project_directory> <command>"
    echo ""
    echo "Available containers:"
    echo "  - workspace  : Main workspace container"
    echo "  - php-fpm    : PHP-FPM container"
    echo "  - php-worker : PHP worker container"
    echo "  - nginx      : Nginx web server"
    echo "  - mariadb    : MariaDB database"
    echo ""
    echo "Examples:"
    echo "  $0 workspace myproject 'composer install'"
    echo "  $0 php-fpm invoiceplane 'php artisan migrate --force'"
    echo "  $0 workspace myapp 'npm run build'"
    echo "  $0 workspace myproject 'php artisan test --filter=UserTest'"
    echo ""
    exit 1
}

# Check arguments
if [ $# -lt 3 ]; then
    echo "Error: Missing required arguments!"
    echo ""
    show_usage
fi

CONTAINER_NAME="$1"
PROJECT_DIR="$2"
COMMAND="$3"

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    echo "Please create it from .env.example: cp .env.example .env.docker"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker ps -aqf "name=${CONTAINER_NAME}")

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Container '${CONTAINER_NAME}' is not running!"
    echo "Start it with: ./startmeup.sh or ./buildmeup.sh"
    echo ""
    echo "Available running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

# Check if project directory exists in container
if ! docker exec "$CONTAINER_ID" test -d "/var/www/projects/${PROJECT_DIR}"; then
    echo "Warning: Project directory '/var/www/projects/${PROJECT_DIR}' does not exist in container!"
    echo "Available projects in /var/www/projects:"
    docker exec "$CONTAINER_ID" ls -1 /var/www/projects/ 2>/dev/null || echo "  (directory is empty or not accessible)"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Running command in ${CONTAINER_NAME} container..."
echo "Project: /var/www/projects/${PROJECT_DIR}"
echo "Command: ${COMMAND}"
echo "----------------------------------------"

# Execute the command in the container
docker exec -it "$CONTAINER_ID" bash -c "cd /var/www/projects/${PROJECT_DIR} && ${COMMAND}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "----------------------------------------"
    echo "Command completed successfully."
else
    echo "----------------------------------------"
    echo "Command failed with exit code: $EXIT_CODE"
    exit $EXIT_CODE
fi
