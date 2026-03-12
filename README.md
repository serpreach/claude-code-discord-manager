# Claude Code Discord Manager

Run Claude Code as a Discord bot — powered entirely by your Max/Pro subscription. **Zero API costs.**

This bridge connects Discord to the `claude --print` CLI, giving you a fully functional Claude Code bot that can manage your server, supervise other bots, run scripts, and handle operations — all on your existing subscription.

## What It Does

- **Discord bot powered by Claude Code CLI** — same capabilities as terminal Claude Code
- **Zero API costs** — uses Max/Pro subscription by unsetting `ANTHROPIC_API_KEY`
- **Per-channel sessions** — conversations persist across messages
- **Cross-channel awareness** — Claude sees recent activity from other channels
- **Worker bot supervision** — watches another bot (e.g. OpenClaw) and corrects mistakes in real-time
- **Role-based access** — Boss / Admin / Team Member permissions
- **Shared brain logging** — all conversations logged for cross-platform context
- **Slash commands** — `/model`, `/clear`, `/status`, `/admin`, `/help`

## How It Works

```
Discord Message
    ↓
bridge.py (Python — discord.py)
    ↓
claude --print --model sonnet -p "prompt"  ← runs as subprocess
    ↓                                        ← ANTHROPIC_API_KEY unset = Max subscription
Claude Code CLI responds                    ← full server access, bash, files
    ↓
Response sent back to Discord
```

The key insight: `claude --print` is a subprocess call. By unsetting `ANTHROPIC_API_KEY` from the environment, it falls back to your Max/Pro subscription instead of consuming API credits. Every call is free.

## Quick Start

### Prerequisites

- **Claude Code CLI** installed: `npm install -g @anthropic-ai/claude-code`
- **Claude Max or Pro subscription** (for zero-cost API calls)
- **Python 3.10+**
- **Discord bot** created at [Discord Developer Portal](https://discord.com/developers/applications)

### Discord Bot Setup

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application → Bot section → copy the token
3. Enable these **Privileged Gateway Intents:**
   - Message Content Intent
   - Server Members Intent
4. Generate an invite URL (OAuth2 → URL Generator):
   - Scopes: `bot`
   - Permissions: `Send Messages`, `Read Message History`, `View Channels`
5. Invite the bot to your server

### Installation

```bash
git clone https://github.com/serpreach/claude-code-discord-manager.git
cd claude-code-discord-manager

# Install Python dependency
pip install -r requirements.txt

# Configure
cp .env.example .env
nano .env  # Fill in DISCORD_TOKEN and BOSS_DISCORD_ID

# Run
python3 bridge.py
```

### Run as a Service (Recommended)

Edit `claude-discord.service` with your paths, then:

```bash
sudo cp claude-discord.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable claude-discord
sudo systemctl start claude-discord

# Check logs
journalctl -u claude-discord -f
```

### Run with Docker

```bash
cp .env.example .env
nano .env  # Fill in your values

docker compose up -d
docker logs -f claude-discord-manager
```

> **Note:** Running on host (systemd) is recommended over Docker — gives Claude Code full server access without volume mounting everything.

## Configuration

All config is via environment variables (`.env` file):

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DISCORD_TOKEN` | Yes | — | Discord bot token |
| `BOSS_DISCORD_ID` | Yes | — | Your Discord user ID |
| `CLAUDE_MODEL` | No | `sonnet` | Default model (opus/sonnet/haiku) |
| `WORKER_BOT_ID` | No | `0` | Worker bot ID (0 = no supervision) |
| `WORKER_BOT_NAME` | No | `Worker` | Worker bot display name |
| `AUTO_RESPOND_CHANNELS` | No | — | Channel IDs where bot responds without @mention |
| `SUPERVISOR_COOLDOWN` | No | `30` | Seconds between supervisor checks |
| `MEMORY_DIR` | No | — | Path to Claude Code memory directory |
| `CLAUDE_CWD` | No | `~` | Working directory for claude CLI |
| `CLAUDE_TIMEOUT` | No | `300` | CLI response timeout (seconds) |

## Worker Bot Supervision

If you run another bot (like [OpenClaw](https://openclaw.com)), Claude Code can supervise it:

1. Set `WORKER_BOT_ID` to the bot's Discord user ID
2. Set `WORKER_BOT_NAME` to its display name
3. Claude Code will watch the worker's messages and intervene when it makes mistakes

The supervisor uses Haiku (fast + cheap) to evaluate each worker message against the conversation context. It only intervenes when the worker is clearly wrong — defaults to staying silent.

```
User asks question → Worker bot responds → Claude Code evaluates
                                              ↓
                                     Correct? → SILENT
                                     Wrong?   → Tags worker with correction
```

## Customizing the System Prompt

Edit the `SYSTEM_PROMPT` variable in `bridge.py` to customize Claude's personality, rules, and behavior for your use case. This prompt is sent with every `claude --print` call via `--append-system-prompt`.

## Slash Commands

| Command | Who | Description |
|---------|-----|-------------|
| `/model [opus\|sonnet\|haiku]` | Anyone | Switch Claude model |
| `/clear` | Anyone | Reset conversation session |
| `/status` | Anyone | Bridge uptime and stats |
| `/admin add/remove/list` | Boss only | Manage admin permissions |
| `/help` | Anyone | Show available commands |

## Architecture

```
┌─────────────────────────────────────────────────┐
│                    Discord                       │
│  #channel-1  #channel-2  #payments  DMs         │
└──────┬──────────┬──────────┬────────┬───────────┘
       │          │          │        │
       ▼          ▼          ▼        ▼
┌─────────────────────────────────────────────────┐
│              bridge.py                           │
│                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ History  │ │ Sessions │ │  Role & Access   │ │
│  │ Buffer   │ │ Manager  │ │  Control         │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
│                                                  │
│  ┌──────────────────┐ ┌──────────────────────┐  │
│  │   Supervisor     │ │  Cross-Channel       │  │
│  │   (worker bot)   │ │  Context Loader      │  │
│  └──────────────────┘ └──────────────────────┘  │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│     claude --print --model sonnet -p "..."       │
│                                                  │
│     env: ANTHROPIC_API_KEY removed               │
│     → Uses Max/Pro subscription (free)           │
│     → Full server access (bash, files, scripts)  │
│     → Session persistence (--resume)             │
└─────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│              Shared Brain                        │
│  ./shared-brain/conversation.jsonl               │
│  ./shared-brain/channels/{channel}.jsonl         │
└─────────────────────────────────────────────────┘
```

## Use Cases

- **Server manager bot** — run scripts, manage files, deploy code via Discord
- **Bot supervisor** — watch and correct a cheaper worker bot in real-time
- **Team coordination** — per-channel context, role-based access, operations
- **DevOps assistant** — server monitoring, log analysis, incident response

## Cost

**$0 additional** on Max/Pro subscription. The trick is removing `ANTHROPIC_API_KEY` from the subprocess environment, which forces `claude --print` to use your subscription quota instead of API credits.

```python
env = os.environ.copy()
env.pop('ANTHROPIC_API_KEY', None)  # This is the magic line
```

## License

MIT
