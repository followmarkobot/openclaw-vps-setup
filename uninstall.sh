#!/usr/bin/env bash
# ============================================================
# OpenClaw VPS Uninstaller
# Cleanly removes OpenClaw from your server
# ============================================================
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║     🗑  OpenClaw Uninstaller          ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"
echo ""

echo "This will remove:"
echo "  • OpenClaw gateway service"
echo "  • OpenClaw CLI (npm global package)"
echo "  • Config directory (~/.openclaw)"
echo "  • Workspace directory (~/clawd)"
echo ""
echo -e "${YELLOW}⚠ Your workspace files (memory, notes) will be deleted!${NC}"
echo ""
read -rp "Are you sure? (y/n) " confirm
[[ "$confirm" =~ ^[Yy] ]] || { echo "Cancelled."; exit 0; }

echo ""
read -rp "Back up workspace to ~/clawd-backup first? (y/n) " backup
if [[ "$backup" =~ ^[Yy] ]]; then
  if [ -d "$HOME/clawd" ]; then
    cp -r "$HOME/clawd" "$HOME/clawd-backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓ Backup created${NC}"
  fi
fi

if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Stop and remove service
echo ""
echo -e "${BOLD}Stopping gateway...${NC}"
openclaw gateway stop 2>/dev/null || true
$SUDO systemctl stop openclaw-gateway 2>/dev/null || true
$SUDO systemctl disable openclaw-gateway 2>/dev/null || true
$SUDO rm -f /etc/systemd/system/openclaw-gateway.service
$SUDO systemctl daemon-reload 2>/dev/null || true
echo "  ✓ Service removed"

# Remove CLI
echo -e "${BOLD}Removing OpenClaw CLI...${NC}"
npm uninstall -g openclaw 2>/dev/null || $SUDO npm uninstall -g openclaw 2>/dev/null || true
echo "  ✓ CLI removed"

# Remove config and workspace
echo -e "${BOLD}Removing config and workspace...${NC}"
rm -rf "$HOME/.openclaw"
rm -rf "$HOME/clawd"
echo "  ✓ Files removed"

echo ""
echo -e "${GREEN}${BOLD}✅ OpenClaw has been completely removed.${NC}"
echo ""
echo "If you want to reinstall later:"
echo "  curl -fsSL https://raw.githubusercontent.com/openclaw/vps-setup/main/setup.sh | bash"
echo ""
