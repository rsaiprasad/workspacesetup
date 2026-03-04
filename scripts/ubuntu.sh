#!/bin/bash

# Ubuntu-specific installation functions

install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."

        # Install dependencies required by Homebrew
        sudo apt-get update
        sudo apt-get install -y build-essential procps curl file git

        # Install Homebrew
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for current session
        if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
    else
        echo "Homebrew is already installed"
    fi

    # Add Homebrew to shell configuration if not already present
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q "linuxbrew" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# Homebrew" >> "$zshrc"
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$zshrc"
        echo "Homebrew added to .zshrc"
    fi
}

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

        # Create zsh config symlinks
        ln -sf "$prezto_dir/runcoms/zlogin" "$HOME/.zlogin"
        ln -sf "$prezto_dir/runcoms/zlogout" "$HOME/.zlogout"
        ln -sf "$prezto_dir/runcoms/zpreztorc" "$HOME/.zpreztorc"
        ln -sf "$prezto_dir/runcoms/zprofile" "$HOME/.zprofile"
        ln -sf "$prezto_dir/runcoms/zshenv" "$HOME/.zshenv"
        ln -sf "$prezto_dir/runcoms/zshrc" "$HOME/.zshrc"
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

install_obsidian() {
    if ! command -v obsidian &> /dev/null; then
        echo "Installing Obsidian..."
        wget -q -O /tmp/obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/latest/download/obsidian_amd64.deb"
        sudo apt-get install -y /tmp/obsidian.deb
        rm /tmp/obsidian.deb
    else
        echo "Obsidian is already installed"
    fi
}

install_zoom() {
    if ! command -v zoom &> /dev/null; then
        echo "Installing Zoom..."
        wget -q -O /tmp/zoom.deb "https://zoom.us/client/latest/zoom_amd64.deb"
        sudo apt-get install -y /tmp/zoom.deb
        rm /tmp/zoom.deb
    else
        echo "Zoom is already installed"
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

    # Install libatomic1 - required by Node.js
    echo "Installing Node.js dependencies..."
    sudo apt-get install -y libatomic1

    if command -v mise &> /dev/null; then
        echo "Installing Python 3.12 via mise..."
        mise use --global python@3.12

        echo "Installing Node.js 24 via mise..."
        mise use --global node@24

        echo "Installing Bun via mise..."
        mise use --global bun@latest

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

install_tmux() {
    if ! command -v tmux &> /dev/null; then
        echo "Installing tmux..."
        sudo apt-get update
        sudo apt-get install -y tmux
    else
        echo "tmux is already installed"
    fi

    # Install Oh My Tmux dependencies (awk, perl, grep, sed are usually present)
    sudo apt-get install -y perl 2>/dev/null || true

    # Install clipboard support for tmux copy-to-clipboard (xsel, xclip, or wl-copy)
    sudo apt-get install -y xsel xclip wl-clipboard 2>/dev/null || true

    # Configure Oh My Tmux
    configure_tmux
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

install_vscode_extensions() {
    if command -v code &> /dev/null; then
        echo "Installing VS Code extensions..."
        code --install-extension amazonwebservices-aisolutionsarchitecture.bedrock-vscode-playground
        code --install-extension amazonwebservices.amazon-q-vscode
        code --install-extension amazonwebservices.aws-toolkit-vscode
        code --install-extension amazonwebservices.codewhisperer-for-command-line-companion
        code --install-extension amzn.amzn-pippin
        code --install-extension amzn.vscode-crux
        code --install-extension apollographql.vscode-apollo
        code --install-extension asbx.amzn-cline
        code --install-extension aws-scripting-guy.cform
        code --install-extension bierner.markdown-mermaid
        code --install-extension charliermarsh.ruff
        code --install-extension esbenp.prettier-vscode
        code --install-extension fwcd.kotlin
        code --install-extension github.remotehub
        code --install-extension github.vscode-pull-request-github
        code --install-extension marklel.vscode-brazil
        code --install-extension mathiasfrohlich.kotlin
        code --install-extension mechatroner.rainbow-csv
        code --install-extension ms-azuretools.vscode-containers
        code --install-extension ms-python.black-formatter
        code --install-extension ms-python.debugpy
        code --install-extension ms-python.python
        code --install-extension ms-python.vscode-pylance
        code --install-extension ms-python.vscode-python-envs
        code --install-extension ms-toolsai.jupyter
        code --install-extension ms-toolsai.jupyter-keymap
        code --install-extension ms-toolsai.jupyter-renderers
        code --install-extension ms-toolsai.vscode-jupyter-cell-tags
        code --install-extension ms-toolsai.vscode-jupyter-slideshow
        code --install-extension ms-vscode-remote.remote-containers
        code --install-extension ms-vscode-remote.remote-ssh
        code --install-extension ms-vscode-remote.remote-ssh-edit
        code --install-extension ms-vscode.azure-repos
        code --install-extension ms-vscode.remote-explorer
        code --install-extension ms-vscode.remote-repositories
        code --install-extension mtxr.sqltools
        code --install-extension mtxr.sqltools-driver-mysql
        code --install-extension rangav.vscode-thunder-client
        code --install-extension redhat.vscode-yaml
        code --install-extension syler.sass-indented
        code --install-extension vscjava.vscode-gradle
        code --install-extension zeshuaro.vscode-python-poetry
    else
        echo "VS Code not found, skipping extensions installation"
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
