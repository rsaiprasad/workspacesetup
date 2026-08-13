#!/bin/bash

# Ubuntu-specific installation functions

MESLO_NERD_FONT_VERSION="3.5.0"
MESLO_NERD_FONT_ARCHIVE_SHA256="24cfe8148aeb600891f1d81180e77ecc967a814cde75dc7e63ec5bc2b0ab3eef"
MESLO_NERD_FONT_FAMILY="MesloLGS Nerd Font Mono"

WORKSPACE_SETUP_FC_CACHE="${WORKSPACE_SETUP_FC_CACHE:-/usr/bin/fc-cache}"
WORKSPACE_SETUP_FC_MATCH="${WORKSPACE_SETUP_FC_MATCH:-/usr/bin/fc-match}"
WORKSPACE_SETUP_FC_SCAN="${WORKSPACE_SETUP_FC_SCAN:-/usr/bin/fc-scan}"
WORKSPACE_SETUP_GSETTINGS="${WORKSPACE_SETUP_GSETTINGS:-/usr/bin/gsettings}"
WORKSPACE_SETUP_SYSTEMCTL="${WORKSPACE_SETUP_SYSTEMCTL:-/usr/bin/systemctl}"

meslo_nerd_font_mono_installed() {
    local fonts_dir="$HOME/.local/share/fonts/MesloLGSNerdFontMono"
    local font_details
    local codepoint
    local style

    [[ -x "$WORKSPACE_SETUP_FC_MATCH" && -x "$WORKSPACE_SETUP_FC_SCAN" ]] || return 1

    for style in Regular Bold Italic BoldItalic; do
        [[ -s "$fonts_dir/MesloLGSNerdFontMono-${style}.ttf" ]] || return 1
        font_details=$("$WORKSPACE_SETUP_FC_SCAN" --format='%{family[0]}|%{spacing}' \
            "$fonts_dir/MesloLGSNerdFontMono-${style}.ttf") || return 1
        [[ "$font_details" == "$MESLO_NERD_FONT_FAMILY|100" ]] || return 1
    done

    for codepoint in e0a0 e0b0 e0b2 276f; do
        font_details=$("$WORKSPACE_SETUP_FC_MATCH" --format='%{family[0]}|%{spacing}' \
            "$MESLO_NERD_FONT_FAMILY:charset=$codepoint") || return 1
        [[ "$font_details" == "$MESLO_NERD_FONT_FAMILY|100" ]] || return 1
    done
}

migrate_terminator_font_name() {
    local terminator_config="$HOME/.config/terminator/config"

    if [[ -f "$terminator_config" ]] && \
       grep -Fqx '    font = MesloLGS NF 11' "$terminator_config"; then
        sed -i 's/^    font = MesloLGS NF 11$/    font = MesloLGS Nerd Font Mono 11/' \
            "$terminator_config"
        echo "Terminator font migrated to $MESLO_NERD_FONT_FAMILY"
    fi
}

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

install_gh() {
    if ! command -v gh &> /dev/null; then
        echo "Installing GitHub CLI..."
        sudo apt-get update
        sudo apt-get install -y gh || {
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y gh
        }
    else
        echo "GitHub CLI is already installed"
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
    local fonts_dir="$HOME/.local/share/fonts/MesloLGSNerdFontMono"
    local archive_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${MESLO_NERD_FONT_VERSION}/Meslo.tar.xz"
    local staging_dir
    local temp_dir
    local style

    if meslo_nerd_font_mono_installed; then
        echo "$MESLO_NERD_FONT_FAMILY is already installed"
        return
    fi

    echo "Installing $MESLO_NERD_FONT_FAMILY v${MESLO_NERD_FONT_VERSION}..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl fontconfig xz-utils

    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/meslo-nerd-font.XXXXXX")
    if ! (
        set -e
        trap 'rm -rf -- "$temp_dir"' EXIT

        curl --fail --location --retry 3 \
            --output "$temp_dir/Meslo.tar.xz" "$archive_url" || exit 1
        printf '%s  %s\n' "$MESLO_NERD_FONT_ARCHIVE_SHA256" "$temp_dir/Meslo.tar.xz" \
            | sha256sum --check --status || exit 1

        staging_dir="$temp_dir/install"
        mkdir -p "$staging_dir" || exit 1
        for style in Regular Bold Italic BoldItalic; do
            tar -xf "$temp_dir/Meslo.tar.xz" -C "$temp_dir" \
                "MesloLGSNerdFontMono-${style}.ttf" || exit 1
            install -m 0644 "$temp_dir/MesloLGSNerdFontMono-${style}.ttf" \
                "$staging_dir/" || exit 1
        done

        # Only replace the installed set after every face has downloaded and
        # extracted successfully, so a failed repair leaves the old set intact.
        mkdir -p "$fonts_dir" || exit 1
        install -m 0644 "$staging_dir"/*.ttf "$fonts_dir/" || exit 1
    ); then
        echo "Failed to download or install $MESLO_NERD_FONT_FAMILY" >&2
        return 1
    fi

    "$WORKSPACE_SETUP_FC_CACHE" -f "$HOME/.local/share/fonts"
    if ! meslo_nerd_font_mono_installed; then
        echo "Failed to install the exact font family: $MESLO_NERD_FONT_FAMILY" >&2
        return 1
    fi

    UBUNTU_TERMINAL_FONT_FILES_CHANGED=1
    echo "$MESLO_NERD_FONT_FAMILY installed and verified"
}

configure_ubuntu_terminal_font() {
    local current_font
    local current_use_system_font
    local font_size="12"
    local profile_id
    local profile_schema
    local configured_font
    local profile_changed=0

    if ! meslo_nerd_font_mono_installed; then
        install_powerline_fonts || return 1
    fi

    # Migrate only the exact legacy value written by older versions of this
    # repository; leave user-selected Terminator fonts untouched.
    migrate_terminator_font_name

    if [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
        echo "SSH session detected; skipping GNOME Terminal configuration"
        return
    fi

    if [[ ! -x "$WORKSPACE_SETUP_GSETTINGS" ]] || [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || \
       [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        echo "Local GNOME desktop session not detected; skipping GNOME Terminal configuration"
        return
    fi

    if ! "$WORKSPACE_SETUP_GSETTINGS" list-schemas | grep -Fxq 'org.gnome.Terminal.ProfilesList'; then
        echo "GNOME Terminal is not installed; skipping its profile configuration"
        return
    fi

    profile_id=$("$WORKSPACE_SETUP_GSETTINGS" get org.gnome.Terminal.ProfilesList default | tr -d "'")
    if [[ -z "$profile_id" ]]; then
        echo "GNOME Terminal has no default profile; skipping its profile configuration"
        return
    fi

    profile_schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/"
    current_font=$("$WORKSPACE_SETUP_GSETTINGS" get "$profile_schema" font | tr -d "'")
    current_use_system_font=$("$WORKSPACE_SETUP_GSETTINGS" get "$profile_schema" use-system-font)

    if [[ "$current_use_system_font" == "true" ]] && \
       "$WORKSPACE_SETUP_GSETTINGS" list-schemas | grep -Fxq 'org.gnome.desktop.interface'; then
        current_font=$("$WORKSPACE_SETUP_GSETTINGS" get \
            org.gnome.desktop.interface monospace-font-name | tr -d "'")
    fi
    if [[ "$current_font" =~ ([0-9]+([.][0-9]+)?)$ ]]; then
        font_size="${BASH_REMATCH[1]}"
    fi
    configured_font="$MESLO_NERD_FONT_FAMILY $font_size"

    if [[ "$current_font" != "$configured_font" || "$current_use_system_font" != "false" ]]; then
        profile_changed=1
    fi

    "$WORKSPACE_SETUP_GSETTINGS" set "$profile_schema" font "$configured_font"
    "$WORKSPACE_SETUP_GSETTINGS" set "$profile_schema" use-system-font false

    if [[ "$("$WORKSPACE_SETUP_GSETTINGS" get "$profile_schema" font)" != "'$configured_font'" ]] || \
       [[ "$("$WORKSPACE_SETUP_GSETTINGS" get "$profile_schema" use-system-font)" != "false" ]]; then
        echo "Failed to configure the GNOME Terminal font" >&2
        return 1
    fi

    echo "GNOME Terminal default profile now uses $configured_font"
    if [[ "${UBUNTU_TERMINAL_FONT_FILES_CHANGED:-0}" == "1" || "$profile_changed" == "1" ]] && \
       "$WORKSPACE_SETUP_SYSTEMCTL" --user --quiet is-active gnome-terminal-server.service 2>/dev/null; then
        UBUNTU_GNOME_TERMINAL_RESTART_REQUIRED=1
        echo "IMPORTANT: GNOME Terminal is already running. Save your terminal work,"
        echo "close every GNOME Terminal window, and relaunch it to load the new font."
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

install_gnupg() {
    if ! command -v gpg &> /dev/null; then
        echo "Installing GnuPG..."
        sudo apt-get update
        sudo apt-get install -y gnupg
    else
        echo "GnuPG is already installed"
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
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v mise &> /dev/null; then
        echo "mise not found, skipping language installation"
        return
    fi

    dpkg -s libatomic1 &>/dev/null || { echo "Installing Node.js dependencies..."; sudo apt-get install -y libatomic1; }

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
    font = MesloLGS Nerd Font Mono 11
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
