#!/bin/bash

# Common functions shared between Ubuntu and macOS

configure_prezto() {
    local zpreztorc="$HOME/.zpreztorc"

    if [[ -f "$zpreztorc" ]]; then
        echo "Configuring Prezto..."

        # Enable required modules (git and zsh-z included)
        cat > "$zpreztorc" << 'EOF'
#
# Prezto Configuration
#

# Color output
zstyle ':prezto:*:*' color 'yes'

# Prezto modules to load (order matters)
zstyle ':prezto:load' pmodule \
  'environment' \
  'terminal' \
  'editor' \
  'history' \
  'directory' \
  'spectrum' \
  'utility' \
  'completion' \
  'git' \
  'syntax-highlighting' \
  'history-substring-search' \
  'autosuggestions' \
  'prompt'

# Set the prompt theme to paradox
zstyle ':prezto:module:prompt' theme 'paradox'

# Use long format for prompt
zstyle ':prezto:module:prompt' pwd-length 'long'

# Git module settings
zstyle ':prezto:module:git:status:ignore' submodules 'all'

# Editor settings
zstyle ':prezto:module:editor' key-bindings 'emacs'

# History substring search
zstyle ':prezto:module:history-substring-search' color 'yes'

# Syntax highlighting
zstyle ':prezto:module:syntax-highlighting' highlighters \
  'main' \
  'brackets' \
  'pattern' \
  'cursor'

# Terminal title
zstyle ':prezto:module:terminal' auto-title 'yes'
EOF
        echo "Prezto configured with paradox theme and long prompt format"
    fi
}

install_zsh_z() {
    local zsh_z_dir="${ZDOTDIR:-$HOME}/.zsh-z"

    if [[ ! -d "$zsh_z_dir" ]]; then
        echo "Installing zsh-z..."
        git clone https://github.com/agkozak/zsh-z.git "$zsh_z_dir"
    else
        echo "zsh-z already installed"
    fi

    # Add zsh-z to .zshrc if not already present
    if ! grep -q "zsh-z.plugin.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# zsh-z plugin" >> "$HOME/.zshrc"
        echo "source ${zsh_z_dir}/zsh-z.plugin.zsh" >> "$HOME/.zshrc"
        echo "zsh-z added to .zshrc"
    fi
}

configure_zshrc_mise() {
    local zshrc="$HOME/.zshrc"

    # Add mise PATH if not already present
    if ! grep -q 'HOME/.local/bin' "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# mise PATH" >> "$zshrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$zshrc"
        echo "mise PATH added to .zshrc"
    else
        echo "mise PATH already in .zshrc"
    fi

    # Add mise activation if not already present
    if ! grep -q "mise activate" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# mise activation" >> "$zshrc"
        echo 'eval "$(mise activate zsh)"' >> "$zshrc"
        echo "mise activation added to .zshrc"
    else
        echo "mise activation already in .zshrc"
    fi
}

configure_tmux() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local tmux_dir="$HOME/.tmux"

    if [[ ! -d "$tmux_dir" ]]; then
        echo "Installing Oh My Tmux..."
        git clone --single-branch https://github.com/gpakosz/.tmux.git "$tmux_dir"
        ln -sf "$tmux_dir/.tmux.conf" "$HOME/.tmux.conf"
    else
        echo "Oh My Tmux is already installed"
    fi

    # Deploy custom tmux config
    if [[ -f "$script_dir/configs/tmux.conf.local" ]]; then
        cp "$script_dir/configs/tmux.conf.local" "$HOME/.tmux.conf.local"
        echo "tmux.conf.local deployed"
    fi
}

set_default_editor() {
    echo "Setting default editor to vi..."
    git config --global core.editor "vi"
    if ! grep -q 'EDITOR=vi' "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Default editor" >> "$HOME/.zshrc"
        echo 'export EDITOR=vi' >> "$HOME/.zshrc"
        echo 'export VISUAL=vi' >> "$HOME/.zshrc"
    fi
    echo "Default editor set to vi"
}

# Cache installed extensions for idempotent installs
_vscode_installed=""
_load_vscode_extensions() {
    if [[ -z "$_vscode_installed" ]] && command -v code &>/dev/null; then
        _vscode_installed=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi
}

install_vscode_ext() {
    local ext="$1"
    code --install-extension "$ext" --force
}

install_cline_extension() {
    if command -v code &> /dev/null; then
        _load_vscode_extensions
        install_vscode_ext saoudrizwan.claude-dev || echo "Failed to install Cline extension"
    else
        echo "VS Code not found, skipping Cline extension installation"
    fi
}

install_gemini_cli() {
    echo "Installing Gemini CLI..."
    if command -v npm &> /dev/null; then
        npm install -g @anthropic-ai/claude-code 2>/dev/null || true
        npm install -g @google/generative-ai-cli 2>/dev/null || npm install -g gemini-cli 2>/dev/null || echo "Gemini CLI installation may require manual setup"
    else
        echo "npm not found yet. Gemini CLI will need to be installed after mise sets up Node.js"
        echo "Run: npm install -g @google/generative-ai-cli"
    fi
}

install_claude_code_cli() {
    echo "Installing Claude Code CLI..."
    if command -v npm &> /dev/null; then
        npm install -g @anthropic-ai/claude-code || echo "Claude Code CLI installation may require manual setup"
    else
        echo "npm not found yet. Claude Code CLI will need to be installed after mise sets up Node.js"
        echo "Run: npm install -g @anthropic-ai/claude-code"
    fi
}
