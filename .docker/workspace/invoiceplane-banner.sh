#!/bin/bash
# InvoicePlane ASCII Art Logo and Banner
# This file is sourced by container bash profiles

# Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# InvoicePlane ASCII Logo
cat << 'EOF'
    ____                  _          ____  __                
   /  _/___ _   ______  (_)_______ / __ \/ /___ _____  ___  
   / // __ \ | / / __ \/ / ___/ _ / /_/ / / __ `/ __ \/ _ \ 
 _/ // / / / |/ / /_/ / / /__/  __/ ____/ / /_/ / / / /  __/ 
/___/_/ /_/|___/\____/_/\___/\___/_/   /_/\__,_/_/ /_/\___/  
                                                              
EOF

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  Welcome to InvoicePlane Docker Environment               ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  Container: ${GREEN}$(hostname)${NC}                                    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  User: ${YELLOW}$(whoami)${NC}                                           ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo -e "  ${GREEN}php -v${NC}        - Check PHP version"
echo -e "  ${GREEN}composer${NC}      - Run Composer"
echo -e "  ${GREEN}cd /var/www/projects${NC} - Go to projects directory"
echo ""
