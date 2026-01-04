#!/bin/bash
# InvoicePlane PHP-FPM Container Banner

# Colors
BLUE='\033[38;2;66;154;225m'  # #429AE1
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

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  PHP-FPM Container - InvoicePlane Environment     ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}  PHP Version: ${GREEN}$(php -v | head -n1 | cut -d' ' -f2)${NC}                          ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
