# Workspace Setup

Automated workspace setup script for Ubuntu, macOS, and Amazon Linux 2023. Sets up a development environment with zsh, Prezto, persistent tmux sessions, and essential development tools.

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
  - Obsidian
  - Zoom
  - mise (for managing language runtimes)
  - Python 3.12 (via mise)
  - Node.js 24 (via mise)
  - Bun (via mise)
  - tmux with Oh My Tmux
  - VS Code with extensions bundle
  - Gemini CLI
  - Claude Code CLI
  - OpenAI Codex CLI with persistent per-project tmux sessions

- **macOS Only**:
  - OpenSuperWhisper
  - iTerm2 terminal

- **Ubuntu Only**:
  - Terminator terminal with Solarized Dark theme

- **Amazon Linux 2023 Notes**:
  - Uses dnf package manager
  - Obsidian requires manual AppImage download (no RPM available)

## Quick Start

```bash
git clone https://github.com/rsaiprasad/workspacesetup.git
cd workspacesetup
chmod +x setup.sh
./setup.sh
```

## Requirements

- Ubuntu 20.04+ or macOS 12+ or Amazon Linux 2023
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
- **tmux**: Persistent terminal sessions with Oh My Tmux
- **VS Code**: Code editor with Cline extension

### CLI Tools
- **Gemini CLI**: Google's AI assistant
- **Claude Code CLI**: Anthropic's AI coding assistant
- **Codex CLI**: OpenAI's coding assistant, wrapped in tmux for interactive use

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

# Install Codex CLI on macOS or Linux
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

## Codex Sessions with tmux

In the configured zsh shell, interactive `codex` commands automatically create or attach to a tmux session named after the current Git repository, such as `codex-stockstudy-123456789`. The numeric suffix comes from the full repository path, so repositories with the same directory name remain separate. The same session is available from a local terminal or over SSH.

```bash
cd ~/workspace/stockstudy
codex
```

To detach without stopping Codex, press `Ctrl-b`, then `d`. From another terminal or SSH connection, return to the same repository and run `codex` again. The active session is handed over to the new terminal.

Useful commands:

```bash
# List active tmux sessions
tmux ls

# Attach explicitly and detach its old client (copy the name from `tmux ls`)
tmux attach -d -t codex-stockstudy-123456789

# Start another Codex session for the same repository
CODEX_TMUX_SESSION=codex-stockstudy-2 codex

# Run Codex without the tmux wrapper
CODEX_TMUX_BYPASS=1 codex
```

Different repositories automatically receive different session names. Inside tmux, press `Ctrl-b`, then `c` to open another window; running `codex` there starts another Codex process without nesting tmux. When attaching to an existing session, that session's running Codex process is kept and new CLI arguments are ignored.

Non-TTY commands, such as normal scripts and CI jobs, run Codex directly. The setup does not force every SSH login into tmux, and it does not change project-specific model routing or instructions.

tmux sessions survive terminal closures and SSH disconnects, but not a machine reboot. After restarting, return to the project and resume the most recent saved Codex conversation:

```bash
codex resume --last
```

See the [official Codex CLI guide](https://developers.openai.com/codex/cli/) and [CLI reference](https://developers.openai.com/codex/cli/reference/).

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
