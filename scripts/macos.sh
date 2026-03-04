#!/bin/bash

# macOS-specific installation functions

# Ensure Homebrew is installed
ensure_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

install_git() {
    ensure_homebrew

    if ! command -v git &> /dev/null; then
        echo "Installing git..."
        brew install git
    else
        echo "git is already installed"
    fi
}

install_zsh() {
    # macOS comes with zsh, but we can install a newer version via Homebrew
    if ! command -v zsh &> /dev/null; then
        echo "Installing zsh..."
        ensure_homebrew
        brew install zsh
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
    ensure_homebrew

    echo "Installing Powerline fonts..."

    # Install via Homebrew cask
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask font-meslo-lg-nerd-font 2>/dev/null || brew install font-meslo-lg-nerd-font 2>/dev/null || true
    brew install --cask font-powerline-symbols 2>/dev/null || true

    # Manual installation of MesloLGS NF
    local fonts_dir="$HOME/Library/Fonts"
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
    fi

    echo "Powerline fonts installed"
}

install_chrome() {
    if [[ ! -d "/Applications/Google Chrome.app" ]]; then
        echo "Installing Google Chrome..."
        ensure_homebrew
        brew install --cask google-chrome
    else
        echo "Google Chrome is already installed"
    fi
}

install_obsidian() {
    if [[ ! -d "/Applications/Obsidian.app" ]]; then
        echo "Installing Obsidian..."
        ensure_homebrew
        brew install --cask obsidian
    else
        echo "Obsidian is already installed"
    fi
}

install_zoom() {
    if [[ ! -d "/Applications/zoom.us.app" ]]; then
        echo "Installing Zoom..."
        ensure_homebrew
        brew install --cask zoom
    else
        echo "Zoom is already installed"
    fi
}

install_opensuperwhisper() {
    if [[ ! -d "/Applications/OpenSuperWhisper.app" ]]; then
        echo "Installing OpenSuperWhisper..."
        ensure_homebrew
        brew install --cask opensuperwhisper
    else
        echo "OpenSuperWhisper is already installed"
    fi
}

install_iterm2() {
    if [[ ! -d "/Applications/iTerm.app" ]]; then
        echo "Installing iTerm2..."
        ensure_homebrew
        brew install --cask iterm2
        echo "Note: Set Solarized theme in iTerm2 > Preferences > Profiles > Colors"
    else
        echo "iTerm2 is already installed"
    fi
}

install_mise() {
    if ! command -v mise &> /dev/null; then
        echo "Installing mise..."
        ensure_homebrew
        brew install mise
    else
        echo "mise is already installed"
    fi
}

install_languages() {
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
    ensure_homebrew

    if ! command -v tmux &> /dev/null; then
        echo "Installing tmux..."
        brew install tmux
    else
        echo "tmux is already installed"
    fi

    # Configure Oh My Tmux
    configure_tmux
}

install_vscode() {
    if [[ ! -d "/Applications/Visual Studio Code.app" ]] && ! command -v code &> /dev/null; then
        echo "Installing VS Code..."
        ensure_homebrew
        brew install --cask visual-studio-code
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

set_default_shell() {
    local zsh_path=$(which zsh)

    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        echo "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        echo "Setting zsh as default shell..."
        chsh -s "$zsh_path"
    else
        echo "zsh is already the default shell"
    fi
}
