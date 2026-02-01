#!/bin/bash

# Ubuntu-specific installation functions

install_git() {
    if ! command -v git &> /dev/null; then
        echo "Installing git..."
        sudo apt-get update
        sudo apt-get install -y git
    else
        echo "git is already installed"
    fi
}

install_zsh() {
    if ! command -v zsh &> /dev/null; then
        echo "Installing zsh..."
        sudo apt-get update
        sudo apt-get install -y zsh
    else
        echo "zsh is already installed"
    fi
}

install_prezto() {
    local prezto_dir="${ZDOTDIR:-$HOME}/.zprezto"

    if [[ ! -d "$prezto_dir" ]]; then
        echo "Installing Prezto..."
        git clone --recursive https://github.com/sorin-ionescu/prezto.git "$prezto_dir"

        # Create zsh config files
        setopt EXTENDED_GLOB 2>/dev/null || true
        for rcfile in "${prezto_dir}"/runcoms/^README.md(.N); do
            ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}" 2>/dev/null || true
        done

        # Manually link the files if the above didn't work
        ln -sf "$prezto_dir/runcoms/zlogin" "$HOME/.zlogin" 2>/dev/null || true
        ln -sf "$prezto_dir/runcoms/zlogout" "$HOME/.zlogout" 2>/dev/null || true
        ln -sf "$prezto_dir/runcoms/zpreztorc" "$HOME/.zpreztorc" 2>/dev/null || true
        ln -sf "$prezto_dir/runcoms/zprofile" "$HOME/.zprofile" 2>/dev/null || true
        ln -sf "$prezto_dir/runcoms/zshenv" "$HOME/.zshenv" 2>/dev/null || true
        ln -sf "$prezto_dir/runcoms/zshrc" "$HOME/.zshrc" 2>/dev/null || true
    else
        echo "Prezto is already installed"
    fi

    # Configure Prezto
    configure_prezto

    # Install zsh-z
    install_zsh_z

    # Configure mise in zshrc
    configure_zshrc_mise
}

install_powerline_fonts() {
    echo "Installing Powerline fonts..."
    sudo apt-get update
    sudo apt-get install -y fonts-powerline

    # Also install Nerd Fonts for better compatibility
    local fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"

    if [[ ! -f "$fonts_dir/MesloLGS NF Regular.ttf" ]]; then
        echo "Installing MesloLGS Nerd Font..."
        cd /tmp
        curl -fLo "MesloLGS NF Regular.ttf" \
            "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" 2>/dev/null || true
        curl -fLo "MesloLGS NF Bold.ttf" \
            "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf" 2>/dev/null || true
        curl -fLo "MesloLGS NF Italic.ttf" \
            "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf" 2>/dev/null || true
        curl -fLo "MesloLGS NF Bold Italic.ttf" \
            "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf" 2>/dev/null || true

        mv MesloLGS*.ttf "$fonts_dir/" 2>/dev/null || true
        fc-cache -fv
    fi
}

install_chrome() {
    if ! command -v google-chrome &> /dev/null; then
        echo "Installing Google Chrome..."
        wget -q -O /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
        sudo apt-get install -y /tmp/google-chrome.deb
        rm /tmp/google-chrome.deb
    else
        echo "Google Chrome is already installed"
    fi
}

install_mise() {
    if ! command -v mise &> /dev/null; then
        echo "Installing mise..."
        curl https://mise.run | sh

        # Add mise to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "mise is already installed"
    fi
}

install_languages() {
    # Ensure mise is in PATH
    export PATH="$HOME/.local/bin:$PATH"

    if command -v mise &> /dev/null; then
        echo "Installing latest Python via mise..."
        mise use --global python@latest

        echo "Installing latest Node.js via mise..."
        mise use --global node@latest

        # Install CLIs now that Node.js is available
        eval "$(mise activate bash)"

        echo "Installing Gemini CLI..."
        npm install -g @google/gemini-cli 2>/dev/null || echo "Gemini CLI may need manual installation"

        echo "Installing Claude Code CLI..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null || echo "Claude Code CLI may need manual installation"
    else
        echo "mise not found, skipping language installation"
    fi
}

install_vscode() {
    if ! command -v code &> /dev/null; then
        echo "Installing VS Code..."
        sudo apt-get update
        sudo apt-get install -y wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f /tmp/packages.microsoft.gpg
        sudo apt-get update
        sudo apt-get install -y code
    else
        echo "VS Code is already installed"
    fi
}

install_terminator() {
    if ! command -v terminator &> /dev/null; then
        echo "Installing Terminator..."
        sudo apt-get update
        sudo apt-get install -y terminator
    else
        echo "Terminator is already installed"
    fi

    # Configure Terminator with Solarized Dark theme
    local terminator_config_dir="$HOME/.config/terminator"
    mkdir -p "$terminator_config_dir"

    cat > "$terminator_config_dir/config" << 'EOF'
[global_config]
  title_transmit_bg_color = "#d30102"
  focus = system

[keybindings]

[profiles]
  [[default]]
    background_color = "#002b36"
    cursor_color = "#839496"
    foreground_color = "#839496"
    palette = "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#002b36:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3"
    use_system_font = False
    font = MesloLGS NF 11
    scrollback_lines = 10000

[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = Terminal
      parent = window0
      profile = default

[plugins]
EOF

    echo "Terminator configured with Solarized Dark theme"
}

set_default_shell() {
    local zsh_path=$(which zsh)

    if [[ "$SHELL" != "$zsh_path" ]]; then
        echo "Setting zsh as default shell..."
        chsh -s "$zsh_path"
    else
        echo "zsh is already the default shell"
    fi
}
