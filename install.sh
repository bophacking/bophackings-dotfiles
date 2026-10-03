#!/bin/bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Move aside real files/folders that would block stow.
# Existing symlinks are left alone, so rerunning is safe.
backup_conflicts() {
    for f in .zshrc .config/i3 .config/fastfetch; do
        target="$HOME/$f"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mv "$target" "$target.bak.$(date +%s)"
            log_warn "Backed up existing $f"
        fi
    done
}

install_user_configs() {
    log_info "Installing user configs with stow..."
    backup_conflicts
    mkdir -p "$HOME/.config"
    stow -d "$DOTFILES_DIR" -t "$HOME" -v zsh config pictures
}

install_system_configs() {
    log_info "Installing system configs (needs sudo)..."

    if [ -f "$DOTFILES_DIR/OutsideHome/picom.conf" ]; then
        sudo mkdir -p /etc/xdg
        sudo cp "$DOTFILES_DIR/OutsideHome/picom.conf" /etc/xdg/picom.conf
        log_info "Picom installed to /etc/xdg/picom.conf"
    fi

    if [ -f "$DOTFILES_DIR/OutsideHome/i3status.conf" ]; then
        sudo cp "$DOTFILES_DIR/OutsideHome/i3status.conf" /etc/i3status.conf
        log_info "i3status installed to /etc/i3status.conf"
    fi

    if [ -f "$DOTFILES_DIR/OutsideHome/i3blocks.conf" ]; then
        sudo cp "$DOTFILES_DIR/OutsideHome/i3blocks.conf" /etc/i3blocks.conf
        log_info "i3blocks installed to /etc/i3blocks.conf"
    fi
}

verify_installation() {
    log_info "Verifying symlinks..."
    echo ""
    find ~ -maxdepth 3 -type l -lname '*.dotfiles*' 2>/dev/null | head -10
}

main() {
    echo "================================"
    echo "   Dotfiles Installation"
    echo "================================"
    echo ""

    if ! command -v stow &> /dev/null; then
        log_error "stow is not installed. Install with: sudo apt install stow"
        exit 1
    fi

    install_user_configs
    echo ""

    install_system_configs
    echo ""

    verify_installation
    echo ""

    log_info "Installation complete!"
}

main "$@"
