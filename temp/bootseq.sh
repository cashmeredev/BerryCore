#!/bin/bash
# Boot Sequence Simulator

G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
W='\033[1;37m'; N='\033[0m'

boot_msg() {
    echo -ne "${G}[ ${W}OK${G} ]${N} $1"
    sleep 0.1
    echo -e " ${C}done${N}"
}

clear
echo -e "${W}"
echo "╔════════════════════════════════════════════╗"
echo "║   BERRYCORE PORSCHE EDITION BOOT v0.72    ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${N}"
sleep 0.5

boot_msg "Loading quantum kernel modules..."
boot_msg "Initializing crypto subsystem..."
boot_msg "Mounting /dev/berrycore..."
boot_msg "Starting BerryCore daemon..."
boot_msg "Loading 58 tactical packages..."
boot_msg "Initializing network stack..."
boot_msg "Starting shell environment..."
boot_msg "Enabling turbo mode..."
boot_msg "Loading Porsche Edition theme..."
echo ""
sleep 0.3

echo -e "${G}[✓✓✓] SYSTEM READY [✓✓✓]${N}"
echo ""
echo -e "${C}Welcome to BerryCore ${W}Porsche Edition${N}"
echo -e "${C}Type ${Y}qpkg catalog${C} to explore tools${N}"
echo ""

