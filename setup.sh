#!/usr/bin/env bash
# ============================================================
# OpenClaw VPS Quick Setup
# One script to go from fresh Ubuntu server → working AI assistant
# ============================================================
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║       🤖 OpenClaw Quick Setup          ║"
  echo "  ╚═══════════════════════════════════════╝"
  echo -e "${NC}"
  echo ""
}

step() {
  echo ""
  echo -e "${GREEN}${BOLD}▸ $1${NC}"
}

warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

fail() {
  echo -e "${RED}✖ $1${NC}"
  exit 1
}

prompt() {
  local var_name="$1"
  local message="$2"
  local secret="${3:-false}"
  
  echo ""
  echo -e "${BOLD}$message${NC}"
  if [ "$secret" = "true" ]; then
    read -rs input
    echo ""
  else
    read -r input
  fi
  
  if [ -z "$input" ]; then
    fail "This field is required. Please re-run the script."
  fi
  
  eval "$var_name='$input'"
}

# ============================================================
banner

echo "This script will:"
echo "  1. Install Node.js 22 (if needed)"
echo "  2. Install OpenClaw"
echo "  3. Set up your Telegram bot"
echo "  4. Start the gateway as a background service"
echo "  5. Verify everything is working"
echo ""
echo "You'll need:"
echo "  • An Anthropic API key (from console.anthropic.com)"
echo "  • A Telegram bot token (from @BotFather)"
echo ""
read -rp "Ready? (y/n) " confirm
[[ "$confirm" =~ ^[Yy] ]] || exit 0

# ============================================================
step "Step 1/6: Checking system..."

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
else
  OS_ID="unknown"
fi

if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
  warn "This script is tested on Ubuntu/Debian. You're on: $OS_ID"
  read -rp "Continue anyway? (y/n) " cont
  [[ "$cont" =~ ^[Yy] ]] || exit 0
fi

# Check if root
if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# ============================================================
step "Step 2/6: Installing Node.js 22..."

if command -v node &>/dev/null; then
  NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_VER" -ge 22 ]; then
    echo "  ✓ Node.js $(node -v) already installed"
  else
    warn "Node.js $(node -v) found but v22+ is required. Installing..."
    INSTALL_NODE=true
  fi
else
  INSTALL_NODE=true
fi

if [ "${INSTALL_NODE:-false}" = "true" ]; then
  echo "  Installing Node.js 22 via NodeSource..."
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq curl ca-certificates gnupg
  
  # NodeSource setup
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | $SUDO tee /etc/apt/sources.list.d/nodesource.list >/dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq nodejs
  
  echo "  ✓ Node.js $(node -v) installed"
fi

# ============================================================
step "Step 3/6: Installing OpenClaw..."

if command -v openclaw &>/dev/null; then
  echo "  ✓ OpenClaw already installed, updating..."
  npm install -g openclaw@latest 2>/dev/null || $SUDO npm install -g openclaw@latest
else
  echo "  Installing OpenClaw globally..."
  npm install -g openclaw@latest 2>/dev/null || $SUDO npm install -g openclaw@latest
fi

echo "  ✓ OpenClaw $(openclaw --version 2>/dev/null || echo 'installed')"

# ============================================================
step "Step 4/6: Configuration"

echo ""
echo -e "${CYAN}═══ Anthropic API Key ═══${NC}"
echo "Get one at: https://console.anthropic.com/settings/keys"
echo "It looks like: sk-ant-api03-..."
prompt ANTHROPIC_KEY "Paste your Anthropic API key:" true

echo ""
echo -e "${CYAN}═══ Telegram Bot Setup ═══${NC}"
echo "1. Open Telegram and search for @BotFather"
echo "2. Send /newbot"
echo "3. Pick a name (e.g. 'My Clawdbot')"
echo "4. Pick a username (must end in 'bot', e.g. 'myname_clawdbot')"
echo "5. Copy the token BotFather gives you"
echo ""
prompt TELEGRAM_TOKEN "Paste your Telegram bot token:" true

echo ""
echo -e "${CYAN}═══ Bot Name ═══${NC}"
prompt BOT_NAME "What should your bot be called? (e.g. Tobbot):"

echo ""
echo -e "${CYAN}═══ Your Name ═══${NC}"
prompt USER_NAME "What's your name?:"

# ============================================================
step "Step 5/6: Setting everything up..."

# Create workspace
WORKSPACE="$HOME/clawd"
mkdir -p "$WORKSPACE/memory"

# Write workspace files
cat > "$WORKSPACE/AGENTS.md" << 'AGENTS_EOF'
# AGENTS.md
Read SOUL.md, USER.md, and today's memory file at the start of each session.
AGENTS_EOF

cat > "$WORKSPACE/IDENTITY.md" << EOF
# IDENTITY.md
- **Name:** $BOT_NAME
- **Creature:** AI assistant
- **Emoji:** 🤖
EOF

cat > "$WORKSPACE/USER.md" << EOF
# USER.md
- **Name:** $USER_NAME
- **What to call them:** $USER_NAME
EOF

cat > "$WORKSPACE/SOUL.md" << 'SOUL_EOF'
# SOUL.md
Be helpful, be direct, have personality. Skip the filler words.
Have opinions. Be resourceful — try to figure things out before asking.
SOUL_EOF

# Write OpenClaw config
CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/config.yaml" << EOF
gateway:
  port: 18789

providers:
  anthropic:
    apiKey: "$ANTHROPIC_KEY"

channels:
  telegram:
    enabled: true
    token: "$TELEGRAM_TOKEN"

routing:
  agents:
    main:
      workspace: "$WORKSPACE"

tools:
  exec:
    enabled: true
EOF

echo "  ✓ Config written"

# Install and start the daemon
echo "  Starting OpenClaw gateway..."
openclaw gateway install 2>/dev/null || true
openclaw gateway start 2>/dev/null || true

# ============================================================
step "Step 6/6: Verifying installation..."

sleep 3

VERIFY_OK=true

# Check CLI is available
if command -v openclaw &>/dev/null; then
  echo "  ✓ OpenClaw CLI found: $(openclaw --version 2>/dev/null || echo 'ok')"
else
  echo -e "  ${RED}✖ OpenClaw CLI not found in PATH${NC}"
  VERIFY_OK=false
fi

# Check config exists
if [ -f "$CONFIG_DIR/config.yaml" ]; then
  echo "  ✓ Config file exists"
else
  echo -e "  ${RED}✖ Config file missing${NC}"
  VERIFY_OK=false
fi

# Check gateway is running
if openclaw gateway status &>/dev/null; then
  echo "  ✓ Gateway is running"
else
  echo -e "  ${YELLOW}⚠ Gateway may not be running — check: openclaw gateway status${NC}"
  VERIFY_OK=false
fi

# Check workspace
if [ -d "$WORKSPACE" ] && [ -f "$WORKSPACE/SOUL.md" ]; then
  echo "  ✓ Workspace initialized"
else
  echo -e "  ${RED}✖ Workspace not set up correctly${NC}"
  VERIFY_OK=false
fi

echo ""
if [ "$VERIFY_OK" = true ]; then
  echo -e "${GREEN}${BOLD}"
  echo "  ╔═══════════════════════════════════════════════════╗"
  echo "  ║           ✅ Setup Complete & Verified!           ║"
  echo "  ╠═══════════════════════════════════════════════════╣"
  echo "  ║                                                   ║"
  echo "  ║  Your bot '$BOT_NAME' is now running!             ║"
  echo "  ║                                                   ║"
  echo "  ║  Next steps:                                      ║"
  echo "  ║  1. Open Telegram                                 ║"
  echo "  ║  2. Search for your bot's username                ║"
  echo "  ║  3. Send it a message!                            ║"
  echo "  ║                                                   ║"
  echo "  ║  Useful commands:                                 ║"
  echo "  ║  • openclaw status        - Check status          ║"
  echo "  ║  • openclaw gateway stop  - Stop the bot          ║"
  echo "  ║  • openclaw gateway start - Start the bot         ║"
  echo "  ║                                                   ║"
  echo "  ╚═══════════════════════════════════════════════════╝"
  echo -e "${NC}"
else
  echo -e "${YELLOW}${BOLD}"
  echo "  ╔═══════════════════════════════════════════════════╗"
  echo "  ║       ⚠  Setup finished with warnings            ║"
  echo "  ║  Review the issues above and try:                 ║"
  echo "  ║    openclaw gateway restart                       ║"
  echo "  ╚═══════════════════════════════════════════════════╝"
  echo -e "${NC}"
fi
