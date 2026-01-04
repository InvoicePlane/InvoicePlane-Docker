#!/bin/bash
# InvoicePlane Docker Container Banner
# Shared banner script for all InvoicePlane Docker containers
# Follows DRY, SOLID, and early return principles

# Early return if not in interactive shell
[[ $- != *i* ]] && return

# Color definitions - InvoicePlane brand colors
readonly IPBLUE='\033[38;2;66;154;225m'  # #429AE1 - InvoicePlane brand blue
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'  # No Color

# Helper function to display the InvoicePlane ASCII logo
show_logo() {
    cat << 'EOF'
    ____                  _          ____  __                
   /  _/___ _   ______  (_)_______ / __ \/ /___ _____  ___  
   / // __ \ | / / __ \/ / ___/ _ / /_/ / / __ `/ __ \/ _ \ 
 _/ // / / / |/ / /_/ / / /__/  __/ ____/ / /_/ / / / /  __/ 
/___/_/ /_/|___/\____/_/\___/\___/_/   /_/\__,_/_/ /_/\___/  
                                                              
EOF
}

# Helper function to display container info box
show_info_box() {
    local container_type="${1:-Unknown}"
    local user_name
    local host_name
    
    user_name=$(whoami 2>/dev/null || echo "unknown")
    host_name=$(hostname 2>/dev/null || echo "unknown")
    
    echo -e "${IPBLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${IPBLUE}║${NC}  ${container_type}${IPBLUE}║${NC}"
    echo -e "${IPBLUE}║${NC}  Container: ${GREEN}${host_name}${NC}  |  User: ${YELLOW}${user_name}${NC}  |  Dir: ${GREEN}\w${NC}${IPBLUE}║${NC}"
    echo -e "${IPBLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

# Helper function to show PHP version if available
show_php_version() {
    if command -v php >/dev/null 2>&1; then
        local php_version
        php_version=$(php -v 2>/dev/null | head -n1 | cut -d' ' -f2 || echo "unknown")
        echo -e "${IPBLUE}║${NC}  PHP Version: ${GREEN}${php_version}${NC}"
    fi
}

# Helper function to show quick commands
show_quick_commands() {
    echo ""
    echo -e "${IPBLUE}Quick Commands:${NC}"
    
    # Show PHP-related commands if PHP is available
    if command -v php >/dev/null 2>&1; then
        echo -e "  ${GREEN}php -v${NC}               - Check PHP version"
    fi
    
    # Show Composer if available
    if command -v composer >/dev/null 2>&1; then
        echo -e "  ${GREEN}composer${NC}             - Run Composer"
    fi
    
    # Show common directories
    if [[ -d /var/www/projects ]]; then
        echo -e "  ${GREEN}cd /var/www/projects${NC} - Go to projects directory"
    fi
    
    echo ""
}

# Main banner display function
display_banner() {
    local container_type="${CONTAINER_TYPE:-InvoicePlane Docker Environment}"
    
    # Display logo
    show_logo
    
    # Display info box with PHP version if available
    echo -e "${IPBLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${IPBLUE}║${NC}  Welcome to ${container_type}  ${IPBLUE}║${NC}"
    show_php_version
    echo -e "${IPBLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    
    # Show additional info
    local user_name host_name pwd
    user_name=$(whoami 2>/dev/null || echo "unknown")
    host_name=$(hostname 2>/dev/null || echo "unknown")
    pwd=$(pwd 2>/dev/null || echo "~")
    
    echo -e "Container: ${GREEN}${host_name}${NC}  |  User: ${YELLOW}${user_name}${NC}  |  Dir: ${GREEN}${pwd}${NC}"
    
    # Display quick commands
    show_quick_commands
}

# Execute main function
display_banner
