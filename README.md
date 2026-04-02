# Kairu — The Office Dolphin, Reborn with AI

> Rebuilt Microsoft Office's legendary Japanese dolphin assistant for macOS,
> but actually useful this time. Local AI. Native Swift. Zero dependencies.

**Kairu** (カイル) was the dolphin assistant in Japanese editions of Microsoft Office 97/XP.
Famous for being unhelpful — and for the iconic search query "お前を消す方法" (how to delete you).

This project brings Kairu back as a macOS desktop companion, powered by a **local AI gateway**
([OpenClaw](https://github.com/nicholasgasior/openclaw)) instead of Microsoft's original scripted responses.
The dolphin now actually understands your questions.

## Features

- Floating transparent dolphin on your desktop (drag anywhere)
- Original Office XP animation style (idle, thinking, talking)
- Classic yellow balloon UI with Windows-style buttons
- Markdown rendering in responses
- Powered by local AI (OpenClaw + OpenAI Codex / any LLM)
- Menu bar integration (no Dock icon)
- Native Swift — zero external dependencies, ~15 source files
- Settings persisted (position, connection config)

## Requirements

- macOS 14.0+ (Sonoma or later, Apple Silicon recommended)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running locally
- [OpenClaw](https://github.com/nicholasgasior/openclaw) gateway in Docker

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_USER/kairu-app.git
cd kairu-app

# 2. Fetch Kairu's animation assets (one command!)
./scripts/fetch-assets.sh

# 3. Build & Run
swift build
open .build/debug/Kairu.app

# Or build a proper .app bundle:
./build-app.sh
```

### Install to Applications

```bash
./build-app.sh
cp -r .build/debug/Kairu.app /Applications/
```

## Connection Modes

Kairu works with **any** OpenClaw installation — Docker, native, or remote.

### Docker (default)

```bash
cd your-openclaw-dir/docker && docker compose up -d
# Kairu auto-connects via: docker exec <container> openclaw agent ...
```

### Native (openclaw installed locally)

```bash
# If you installed openclaw via npm:
npm i -g openclaw
openclaw gateway &

# Tell Kairu to use native mode:
defaults write com.iiba.kairu connectionMode "native"
```

### SSH (remote — Raspberry Pi, server, etc.)

```bash
# OpenClaw running on a Raspberry Pi or remote server:
defaults write com.iiba.kairu connectionMode "ssh"
defaults write com.iiba.kairu sshHost "pi@openclaw-pi"
```

### Configuration

| Setting | Default | `defaults write` key | Description |
|---------|---------|---------------------|-------------|
| Mode | `docker` | `connectionMode` | `docker` / `native` / `ssh` |
| Container | `openclaw-parenting-ai` | `containerName` | Docker container name |
| SSH Host | `pi@openclaw-pi` | `sshHost` | SSH target for remote mode |
| Agent | `main` | `agentName` | OpenClaw agent to talk to |
| Timeout | `120s` | `timeoutSeconds` | Max wait for AI response |

## How It Works

```
┌─────────────┐     ┌───────────────────────────┐     ┌──────────┐
│  Kairu App  │────▶│  docker exec / native /   │────▶│ OpenClaw │
│  (macOS)    │◀────│  ssh → openclaw agent     │◀────│ Gateway  │
│  Balloon UI │     │  stdin/stdout              │     │ (AI)     │
└─────────────┘     └───────────────────────────┘     └──────────┘
```

1. User types in the balloon → message sent via `docker exec` stdin (never exposed in `ps`)
2. OpenClaw processes with its configured AI model (GPT-5.4, etc.)
3. Response streamed back → Kairu switches from "thinking" to "talking" animation
4. Markdown rendered in the classic yellow balloon

## Asset Notice

The Kairu dolphin character and animations are property of Microsoft Corporation.
They are **not included** in this repository. The `fetch-assets.sh` script downloads
them from public internet archives for personal use. This project is unofficial and
not affiliated with Microsoft.

## Project Structure

```
kairu-app/
├── Package.swift              # SPM config (macOS 14+, zero deps)
├── build-app.sh               # Build .app bundle
├── scripts/
│   └── fetch-assets.sh        # Download Kairu animation assets
└── Sources/Kairu/
    ├── KairuApp.swift          # @main + MenuBarExtra
    ├── AppDelegate.swift       # Panel management + animation sync
    ├── KairuConfig.swift       # UserDefaults-backed settings
    ├── DolphinPanel.swift      # Transparent floating NSPanel
    ├── DolphinView.swift       # GIF animation + motion
    ├── AnimatedGIFView.swift   # NSImageView wrapper for GIF playback
    ├── ChatBubblePanel.swift   # Chat window NSPanel
    ├── ChatBubbleView.swift    # Classic Office balloon UI
    ├── ChatViewModel.swift     # Message state + send guard
    ├── OpenClawService.swift   # Secure docker exec communication
    ├── MenuBarView.swift       # Menu bar controls
    └── Resources/              # Assets (fetched by user)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License — see [LICENSE](LICENSE).

The Kairu character design is property of Microsoft Corporation.
This project is an unofficial fan recreation for educational and personal use.
