#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║                                                              ║
# ║        🚀 MAC DEVELOPER SETUP — COMPLETE WORKFLOW 🚀        ║
# ║                                                              ║
# ║   Professional Development Environment for macOS             ║
# ║   Node.js (NVM) • Rust • Go • Shell & CLI Tools             ║
# ║                                                              ║
# ║   Author: Asmat  •  github.com/theasmat                     ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage:
#   chmod +x mac-dev-setup.sh
#   ./mac-dev-setup.sh
#
# Features:
#   • Every single step is optional (y/n prompts)
#   • Idempotent — safe to re-run without breaking anything
#   • Logs all output to ~/mac-dev-setup.log
#   • Installs: Node.js (nvm), pnpm, Rust (rustup), Go, Python (uv)
#   • Configures: SSH keys, Zsh, Oh My Zsh + Passionp theme
#   • Sets up: Modern CLI tools (eza, bat, fzf, ripgrep)

set -euo pipefail

# --- CONFIGURATION & STYLING ---

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

CHECK="✅"
SKIP="⏭️ "
INFO="ℹ️ "
WARNING="⚠️ "
ROCKET="🚀"
GEAR="⚙️ "
PEN="✍️ "
FOLDER="📁"
DOCK_ICON="📱"
KEY="🔑"
SHELL_ICON="🐚"
PACKAGE="📦"
LANG_ICON="🔤"

LOG_FILE="$HOME/mac-dev-setup.log"
SUDO_PID=""

# --- HELPER FUNCTIONS ---

cleanup() {
    if [[ -n "${SUDO_PID:-}" ]] && kill -0 "$SUDO_PID" 2>/dev/null; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
    echo ""
    print_info "Log saved to: ${LOG_FILE}"
}
trap cleanup EXIT

exec > >(tee -a "$LOG_FILE") 2>&1

# ask_yes_no "Question?" [y|n]   — optional default
ask_yes_no() {
    local prompt="$1"
    local default="${2:-}"
    local hint="(y/n)"
    [[ "$default" == "y" ]] && hint="(Y/n)"
    [[ "$default" == "n" ]] && hint="(y/N)"

    while true; do
        printf "${YELLOW}%s${NC} ${CYAN}%s${NC}: " "$prompt" "$hint"
        read -r yn
        if [[ -z "$yn" && -n "$default" ]]; then
            [[ "$default" == "y" ]] && return 0 || return 1
        fi
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Please answer yes (y) or no (n).${NC}";;
        esac
    done
}

print_section() {
    local title="$1"
    local width=64
    local stripped
    stripped=$(echo "$title" | sed $'s/\033\\[[0-9;]*[a-zA-Z]//g')
    local title_len=${#stripped}
    local padding=$(( (width - title_len) / 2 ))
    local remainder=$(( (width - title_len) % 2 ))

    echo ""
    echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $((width + 2))))╗${NC}"
    printf "${CYAN}║${NC}%*s${WHITE}${BOLD}%s${NC}%*s${CYAN}║${NC}\n" "$((padding + 1))" "" "$title" "$((padding + remainder + 1))" ""
    echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $((width + 2))))╝${NC}"
    echo ""
}

print_subheader() {
    echo ""
    echo -e "  ${MAGENTA}${BOLD}── $1 ──${NC}"
    echo ""
}

print_info()    { echo -e "  ${BLUE}${INFO}${NC}  $1"; }
print_success() { echo -e "  ${GREEN}${CHECK}${NC} $1"; }
print_skip()    { echo -e "  ${DIM}${SKIP} $1${NC}"; }
print_warning() { echo -e "  ${RED}${WARNING}${NC} $1"; }

is_brew_installed() { brew list --formula "$1" &>/dev/null 2>&1; }
is_cask_installed() { brew list --cask "$1" &>/dev/null 2>&1; }

brew_install() {
    local name="$1"
    if is_brew_installed "$name"; then
        print_success "${name} already installed."
    else
        brew install "$name"
        print_success "${name} installed."
    fi
}

cask_install() {
    local name="$1"
    if is_cask_installed "$name"; then
        print_success "${name} already installed."
    else
        brew install --cask --no-quarantine "$name"
        print_success "${name} installed."
    fi
}

# --- SCRIPT SECTIONS ---

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "This script is designed for macOS only."
        exit 1
    fi
}

show_welcome() {
    clear
    print_section "${ROCKET} MAC DEVELOPER SETUP ${ROCKET}"
    print_info "Professional dev environment setup for macOS."
    print_info "Every step is optional — you're in full control."
    print_info "Safe to re-run: skips anything already installed."
    echo ""
    echo -e "  ${DIM}Logging to: ${LOG_FILE}${NC}"
    echo ""
    printf "  ${WHITE}Press ${GREEN}ENTER${NC} to begin..."
    read -r
}

# ============================================================
# STEP 1: SYSTEM PREPARATION
# ============================================================
system_prep() {
    print_section "${ROCKET} STEP 1: SYSTEM PREPARATION"
    print_info "Requesting administrator privileges..."
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_PID=$!
    print_success "Privileges acquired."
}

# ============================================================
# STEP 2: DOCK CONFIGURATION
# ============================================================
configure_dock() {
    print_section "${DOCK_ICON} STEP 2: DOCK CONFIGURATION"
    local dock_changed=0

    if ask_yes_no "Remove all default apps from Dock?"; then
        defaults write com.apple.dock persistent-apps -array
        print_success "All pinned apps removed."
        dock_changed=1
    else
        print_skip "Keeping current Dock apps."
    fi

    if ask_yes_no "Enable Dock auto-hide?" y; then
        defaults write com.apple.dock autohide -bool true
        print_success "Dock auto-hide enabled."
        dock_changed=1
    else
        print_skip "Dock auto-hide skipped."
    fi

    if ask_yes_no "Set smaller Dock icon size (36px)?"; then
        defaults write com.apple.dock tilesize -int 36
        print_success "Dock icon size set to 36px."
        dock_changed=1
    else
        print_skip "Dock icon size skipped."
    fi

    if ask_yes_no "Show only active apps in Dock?"; then
        defaults write com.apple.dock static-only -bool true
        print_success "Dock shows only running apps."
        dock_changed=1
    else
        print_skip "Static Dock skipped."
    fi

    if [[ $dock_changed -eq 1 ]]; then
        print_info "Restarting Dock..."
        killall Dock
        print_success "Dock configured!"
    fi
}

# ============================================================
# STEP 3: FINDER OPTIMIZATION
# ============================================================
configure_finder() {
    print_section "${FOLDER} STEP 3: FINDER OPTIMIZATION"
    local finder_changed=0

    if ask_yes_no "Show hidden files (.zshrc, .gitconfig etc.)?" y; then
        defaults write com.apple.finder AppleShowAllFiles -bool true
        print_success "Hidden files visible."
        finder_changed=1
    else
        print_skip "Hidden files skipped."
    fi

    if ask_yes_no "Show all filename extensions (.js, .md etc.)?" y; then
        defaults write NSGlobalDomain AppleShowAllExtensions -bool true
        print_success "All extensions visible."
        finder_changed=1
    else
        print_skip "Extensions skipped."
    fi

    if ask_yes_no "Show path bar at bottom of Finder?" y; then
        defaults write com.apple.finder ShowPathbar -bool true
        print_success "Path bar enabled."
        finder_changed=1
    else
        print_skip "Path bar skipped."
    fi

    if ask_yes_no "Show status bar in Finder?"; then
        defaults write com.apple.finder ShowStatusBar -bool true
        print_success "Status bar enabled."
        finder_changed=1
    else
        print_skip "Status bar skipped."
    fi

    if ask_yes_no "Default to list view in Finder?"; then
        defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
        print_success "Default view set to list."
        finder_changed=1
    else
        print_skip "List view skipped."
    fi

    if ask_yes_no "Disable .DS_Store on network & USB volumes?" y; then
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
        print_success ".DS_Store disabled on external volumes."
        finder_changed=1
    else
        print_skip ".DS_Store setting skipped."
    fi

    if [[ $finder_changed -eq 1 ]]; then
        print_info "Restarting Finder..."
        killall Finder
        print_success "Finder optimized!"
    fi
}

# ============================================================
# STEP 4: SYSTEM & INPUT PREFERENCES
# ============================================================
configure_system_prefs() {
    print_section "${GEAR} STEP 4: SYSTEM & INPUT PREFERENCES"

    if ask_yes_no "Change screenshot format to PNG?"; then
        defaults write com.apple.screencapture type png
        killall SystemUIServer 2>/dev/null || true
        print_success "Screenshots → PNG."
    else
        print_skip "Screenshot format skipped."
    fi

    if ask_yes_no "Create ~/Desktop/Screenshots folder?"; then
        mkdir -p "$HOME/Desktop/Screenshots"
        defaults write com.apple.screencapture location "$HOME/Desktop/Screenshots"
        killall SystemUIServer 2>/dev/null || true
        print_success "Screenshots save to ~/Desktop/Screenshots."
    else
        print_skip "Screenshot location skipped."
    fi

    if ask_yes_no "Speed up keyboard repeat rate?" y; then
        defaults write NSGlobalDomain KeyRepeat -int 2
        defaults write NSGlobalDomain InitialKeyRepeat -int 15
        print_success "Key repeat rate increased."
    else
        print_skip "Keyboard repeat skipped."
    fi

    if ask_yes_no "Enable 'Tap to click' for trackpad?" y; then
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        print_success "Tap to click enabled."
    else
        print_skip "Tap to click skipped."
    fi

    if ask_yes_no "Enable three-finger drag?"; then
        defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
        print_success "Three-finger drag enabled."
    else
        print_skip "Three-finger drag skipped."
    fi
}

# ============================================================
# STEP 5: KEYBOARD INPUT CORRECTIONS
# ============================================================
configure_keyboard_input() {
    print_section "${PEN} STEP 5: KEYBOARD INPUT CORRECTIONS"
    print_info "Prevents unwanted text transformations while coding."

    if ask_yes_no "Disable automatic capitalization?" y; then
        defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
        print_success "Auto-capitalization disabled."
    else
        print_skip "Auto-capitalization kept."
    fi

    if ask_yes_no "Disable automatic period (double-space)?" y; then
        defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
        print_success "Auto-period disabled."
    else
        print_skip "Auto-period kept."
    fi

    if ask_yes_no "Disable smart quotes?" y; then
        defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
        print_success "Smart quotes disabled."
    else
        print_skip "Smart quotes kept."
    fi

    if ask_yes_no "Disable smart dashes?" y; then
        defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
        print_success "Smart dashes disabled."
    else
        print_skip "Smart dashes kept."
    fi

    if ask_yes_no "Disable auto-correct?" y; then
        defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
        print_success "Auto-correct disabled."
    else
        print_skip "Auto-correct kept."
    fi
}

# ============================================================
# STEP 6: CORE DEVELOPMENT TOOLS
# ============================================================
install_core_tools() {
    print_section "🛠️  STEP 6: CORE DEVELOPMENT TOOLS"

    # --- Xcode CLI Tools ---
    print_subheader "Xcode Command Line Tools"
    print_info "Provides Git, compilers (clang), and build essentials."
    if ask_yes_no "Install Xcode Command Line Tools? (required for Homebrew)" y; then
        if xcode-select -p &>/dev/null; then
            print_success "Xcode CLI Tools already installed."
        else
            xcode-select --install
            print_info "System dialog will appear. Click 'Install' and wait..."
            until xcode-select -p &>/dev/null; do sleep 5; done
            print_success "Xcode CLI Tools installed!"
        fi
    else
        print_skip "Xcode CLI Tools skipped."
        print_warning "Homebrew and many tools require this."
    fi

    # --- Homebrew ---
    print_subheader "Homebrew Package Manager"
    if ask_yes_no "Install Homebrew?" y; then
        if command -v brew &>/dev/null; then
            print_success "Homebrew already installed."
            print_info "Updating Homebrew..."
            brew update
            print_success "Homebrew updated."
        else
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ $(uname -m) == "arm64" ]]; then
                echo '' >> "$HOME/.zprofile"
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            print_success "Homebrew installed!"
        fi
        brew analytics off
        print_info "Homebrew analytics disabled."
    else
        print_skip "Homebrew skipped."
    fi
}

# ============================================================
# STEP 7: SSH KEY SETUP
# ============================================================
setup_ssh() {
    print_section "${KEY} STEP 7: SSH KEY SETUP"

    if ask_yes_no "Generate a new SSH key for GitHub/GitLab?"; then
        local ssh_email
        printf "  ${YELLOW}Enter email for SSH key:${NC} "
        read -r ssh_email

        if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
            print_warning "SSH key already exists at ~/.ssh/id_ed25519"
            if ! ask_yes_no "Overwrite existing key?"; then
                print_skip "Keeping existing SSH key."
                return
            fi
        fi

        ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
        eval "$(ssh-agent -s)"

        mkdir -p "$HOME/.ssh"
        if ! grep -q "Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
            cat >> "$HOME/.ssh/config" << 'EOF'

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

Host gitlab.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
        fi
        chmod 600 "$HOME/.ssh/config"
        ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

        echo ""
        print_success "SSH key generated and added to agent!"
        print_info "Your public key (copy to GitHub/GitLab):"
        echo ""
        echo -e "  ${CYAN}$(cat "$HOME/.ssh/id_ed25519.pub")${NC}"
        echo ""
        print_info "Add at: https://github.com/settings/keys"
        pbcopy < "$HOME/.ssh/id_ed25519.pub"
        print_success "Public key copied to clipboard!"
    else
        print_skip "SSH key generation skipped."
    fi
}

# ============================================================
# STEP 8: PROGRAMMING LANGUAGES
# ============================================================
install_languages() {
    print_section "${LANG_ICON} STEP 8: PROGRAMMING LANGUAGES"

    # ── Node.js via NVM (official) ──
    print_subheader "Node.js (via NVM — official)"
    print_info "NVM is the official Node Version Manager."
    print_info "Install script: https://github.com/nvm-sh/nvm"
    if ask_yes_no "Install Node.js via NVM?" y; then
        export NVM_DIR="$HOME/.nvm"

        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            print_success "NVM already installed."
            # shellcheck source=/dev/null
            source "$NVM_DIR/nvm.sh"
        else
            # Official NVM install — always pulls latest
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

            # Load NVM into current session
            # shellcheck source=/dev/null
            source "$NVM_DIR/nvm.sh"
            print_success "NVM $(nvm --version) installed!"
        fi

        # NVM auto-adds itself to .zshrc/.bashrc, but verify
        local zshrc="$HOME/.zshrc"
        if [[ -f "$zshrc" ]] && ! grep -q 'NVM_DIR' "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
            print_info "NVM config added to .zshrc"
        fi

        # Install latest LTS
        if ask_yes_no "Install latest Node.js LTS?" y; then
            nvm install --lts
            nvm use --lts
            nvm alias default 'lts/*'
            print_success "Node.js $(node --version) installed and set as default."
            print_success "npm $(npm --version) available."
        fi
    else
        print_skip "Node.js installation skipped."
    fi

    # ── pnpm (official standalone) ──
    print_subheader "pnpm (official standalone installer)"
    print_info "pnpm — fast, disk-efficient package manager."
    print_info "Install script: https://pnpm.io/installation"
    if ask_yes_no "Install pnpm (official standalone)?" y; then
        if command -v pnpm &>/dev/null; then
            print_success "pnpm already installed ($(pnpm --version))."
        else
            curl -fsSL https://get.pnpm.io/install.sh | sh -

            # pnpm adds itself to shell config, but source it now
            export PNPM_HOME="$HOME/Library/pnpm"
            export PATH="$PNPM_HOME:$PATH"

            if command -v pnpm &>/dev/null; then
                print_success "pnpm $(pnpm --version) installed!"
            else
                print_success "pnpm installed! Restart your terminal to use it."
            fi
        fi
    else
        print_skip "pnpm installation skipped."
    fi

    # ── Rust via rustup (official) ──
    print_subheader "Rust (via rustup — official)"
    print_info "Rustup is the official Rust toolchain installer."
    if ask_yes_no "Install Rust?"; then
        if command -v rustc &>/dev/null; then
            print_success "Rust already installed ($(rustc --version))."
            if ask_yes_no "Update Rust to latest?"; then
                rustup update
                print_success "Rust updated."
            fi
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            # shellcheck source=/dev/null
            source "$HOME/.cargo/env" 2>/dev/null || true
            print_success "Rust $(rustc --version | awk '{print $2}') installed!"
        fi
    else
        print_skip "Rust skipped."
    fi

    # ── Go via Homebrew ──
    print_subheader "Go (Golang)"
    print_info "Go — fast, statically typed language for backends & CLIs."
    if ask_yes_no "Install Go?"; then
        if command -v go &>/dev/null; then
            print_success "Go already installed ($(go version))."
        else
            if command -v brew &>/dev/null; then
                brew install go
            else
                print_warning "Homebrew required for Go. Skipping."
                return
            fi

            mkdir -p "$HOME/go/"{bin,src,pkg}

            local zshrc="$HOME/.zshrc"
            if [[ -f "$zshrc" ]] && ! grep -q "GOPATH" "$zshrc"; then
                cat >> "$zshrc" << 'EOF'

# Go configuration
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
EOF
            fi
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"

            print_success "Go $(go version | awk '{print $3}') installed!"
            print_info "GOPATH → ~/go"
        fi
    else
        print_skip "Go skipped."
    fi

    # ── Python & uv (official) ──
    print_subheader "Python & uv (official)"
    print_info "uv is a blazing-fast Python package, environment, and version manager."
    print_info "It replaces pip, pip-tools, pipx, poetry, pyenv, and virtualenv."
    if ask_yes_no "Install uv (official standalone manager)?" y; then
        local uv_bin="$HOME/.local/bin/uv"
        if [[ -f "$uv_bin" ]] || command -v uv &>/dev/null; then
            print_success "uv already installed."
            # Load it into current session
            export PATH="$HOME/.local/bin:$PATH"
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
            export PATH="$HOME/.local/bin:$PATH"
            if command -v uv &>/dev/null; then
                print_success "uv $(uv --version | awk '{print $2}') installed!"
            else
                print_success "uv installed!"
            fi
        fi

        # Verify or add uv path to .zshrc
        local zshrc="$HOME/.zshrc"
        if [[ -f "$zshrc" ]] && ! grep -q 'uv' "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# uv (Python manager) path
export PATH="$HOME/.local/bin:$PATH"
EOF
            print_info "uv path added to .zshrc"
        fi
    else
        print_skip "uv installation skipped."
    fi
}

# ============================================================
# STEP 9: TERMINAL TOOLS
# ============================================================
install_terminal_tools() {
    print_section "${PACKAGE} STEP 9: TERMINAL TOOLS"

    if ! command -v brew &>/dev/null; then
        print_warning "Homebrew not found. Skipping."
        return
    fi

    print_info "Modern CLI replacements and essential dev tools."
    local tools=(
        "eza:eza — modern ls replacement (colors, icons, git-aware)"
        "bat:bat — cat with syntax highlighting & line numbers"
        "fzf:fzf — fuzzy finder for files, history, everything"
        "ripgrep:ripgrep (rg) — blazing-fast grep replacement"
        "fd:fd — simple & fast find replacement"
        "zoxide:zoxide — smarter cd that learns your habits"
        "tree:tree — directory tree viewer"
        "htop:htop — interactive process viewer"
        "jq:jq — JSON processor & pretty-printer"
        "wget:wget — file downloader"
        "tldr:tldr — simplified man pages with examples"
        "gh:gh — official GitHub CLI"
        "lazygit:lazygit — beautiful terminal Git UI"
        "lazydocker:lazydocker — terminal Docker dashboard"
        "neovim:neovim — modern Vim editor"
        "tmux:tmux — terminal multiplexer"
        "httpie:httpie — modern curl alternative"
        "git-delta:delta — beautiful git diff viewer"
    )

    for entry in "${tools[@]}"; do
        local tool="${entry%%:*}"
        local desc="${entry#*:}"
        if ask_yes_no "Install ${desc}?"; then
            brew_install "$tool"
        else
            print_skip "Skipped ${tool}."
        fi
    done
}

# ============================================================
# STEP 10: SHELL CONFIGURATION (Oh My Zsh — Best Setup)
# ============================================================
configure_shell() {
    print_section "${SHELL_ICON} STEP 10: SHELL CONFIGURATION"

    local zshrc="$HOME/.zshrc"

    # ── Oh My Zsh ──
    print_subheader "Oh My Zsh — Framework"
    print_info "The most popular Zsh framework with 2000+ plugins & themes."
    if ask_yes_no "Install Oh My Zsh?" y; then
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            print_success "Oh My Zsh already installed."
        else
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
            print_success "Oh My Zsh installed!"
        fi

        local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

        # ── Passionp Theme (github.com/theasmat/ohmyzsh-theme-passionp) ──
        print_subheader "Passionp — Theme"
        print_info "Custom Zsh theme with root awareness, venv/nvm detection,"
        print_info "smart execution timer, exit codes & full Nerd Font support."
        print_info "Requires a Nerd Font (installed in the Fonts step)."
        if ask_yes_no "Install Passionp theme?" y; then
            local theme_file="$HOME/.oh-my-zsh/themes/passionp.zsh-theme"
            if [[ -f "$theme_file" ]]; then
                print_success "Passionp theme already installed."
                if ask_yes_no "Update to latest version?"; then
                    curl -fsSL https://raw.githubusercontent.com/theasmat/ohmyzsh-theme-passionp/master/passionp.zsh-theme -o "$theme_file"
                    print_success "Passionp theme updated!"
                fi
            else
                curl -fsSL https://raw.githubusercontent.com/theasmat/ohmyzsh-theme-passionp/master/passionp.zsh-theme -o "$theme_file"
                print_success "Passionp theme downloaded!"
            fi

            # Set theme in .zshrc
            if [[ -f "$zshrc" ]]; then
                if grep -q '^ZSH_THEME=' "$zshrc"; then
                    sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="passionp"/' "$zshrc"
                else
                    echo 'ZSH_THEME="passionp"' >> "$zshrc"
                fi
                print_success "Theme set to passionp in .zshrc"
            fi
        else
            print_skip "Passionp theme skipped."
        fi

        # ── Plugins ──
        print_subheader "Oh My Zsh — Best Plugins"
        print_info "Installing the essential community plugins..."

        if ask_yes_no "Install zsh-autosuggestions (fish-like suggestions)?" y; then
            if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
                git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
                print_success "zsh-autosuggestions installed."
            else
                print_success "zsh-autosuggestions already installed."
            fi
        fi

        if ask_yes_no "Install zsh-syntax-highlighting (live command coloring)?" y; then
            if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
                git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_custom/plugins/zsh-syntax-highlighting"
                print_success "zsh-syntax-highlighting installed."
            else
                print_success "zsh-syntax-highlighting already installed."
            fi
        fi

        if ask_yes_no "Install zsh-completions (extra tab completions)?" y; then
            if [[ ! -d "$zsh_custom/plugins/zsh-completions" ]]; then
                git clone https://github.com/zsh-users/zsh-completions "$zsh_custom/plugins/zsh-completions"
                print_success "zsh-completions installed."
            else
                print_success "zsh-completions already installed."
            fi
        fi

        if ask_yes_no "Install zsh-history-substring-search (↑↓ history search)?" y; then
            if [[ ! -d "$zsh_custom/plugins/zsh-history-substring-search" ]]; then
                git clone https://github.com/zsh-users/zsh-history-substring-search "$zsh_custom/plugins/zsh-history-substring-search"
                print_success "zsh-history-substring-search installed."
            else
                print_success "zsh-history-substring-search already installed."
            fi
        fi

        if ask_yes_no "Install you-should-use (reminds you of existing aliases)?" y; then
            if [[ ! -d "$zsh_custom/plugins/you-should-use" ]]; then
                git clone https://github.com/MichaelAqworthy/zsh-you-should-use "$zsh_custom/plugins/you-should-use"
                print_success "you-should-use installed."
            else
                print_success "you-should-use already installed."
            fi
        fi

        if ask_yes_no "Install zsh-nvm (auto-load correct Node version per project)?" y; then
            if [[ ! -d "$zsh_custom/plugins/zsh-nvm" ]]; then
                git clone https://github.com/lukechilds/zsh-nvm "$zsh_custom/plugins/zsh-nvm"
                print_success "zsh-nvm installed."
            else
                print_success "zsh-nvm already installed."
            fi
        fi

        # Configure plugins in .zshrc
        print_subheader "Activating Plugins in .zshrc"
        if [[ -f "$zshrc" ]] && grep -q '^plugins=(' "$zshrc"; then
            # Build the plugins list from what's actually installed
            local plugin_list="git"

            # Community plugins (only add if installed)
            [[ -d "$zsh_custom/plugins/zsh-autosuggestions" ]] && plugin_list+=" zsh-autosuggestions"
            [[ -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]] && plugin_list+=" zsh-syntax-highlighting"
            [[ -d "$zsh_custom/plugins/zsh-completions" ]] && plugin_list+=" zsh-completions"
            [[ -d "$zsh_custom/plugins/zsh-history-substring-search" ]] && plugin_list+=" zsh-history-substring-search"
            [[ -d "$zsh_custom/plugins/you-should-use" ]] && plugin_list+=" you-should-use"
            [[ -d "$zsh_custom/plugins/zsh-nvm" ]] && plugin_list+=" zsh-nvm"

            # Built-in OMZ plugins (always available, curated best)
            plugin_list+=" docker"
            plugin_list+=" npm"
            plugin_list+=" node"
            plugin_list+=" vscode"
            plugin_list+=" macos"
            plugin_list+=" web-search"
            plugin_list+=" copypath"
            plugin_list+=" copyfile"
            plugin_list+=" dirhistory"
            plugin_list+=" jsontools"
            plugin_list+=" aliases"
            plugin_list+=" colored-man-pages"
            plugin_list+=" command-not-found"
            plugin_list+=" extract"
            plugin_list+=" sudo"

            sed -i '' "s/^plugins=(.*/plugins=(${plugin_list})/" "$zshrc"
            print_success "Plugins activated in .zshrc!"
            echo ""
            print_info "Enabled plugins:"
            echo -e "  ${CYAN}Community:${NC} autosuggestions, syntax-highlighting, completions,"
            echo -e "             history-substring-search, you-should-use, zsh-nvm"
            echo -e "  ${CYAN}Built-in:${NC}  git, docker, npm, node, vscode, macos, web-search,"
            echo -e "             copypath, copyfile, dirhistory, jsontools, aliases,"
            echo -e "             colored-man-pages, command-not-found, extract, sudo"
        else
            print_warning "Could not find plugins=() line in .zshrc — add plugins manually."
        fi

        # ── Zsh Performance Tweaks ──
        print_subheader "Zsh Performance Tweaks"
        if ask_yes_no "Add performance & history tweaks to .zshrc?" y; then
            if ! grep -q "# === Zsh Performance Tweaks ===" "$zshrc" 2>/dev/null; then
                cat >> "$zshrc" << 'EOF'

# === Zsh Performance Tweaks ===

# Bigger, smarter history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # Share history across all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_VERIFY            # Show substituted history before running
setopt INC_APPEND_HISTORY     # Add immediately, not on exit

# Completion tweaks
setopt COMPLETE_ALIASES       # Complete aliases
zstyle ':completion:*' menu select                          # Arrow key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case-insensitive

# NVM lazy loading (faster shell startup)
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true
EOF
                print_success "Performance tweaks added to .zshrc!"
            else
                print_success "Performance tweaks already present."
            fi
        fi
    else
        print_skip "Oh My Zsh skipped."
    fi

    # ── Shell Aliases ──
    print_subheader "Shell Aliases & Functions"
    if ask_yes_no "Add useful dev aliases to .zshrc?" y; then
        if ! grep -q "# === Dev Aliases ===" "$zshrc" 2>/dev/null; then
            cat >> "$zshrc" << 'ALIASES'

# === Dev Aliases ===

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Modern CLI replacements (only if installed)
command -v eza &>/dev/null && alias ls="eza --icons --group-directories-first"
command -v eza &>/dev/null && alias ll="eza -la --icons --group-directories-first --git"
command -v eza &>/dev/null && alias lt="eza --tree --level=2 --icons"
command -v bat &>/dev/null && alias cat="bat --paging=never"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Git
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias glog="git log --graph --oneline --decorate -20"
alias gd="git diff"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gundo="git reset --soft HEAD~1"

# Node/pnpm
alias dev="pnpm dev"
alias build="pnpm build"
alias start="pnpm start"
alias test="pnpm test"
alias pi="pnpm install"
alias pa="pnpm add"
alias pad="pnpm add -D"

# System
alias brewup="brew update && brew upgrade && brew cleanup"
alias ports="lsof -i -P -n | grep LISTEN"
alias myip="curl -s ifconfig.me"
alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"
alias rmrf="rm -rf"

# Quick edit
alias zshrc="${EDITOR:-code} ~/.zshrc"
alias reload="source ~/.zshrc"
ALIASES
            print_success "Dev aliases added to .zshrc!"
        else
            print_success "Dev aliases already present."
        fi
    else
        print_skip "Aliases skipped."
    fi

    # ── fzf key bindings ──
    if command -v fzf &>/dev/null; then
        if ask_yes_no "Enable fzf key bindings (Ctrl+R history, Ctrl+T files)?" y; then
            if ! grep -q "fzf" "$zshrc" 2>/dev/null; then
                echo '' >> "$zshrc"
                echo '# fzf integration' >> "$zshrc"
                echo 'source <(fzf --zsh) 2>/dev/null || true' >> "$zshrc"
            fi
            print_success "fzf key bindings configured."
        fi
    fi
}

# ============================================================
# STEP 11: DEVELOPER FONTS
# ============================================================
install_fonts() {
    print_section "🔤 STEP 11: DEVELOPER FONTS"

    if ! command -v brew &>/dev/null; then
        print_warning "Homebrew not found. Skipping fonts."
        return
    fi

    print_info "Nerd Fonts are required for passionp theme icons & eza icons."

    if ask_yes_no "Install developer Nerd Fonts?" y; then
        local fonts=(
            "font-fira-code-nerd-font:Fira Code Nerd Font (recommended for passionp)"
            "font-jetbrains-mono-nerd-font:JetBrains Mono Nerd Font"
            "font-hack-nerd-font:Hack Nerd Font"
            "font-meslo-lg-nerd-font:MesloLGS Nerd Font"
        )
        for entry in "${fonts[@]}"; do
            local font="${entry%%:*}"
            local desc="${entry#*:}"
            if ask_yes_no "Install ${desc}?"; then
                cask_install "$font"
            else
                print_skip "Skipped ${font}."
            fi
        done

        echo ""
        print_info "After installing, set your terminal font to a Nerd Font."
        print_info "iTerm2: Settings → Profiles → Text → Font → choose your Nerd Font."
        print_info "Recommended: FiraCode Nerd Font or JetBrainsMono Nerd Font."
    else
        print_skip "Fonts skipped."
    fi
}

# ============================================================
# STEP 12: FINALIZATION
# ============================================================
show_completion() {
    print_section "🎉 SETUP COMPLETE 🎉"

    echo -e "  ${GREEN}${ROCKET} Your Mac is now configured for development!${NC}"
    echo ""

    print_subheader "Installed Versions"
    command -v node    &>/dev/null && print_success "Node.js:  $(node --version)"
    command -v npm     &>/dev/null && print_success "npm:      $(npm --version)"
    command -v pnpm    &>/dev/null && print_success "pnpm:     $(pnpm --version 2>/dev/null || echo 'restart terminal')"
    command -v rustc   &>/dev/null && print_success "Rust:     $(rustc --version | awk '{print $2}')"
    command -v cargo   &>/dev/null && print_success "Cargo:    $(cargo --version | awk '{print $2}')"
    command -v go      &>/dev/null && print_success "Go:       $(go version | awk '{print $3}')"
    command -v python3 &>/dev/null && print_success "Python:   $(python3 --version | awk '{print $2}')"
    PATH="$HOME/.local/bin:$PATH" command -v uv &>/dev/null && print_success "uv:       $(PATH="$HOME/.local/bin:$PATH" uv --version | awk '{print $2}')"
    command -v git     &>/dev/null && print_success "Git:      $(git --version | awk '{print $3}')"
    command -v brew    &>/dev/null && print_success "Homebrew: $(brew --version | head -1 | awk '{print $2}')"

    echo ""
    print_info "Log file: ${LOG_FILE}"
    echo ""

    echo -e "  ${YELLOW}${WARNING}${NC} ${WHITE}${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  ${CYAN}  1. Restart your terminal (or run: ${GREEN}source ~/.zshrc${CYAN})${NC}"
    echo -e "  ${CYAN}  2. Set terminal font to a ${GREEN}Nerd Font${CYAN} (FiraCode/JetBrainsMono)${NC}"
    echo -e "  ${CYAN}  3. Passionp theme is ready — enjoy your prompt! 🎨${NC}"
    echo ""

    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        echo -e "  ${YELLOW}${KEY}${NC}  Add your SSH key to GitHub: ${CYAN}https://github.com/settings/keys${NC}"
        echo ""
    fi

    echo -e "  ${MAGENTA}${BOLD}Happy coding! 🎊${NC}"
    echo ""
}

# ============================================================
# MAIN EXECUTION FLOW
# ============================================================
main() {
    check_macos
    show_welcome
    system_prep

    # Phase 1: System & UI
    configure_dock
    configure_finder
    configure_system_prefs
    configure_keyboard_input

    # Phase 2: Core Tools
    install_core_tools
    setup_ssh

    # Phase 3: Languages
    install_languages

    # Phase 4: CLI Tools
    install_terminal_tools

    # Phase 5: Shell & Fonts
    configure_shell
    install_fonts

    # Done
    show_completion
}

main "$@"