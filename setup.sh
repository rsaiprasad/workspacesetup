#!/bin/bash

set -e

# Workspace Setup Script
# Supports: Ubuntu and macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            echo "ubuntu"
        else
            echo "unsupported"
        fi
    else
        echo "unsupported"
    fi
}

OS=$(detect_os)

if [[ "$OS" == "unsupported" ]]; then
    echo "Error: Unsupported operating system. This script supports Ubuntu and macOS only."
    exit 1
fi

echo "Detected OS: $OS"
echo "Starting workspace setup..."

# Source the appropriate OS-specific script
source "$SCRIPT_DIR/scripts/common.sh"

if [[ "$OS" == "ubuntu" ]]; then
    source "$SCRIPT_DIR/scripts/ubuntu.sh"
elif [[ "$OS" == "macos" ]]; then
    source "$SCRIPT_DIR/scripts/macos.sh"
fi

# Run setup functions in order
echo ""
echo "=== Installing Git ==="
install_git

echo ""
echo "=== Installing Zsh ==="
install_zsh

echo ""
echo "=== Installing Prezto ==="
install_prezto

echo ""
echo "=== Installing Powerline Fonts ==="
install_powerline_fonts

echo ""
echo "=== Installing Chrome ==="
install_chrome

echo ""
echo "=== Installing mise ==="
install_mise

echo ""
echo "=== Installing Python and Node.js via mise ==="
install_languages

echo ""
echo "=== Installing VS Code ==="
install_vscode

echo ""
echo "=== Installing Cline Extension ==="
install_cline_extension

echo ""
echo "=== Installing Gemini CLI ==="
install_gemini_cli

echo ""
echo "=== Installing Claude Code CLI ==="
install_claude_code_cli

if [[ "$OS" == "ubuntu" ]]; then
    echo ""
    echo "=== Installing Terminator ==="
    install_terminator
fi

echo ""
echo "=== Setting Zsh as default shell ==="
set_default_shell

echo ""
echo "=========================================="
echo "Workspace setup complete!"
echo "=========================================="
echo ""
echo "Please log out and log back in for all changes to take effect."
echo "After logging back in, open a new terminal to use zsh with Prezto."
echo ""
