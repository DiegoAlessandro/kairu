# Contributing to Kairu

Thanks for your interest in contributing!

## Getting Started

```bash
git clone https://github.com/YOUR_USER/kairu-app.git
cd kairu-app
./scripts/fetch-assets.sh   # Download animation assets
swift build                  # Verify build
```

## Development

- **Language:** Swift 6.0+, macOS 14.0+ target
- **Build:** `swift build` (SPM, no Xcode required)
- **Run:** `.build/debug/Kairu` or `./build-app.sh && open .build/debug/Kairu.app`
- **Dependencies:** Zero external packages

## Guidelines

- Keep external dependencies at zero
- Follow existing code style (SwiftUI + AppKit hybrid)
- Test on Apple Silicon (arm64)
- Do NOT commit Microsoft assets (GIF/PNG) — they are in `.gitignore`

## Pull Requests

1. Fork & create a feature branch
2. Keep PRs focused (one feature/fix per PR)
3. Include a brief description of what and why
4. Screenshots/videos for UI changes are appreciated

## Ideas for Contributions

- Custom character/skin support (bring your own sprites)
- WebSocket connection to OpenClaw (replace docker exec)
- Homebrew formula
- Additional animation states
- Accessibility improvements
- Localization (currently Japanese-focused)

## Code of Conduct

Be kind, be respectful. We're here to have fun bringing a nostalgic dolphin back to life.
