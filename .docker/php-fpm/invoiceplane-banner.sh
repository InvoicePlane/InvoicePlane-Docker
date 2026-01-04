#!/bin/bash
# InvoicePlane PHP-FPM Container Banner

# Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# InvoicePlane ASCII Logo (compact version for PHP-FPM)
cat << 'EOF'
   ____                  _          ____  __                
  /  _/___ _  ______  (_)_______ / __ \/ /___ _____  ___  
  / // __ `/ | / / __ \/ / ___/ _ / /_/ / / __ `/ __ \/ _ \ 
_/ // / / / |/ / /_/ / / /__/  __/ ____/ / /_/ / / / /  __/ 
/___/_/ /_/|___/\____/_/\___/\___/_/   /_/\__,_/_/ /_/\___/  
EOF

echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  PHP-FPM Container - InvoicePlane Environment     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  PHP Version: ${GREEN}$(php -v | head -n1 | cut -d' ' -f2)${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
