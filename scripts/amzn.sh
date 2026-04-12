#!/bin/bash

# Amazon Linux 2023-specific installation functions (dnf-based)

install_git() {
    if ! command -v git &> /dev/null; then
        echo "Installing git..."
        sudo dnf install -y git
    else
        echo "git is already installed"
    fi
}

install_gh() {
    if ! command -v gh &> /dev/null; then
        echo "Installing GitHub CLI..."
        sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
        sudo dnf install -y gh 2>/dev/null || echo "GitHub CLI may need manual installation"
    else
        echo "GitHub CLI is already installed"
    fi
}

install_zsh() {
    if ! command -v zsh &> /dev/null; then
        echo "Installing zsh..."
        sudo dnf install -y zsh
    else
        echo "zsh is already installed"
    fi
}

install_prezto() {
    local prezto_dir="${ZDOTDIR:-$HOME}/.zprezto"

    if [[ ! -d "$prezto_dir" ]]; then
        echo "Installing Prezto..."
        git clone --recursive https://github.com/sorin-ionescu/prezto.git "$prezto_dir"

        ln -sf "$prezto_dir/runcoms/zlogin" "$HOME/.zlogin"
        ln -sf "$prezto_dir/runcoms/zlogout" "$HOME/.zlogout"
        ln -sf "$prezto_dir/runcoms/zpreztorc" "$HOME/.zpreztorc"
        ln -sf "$prezto_dir/runcoms/zprofile" "$HOME/.zprofile"
        ln -sf "$prezto_dir/runcoms/zshenv" "$HOME/.zshenv"
        ln -sf "$prezto_dir/runcoms/zshrc" "$HOME/.zshrc"
    else
        echo "Prezto is already installed"
    fi

    configure_prezto
    install_zsh_z
    configure_zshrc_mise
}

install_powerline_fonts() {
    local fonts_dir="$HOME/.local/share/fonts"

    if [[ -f "$fonts_dir/MesloLGS NF Regular.ttf" ]]; then
        echo "Powerline fonts already installed"
        return
    fi

    echo "Installing Powerline fonts..."
    mkdir -p "$fonts_dir"
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
    fc-cache -fv 2>/dev/null || true
}

install_chrome() {
    if ! command -v google-chrome-stable &> /dev/null && ! command -v google-chrome &> /dev/null; then
        echo "Installing Google Chrome..."
        sudo dnf install -y \
            "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" \
            2>/dev/null || echo "Chrome installation failed — may need manual install on headless systems"
    else
        echo "Google Chrome is already installed"
    fi
}

install_obsidian() {
    echo "Obsidian: no RPM available — download AppImage from https://obsidian.md/download"
}

install_zoom() {
    if ! command -v zoom &> /dev/null; then
        echo "Installing Zoom..."
        sudo dnf install -y \
            "https://zoom.us/client/latest/zoom_x86_64.rpm" \
            2>/dev/null || echo "Zoom installation failed — may need manual install on headless systems"
    else
        echo "Zoom is already installed"
    fi
}

install_mise() {
    if ! command -v mise &> /dev/null; then
        echo "Installing mise..."
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "mise is already installed"
    fi
}

install_languages() {
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v mise &> /dev/null; then
        echo "mise not found, skipping language installation"
        return
    fi

    # Node.js may need libatomic; gpg-agent (gnupg2) needed for mise to verify downloads
    rpm -q libatomic &>/dev/null || sudo dnf install -y libatomic 2>/dev/null || true
    rpm -q gnupg2 &>/dev/null || sudo dnf install -y gnupg2 2>/dev/null || true

    mise ls --global python 2>/dev/null | grep -q "3.12" || { echo "Installing Python 3.12 via mise..."; mise use --global python@3.12; }
    mise ls --global node 2>/dev/null | grep -q "24" || { echo "Installing Node.js 24 via mise..."; mise use --global node@24; }
    mise ls --global bun 2>/dev/null | grep -q "bun" || { echo "Installing Bun via mise..."; mise use --global bun@latest; }

    eval "$(mise activate bash)"

    command -v gemini &>/dev/null || { echo "Installing Gemini CLI..."; npm install -g @google/gemini-cli 2>/dev/null || echo "Gemini CLI may need manual installation"; }
    command -v claude &>/dev/null || { echo "Installing Claude Code CLI..."; npm install -g @anthropic-ai/claude-code 2>/dev/null || echo "Claude Code CLI may need manual installation"; }
}

install_tmux() {
    if ! command -v tmux &> /dev/null; then
        echo "Installing tmux..."
        sudo dnf install -y tmux
    else
        echo "tmux is already installed"
    fi

    sudo dnf install -y perl 2>/dev/null || true

    configure_tmux
}

install_vscode() {
    if ! command -v code &> /dev/null; then
        echo "Installing VS Code..."
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        cat <<REPO | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
        sudo dnf install -y code
    else
        echo "VS Code is already installed"
    fi
}

install_vscode_extensions() {
    if command -v code &> /dev/null; then
        _load_vscode_extensions
        echo "Installing VS Code extensions (skipping already installed)..."
        local exts=(
            amazonwebservices-aisolutionsarchitecture.bedrock-vscode-playground
            amazonwebservices.amazon-q-vscode
            amazonwebservices.aws-toolkit-vscode
            amzn.amzn-pippin
            apollographql.vscode-apollo
            asbx.amzn-cline
            aws-scripting-guy.cform
            bierner.markdown-mermaid
            charliermarsh.ruff
            esbenp.prettier-vscode
            fwcd.kotlin
            github.remotehub
            github.vscode-pull-request-github
            marklel.vscode-brazil
            mathiasfrohlich.kotlin
            mechatroner.rainbow-csv
            ms-azuretools.vscode-containers
            ms-python.black-formatter
            ms-python.debugpy
            ms-python.python
            ms-python.vscode-pylance
            ms-python.vscode-python-envs
            ms-toolsai.jupyter
            ms-toolsai.jupyter-keymap
            ms-toolsai.jupyter-renderers
            ms-toolsai.vscode-jupyter-cell-tags
            ms-toolsai.vscode-jupyter-slideshow
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.azure-repos
            ms-vscode.remote-explorer
            ms-vscode.remote-repositories
            mtxr.sqltools
            mtxr.sqltools-driver-mysql
            rangav.vscode-thunder-client
            redhat.vscode-yaml
            syler.sass-indented
            vscjava.vscode-gradle
            zeshuaro.vscode-python-poetry
        )
        for ext in "${exts[@]}"; do
            install_vscode_ext "$ext"
        done
    else
        echo "VS Code not found, skipping extensions installation"
    fi
}

set_default_shell() {
    local zsh_path
    zsh_path=$(which zsh)

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
