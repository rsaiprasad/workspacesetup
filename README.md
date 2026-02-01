# Workspace Setup

Automated workspace setup script for Ubuntu and macOS. Sets up a development environment with zsh, Prezto, and essential development tools.

## Features

- **Shell**: Zsh with Prezto framework
  - Paradox theme with long prompt format
  - Git integration enabled
  - zsh-z for directory jumping
  - Syntax highlighting and autosuggestions

- **Fonts**: Powerline/Nerd Fonts for theme compatibility

- **Tools**:
  - Git
  - Google Chrome
  - mise (for managing language runtimes)
  - Python (latest via mise)
  - Node.js (latest via mise)
  - VS Code with Cline extension
  - Gemini CLI
  - Claude Code CLI

- **Ubuntu Only**:
  - Terminator terminal with Solarized Dark theme

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/workspacesetup.git
cd workspacesetup
chmod +x setup.sh
./setup.sh
```

## Requirements

- Ubuntu 20.04+ or macOS 12+
- sudo access (for installing packages)
- Internet connection

## What Gets Installed

### Shell Setup
1. Zsh (if not already installed)
2. Prezto framework with:
   - Paradox theme
   - Long prompt format
   - Git module
   - zsh-z plugin
   - Syntax highlighting
   - Autosuggestions
   - History substring search

### Fonts
- Powerline fonts
- MesloLGS Nerd Font (for terminal theme compatibility)

### Development Tools
- **Git**: Version control
- **mise**: Runtime version manager (replaces asdf, nvm, pyenv)
- **Python**: Latest version via mise
- **Node.js**: LTS version via mise
- **VS Code**: Code editor with Cline extension

### CLI Tools
- **Gemini CLI**: Google's AI assistant
- **Claude Code CLI**: Anthropic's AI coding assistant

### Applications
- **Google Chrome**: Web browser
- **Terminator** (Ubuntu only): Terminal emulator with Solarized Dark theme

## Post-Installation

After running the setup script:

1. Log out and log back in for shell changes to take effect
2. Open a new terminal window
3. The Paradox theme should be active with the correct fonts

### Terminal Font Configuration

If you see broken characters in your prompt, set your terminal font to:
- **MesloLGS NF** or
- **Meslo LG Nerd Font**

### Manual CLI Installation

If the CLI tools didn't install during setup (due to Node.js not being in PATH), run:

```bash
# Activate mise first
eval "$(mise activate zsh)"

# Install CLIs
npm install -g @google/gemini-cli
npm install -g @anthropic-ai/claude-code
```

## Customization

### Prezto Configuration
Edit `~/.zpreztorc` to customize:
- Theme: Change `zstyle ':prezto:module:prompt' theme 'paradox'`
- Modules: Add/remove from `zstyle ':prezto:load' pmodule`

### Terminator Configuration (Ubuntu)
Edit `~/.config/terminator/config` to customize colors and settings.

## Troubleshooting

### Fonts not displaying correctly
```bash
# Ubuntu
fc-cache -fv

# macOS - fonts should auto-reload
```

### mise not found after install
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Prezto not loading
Ensure symlinks are correct:
```bash
ls -la ~/.zshrc ~/.zpreztorc ~/.zshenv
```

## License

MIT
