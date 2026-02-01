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
        echo "Installing latest Python via mise..."
        mise use --global python@latest

        echo "Installing latest Node.js via mise..."
        mise use --global node@lts

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
    if [[ ! -d "/Applications/Visual Studio Code.app" ]] && ! command -v code &> /dev/null; then
        echo "Installing VS Code..."
        ensure_homebrew
        brew install --cask visual-studio-code
    else
        echo "VS Code is already installed"
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
