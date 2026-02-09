<![CDATA[<div align="center">

# 🤖 OpenClaw VPS Setup

**Deploy your personal AI assistant to a VPS in under 5 minutes.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%2FDebian-orange.svg)]()
[![Telegram](https://img.shields.io/badge/channel-Telegram-26A5E4.svg?logo=telegram)](https://telegram.org)
[![Node.js](https://img.shields.io/badge/node-%3E%3D22-brightgreen.svg?logo=node.js)](https://nodejs.org)

[Quick Start](#-quick-start) · [Manual Setup](#-manual-setup) · [Commands](#-useful-commands) · [Uninstall](#-uninstall) · [Troubleshooting](#-troubleshooting)

</div>

---

## What is OpenClaw?

OpenClaw is a personal AI assistant that lives on your server and talks to you via Telegram. It runs 24/7, remembers context across conversations, and can execute tasks on your behalf.

## 📋 Prerequisites

| What | Where to get it | Cost |
|------|----------------|------|
| **VPS** (Ubuntu 22.04+) | [DigitalOcean](https://digitalocean.com) / [Hetzner](https://hetzner.com/cloud) | ~$4–6/mo |
| **Anthropic API key** | [console.anthropic.com](https://console.anthropic.com/settings/keys) | Pay-per-use |
| **Telegram bot token** | [@BotFather](https://t.me/BotFather) on Telegram | Free |

## ⚡ Quick Start

SSH into your VPS and run:

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/vps-setup/main/setup.sh | bash
```

That's it. The script will:
1. Install Node.js 22 (if needed)
2. Install OpenClaw (`openclaw` CLI)
3. Walk you through configuration (API key, Telegram token, bot name)
4. Start the gateway as a systemd service
5. Verify everything is running

## 🔧 Manual Setup

<details>
<summary><strong>Step 1: Create Your VPS</strong></summary>

### DigitalOcean (recommended for beginners)
1. Sign up at [digitalocean.com](https://digitalocean.com)
2. **Create → Droplet** → Ubuntu 24.04, $6/mo (1 GB RAM)
3. Pick a datacenter near you, set a password
4. Copy the **IP address**

### Hetzner (cheapest)
1. Sign up at [hetzner.com/cloud](https://www.hetzner.com/cloud)
2. Create server → Ubuntu 24.04, CX22 (~€4/mo)
3. Set a password, copy the **IP address**
</details>

<details>
<summary><strong>Step 2: Connect via SSH</strong></summary>

```bash
ssh root@YOUR_IP_ADDRESS
```

Type `yes` when prompted, then enter your password.
</details>

<details>
<summary><strong>Step 3: Create a Telegram Bot</strong></summary>

1. Open Telegram → search **@BotFather**
2. Send `/newbot`
3. Pick a display name (e.g., "My AI Assistant")
4. Pick a username (must end in `bot`, e.g., `myname_aibot`)
5. **Save the token** — you'll need it during setup
</details>

<details>
<summary><strong>Step 4: Run Setup</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/vps-setup/main/setup.sh | bash
```

The script will prompt for your Anthropic API key, Telegram token, bot name, and your name.
</details>

<details>
<summary><strong>Step 5: Talk to Your Bot</strong></summary>

1. Open Telegram → search for your bot's username
2. Send it a message
3. First message triggers pairing — follow the on-screen instructions
</details>

## 📸 Screenshots

<!-- Add screenshots here -->
<!-- ![Setup](screenshots/setup.png) -->
<!-- ![Chat](screenshots/chat.png) -->

## 🛠 Useful Commands

```bash
openclaw status              # Check if everything is running
openclaw gateway start       # Start the bot
openclaw gateway stop        # Stop the bot
openclaw gateway restart     # Restart the bot
openclaw health              # Detailed health check
```

**Systemd service management:**

```bash
sudo systemctl status openclaw-gateway
sudo systemctl restart openclaw-gateway
sudo journalctl -u openclaw-gateway -f   # Live logs
```

## 🗑 Uninstall

To completely remove OpenClaw from your server:

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/vps-setup/main/uninstall.sh | bash
```

Or run locally:

```bash
./uninstall.sh
```

## 🔍 Troubleshooting

<details>
<summary><strong>Bot doesn't respond</strong></summary>

```bash
openclaw status          # Is the gateway running?
openclaw health          # Are credentials valid?
sudo journalctl -u openclaw-gateway --since "5 min ago"  # Recent logs
```
</details>

<details>
<summary><strong>"Pairing code" message on first contact</strong></summary>

This is expected. Approve it:
```bash
openclaw pairing list telegram
openclaw pairing approve telegram <code>
```
</details>

<details>
<summary><strong>Need to start over</strong></summary>

```bash
./uninstall.sh           # Clean removal
./setup.sh               # Re-run setup
```
</details>

## 💰 Cost

| Service | Cost |
|---------|------|
| VPS | ~$4–6/month |
| Anthropic API | Pay-per-use (~$2–5/mo for light use) |
| Telegram | Free |

## 📄 License

MIT © [OpenClaw](https://github.com/openclaw)
]]>