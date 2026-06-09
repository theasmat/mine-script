# Mine Scripts & Utilities

A curated collection of developer productivity scripts and utilities designed for macOS.

## Contents

- [🚀 mac-dev-setup.sh](file:///Users/as/Scripts/mine/mac-dev-setup.sh) - Interactive macOS developer environment setup script.
- [🔑 sshx.sh](file:///Users/as/Scripts/mine/sshx.sh) - Complete interactive SSH Identity Manager.
- [🔒 github_pp.sh](file:///Users/as/Scripts/mine/github_pp.sh) - Bulk GitHub repository privacy updater.
- [💾 free-disk-space-widget](file:///Users/as/Scripts/mine/free-disk-space-widget) - Go-based macOS menu bar utility for monitoring disk space.

---

### [🚀 mac-dev-setup.sh](file:///Users/as/Scripts/mine/mac-dev-setup.sh)
An interactive script to configure a fresh macOS installation for software development. Every single phase and option is fully prompt-driven (Y/n), idempotent, and safe to run multiple times.

**Features:**
- **System Tweaks:** Configures Dock behavior (auto-hide, tiny icons), Finder tweaks (show hidden files, paths, extensions), trackpad actions (tap-to-click, 3-finger drag), and keyboard repeat speedups.
- **Language Runtimes:**
  - Node.js (via official NVM installer & LTS configuration)
  - `pnpm` (via official standalone installer)
  - Rust (via official `rustup`)
  - Go (via Homebrew)
  - Python (via official `uv` standalone manager)
- **CLI Utilities:** Installs modern replacements like `eza`, `bat`, `fzf`, `ripgrep`, `fd`, `zoxide`, `jq`, `lazygit`, `lazydocker`, and more.
- **Shell & Aesthetics:** Sets up Zsh with Oh My Zsh, custom Zsh performance settings, developer aliases, and the premium [Passionp theme](https://github.com/theasmat/ohmyzsh-theme-passionp).
- **Fonts:** Installs essential developer Nerd Fonts (Fira Code, JetBrains Mono, Hack, etc.) required for eza and shell prompt icons.

**Usage:**
```bash
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh
```

---

### [🔑 sshx.sh](file:///Users/as/Scripts/mine/sshx.sh)
A comprehensive menu-driven SSH Identity Manager to list, create, test, and delete SSH keys and host configurations. It automates configuring distinct keys for personal, work, and client git hosting accounts.

**Features:**
- **Interactive Menu:** Run, navigate, and execute options cleanly.
- **List Identities:** Displays current Host configuration aliases, their hostnames/domains, and associated `IdentityFile` paths in a formatted table.
- **Safe Keys Creator:** Generates secure key pairs (Ed25519 or RSA-4096), adds them to `ssh-agent`, registers passphrases in the macOS Keychain, updates `~/.ssh/config` without duplications, and copies the public key directly to your clipboard.
- **Test Connections:** Tests authentication status against any configured Git host alias with timeout parameters.
- **Clean Deletion:** Removes selected Host configuration blocks from `~/.ssh/config` using a clean parser and optionally deletes local key pair files.

**Usage:**
```bash
chmod +x sshx.sh
./sshx.sh
```

---

### [🔒 github_pp.sh](file:///Users/as/Scripts/mine/github_pp.sh)
An interactive bulk repository manager for GitHub using the GitHub CLI (`gh`). It allows changing repository visibilities or deleting them in bulk.

**Features:**
- **Interactive Wizard:** Prompts for Account Type (User or Org) and name if run without arguments.
- **Bulk Private/Public:** Change visibility of all repositories to private or public with a single execution.
- **Bulk Delete:** Completely delete all repositories for a user or org.
- **Extreme Safety Guardrails:** Double confirmation prompts (requires typing the owner/account name to execute bulk deletion) to prevent accidental loss.

**Usage:**
```bash
# Launch interactive wizard
chmod +x github_pp.sh
./github_pp.sh

# Or pre-feed the wizard arguments:
./github_pp.sh user <username>
./github_pp.sh org <orgname>
```

---

### [💾 free-disk-space-widget](file:///Users/as/Scripts/mine/free-disk-space-widget)
A Go-based native macOS menu bar utility that displays available disk space in real-time. Includes launchd daemon configurations to automate starting at login.

**Build & Run:**
```bash
# Compile
go build -ldflags="-s -w" .

# Setup Autostart Agent
./create-autosta-file.sh
launchctl load ~/Library/LaunchAgents/free-disk-space-widget.autostart.plist
```

---

*Author: Asmat • [github.com/theasmat](https://github.com/theasmat)*
