#!/bin/bash

set -e

# Workspace Setup Script
# Supports: Ubuntu and macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_DIR="$HOME/.workspace_setup_markers"
mkdir -p "$MARKER_DIR"

# Step tracking: skip already-completed steps on re-run
step_done() { [[ -f "$MARKER_DIR/$1" ]]; }
mark_done() { touch "$MARKER_DIR/$1"; }

run_step() {
    local name="$1"
    local label="$2"
    shift 2
    echo ""
    if step_done "$name"; then
        echo "=== $label === (already done, skipping)"
        return
    fi
    echo "=== $label ==="
    "$@"
    mark_done "$name"
}

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
echo "Tip: To force a full re-run, delete $MARKER_DIR"

# Source the appropriate OS-specific script
source "$SCRIPT_DIR/scripts/common.sh"

if [[ "$OS" == "ubuntu" ]]; then
    source "$SCRIPT_DIR/scripts/ubuntu.sh"
elif [[ "$OS" == "macos" ]]; then
    source "$SCRIPT_DIR/scripts/macos.sh"
fi

# Run setup functions in order
run_step git            "Installing Git"                          install_git
run_step zsh            "Installing Zsh"                          install_zsh
run_step prezto         "Installing Prezto"                       install_prezto
run_step fonts          "Installing Powerline Fonts"              install_powerline_fonts
run_step chrome         "Installing Chrome"                       install_chrome
run_step obsidian       "Installing Obsidian"                     install_obsidian
run_step zoom           "Installing Zoom"                         install_zoom

if [[ "$OS" == "macos" ]]; then
    run_step opensuperwhisper "Installing OpenSuperWhisper"       install_opensuperwhisper
    run_step iterm2          "Installing iTerm2"                  install_iterm2
fi

run_step mise           "Installing mise"                         install_mise
run_step languages      "Installing Python, Node.js, and Bun via mise" install_languages
run_step tmux           "Installing tmux with Oh My Tmux"         install_tmux
run_step vscode         "Installing VS Code"                      install_vscode
run_step vscode_ext     "Installing VS Code Extensions"           install_vscode_extensions
run_step cline          "Installing Cline Extension"              install_cline_extension
run_step gemini_cli     "Installing Gemini CLI"                   install_gemini_cli
run_step claude_cli     "Installing Claude Code CLI"              install_claude_code_cli

if [[ "$OS" == "ubuntu" ]]; then
    run_step terminator "Installing Terminator"                   install_terminator
fi

run_step default_editor "Setting Default Editor"                  set_default_editor
run_step default_shell  "Setting Zsh as default shell"            set_default_shell

echo ""
echo "=========================================="
echo "Workspace setup complete!"
echo "=========================================="
echo ""
echo "Please log out and log back in for all changes to take effect."
echo "After logging back in, open a new terminal to use zsh with Prezto."
echo ""
