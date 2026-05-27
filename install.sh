#!/usr/bin/env bash
# WireGuard Pro — Bootstrap Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/FarooqiEarning/wireguard-pro/main/install.sh | sudo bash

set -e

REPO="FarooqiEarning/wireguard-pro"
SCRIPT="wireguard-pro.sh"
RAW_URL="https://raw.githubusercontent.com/${REPO}/main/${SCRIPT}"
DEST="/usr/local/bin/${SCRIPT}"

# Colors
B='\033[1m' C='\033[0;36m' G='\033[0;32m' R='\033[0;31m' RST='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${R}Run as root: sudo bash install.sh${RST}"; exit 1; }

echo -e "\n${C}${B}WireGuard Pro — Installing...${RST}\n"

# Check dependencies
for cmd in curl bash; do
  command -v "$cmd" &>/dev/null || { echo -e "${R}Missing: ${cmd}${RST}"; exit 1; }
done

[[ ${BASH_VERSINFO[0]} -lt 4 ]] && { echo -e "${R}Bash 4.0+ required${RST}"; exit 1; }

# Download
echo -e "  ${C}Downloading from GitHub...${RST}"
if curl -fsSL --progress-bar "$RAW_URL" -o "$DEST"; then
  chmod +x "$DEST"
  echo -e "  ${G}✔  Saved to ${DEST}${RST}\n"
else
  echo -e "  ${R}Download failed. Check your internet connection.${RST}"
  exit 1
fi

# Run
echo -e "  ${C}Starting WireGuard Pro...${RST}\n"
exec bash "$DEST" "$@"
