#!/usr/bin/env bash

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/workspacesetup-font-test.XXXXXX")
trap 'rm -rf -- "$TEST_ROOT"' EXIT

FAKE_BIN="$TEST_ROOT/fake-bin"
BAD_PATH_BIN="$TEST_ROOT/bad-path-bin"
FIXTURE_DIR="$TEST_ROOT/fixture"
FIXTURE_ARCHIVE="$TEST_ROOT/Meslo.tar.xz"
CURL_LOG="$TEST_ROOT/curl.log"
GSETTINGS_LOG="$TEST_ROOT/gsettings.log"
FONT_STATE="$TEST_ROOT/font.state"
USE_SYSTEM_FONT_STATE="$TEST_ROOT/use-system-font.state"
BAD_GSETTINGS_LOG="$TEST_ROOT/bad-gsettings.log"

mkdir -p "$FAKE_BIN" "$BAD_PATH_BIN" "$FIXTURE_DIR"

fixture_files=()
for style in Regular Bold Italic BoldItalic; do
    fixture_file="MesloLGSNerdFontMono-${style}.ttf"
    printf 'fixture-%s\n' "$style" > "$FIXTURE_DIR/$fixture_file"
    fixture_files+=("$fixture_file")
done
tar -cJf "$FIXTURE_ARCHIVE" -C "$FIXTURE_DIR" "${fixture_files[@]}"
FIXTURE_SHA256=$(sha256sum "$FIXTURE_ARCHIVE" | awk '{print $1}')

export FIXTURE_ARCHIVE CURL_LOG GSETTINGS_LOG FONT_STATE USE_SYSTEM_FONT_STATE

cat > "$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output=""
while (($#)); do
    case "$1" in
        --output)
            output="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
cp "$FIXTURE_ARCHIVE" "$output"
printf 'download\n' >> "$CURL_LOG"
EOF

cat > "$FAKE_BIN/fc-cache" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$FAKE_BIN/fc-match" <<'EOF'
#!/usr/bin/env bash
printf 'MesloLGS Nerd Font Mono|100'
EOF

cat > "$FAKE_BIN/fc-scan" <<'EOF'
#!/usr/bin/env bash
font_file="${@: -1}"
if grep -Fq 'corrupt' "$font_file"; then
    exit 1
fi
printf 'MesloLGS Nerd Font Mono|100'
EOF

cat > "$FAKE_BIN/gsettings" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$GSETTINGS_LOG"

case "$1" in
    list-schemas)
        if [[ "${GSETTINGS_NO_TERMINAL_SCHEMA:-0}" == "1" ]]; then
            printf '%s\n' org.gnome.desktop.interface
        else
            printf '%s\n' org.gnome.Terminal.ProfilesList org.gnome.desktop.interface
        fi
        ;;
    get)
        case "$2 $3" in
            'org.gnome.Terminal.ProfilesList default')
                printf "'test-profile'\n"
                ;;
            'org.gnome.desktop.interface monospace-font-name')
                printf "'Ubuntu Sans Mono 13'\n"
                ;;
            *' font')
                if [[ -f "$FONT_STATE" ]]; then
                    cat "$FONT_STATE"
                else
                    printf "'Monospace 12'\n"
                fi
                ;;
            *' use-system-font')
                if [[ -f "$USE_SYSTEM_FONT_STATE" ]]; then
                    cat "$USE_SYSTEM_FONT_STATE"
                else
                    printf 'true\n'
                fi
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    set)
        case "$3" in
            font)
                printf "'%s'\n" "$4" > "$FONT_STATE"
                ;;
            use-system-font)
                printf '%s\n' "$4" > "$USE_SYSTEM_FONT_STATE"
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    *)
        exit 1
        ;;
esac
EOF

cat > "$FAKE_BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$BAD_PATH_BIN/gsettings" <<EOF
#!/usr/bin/env bash
printf 'called\n' >> '$BAD_GSETTINGS_LOG'
exit 99
EOF

chmod +x "$FAKE_BIN"/* "$BAD_PATH_BIN/gsettings"

export PATH="$BAD_PATH_BIN:$FAKE_BIN:$PATH"
export HOME="$TEST_ROOT/home"

# Production defaults must use Ubuntu's system binaries even if Homebrew (or
# another toolchain) puts incompatible commands earlier in PATH.
(
    unset WORKSPACE_SETUP_FC_CACHE WORKSPACE_SETUP_FC_MATCH WORKSPACE_SETUP_FC_SCAN
    unset WORKSPACE_SETUP_GSETTINGS WORKSPACE_SETUP_SYSTEMCTL
    # shellcheck source=../scripts/ubuntu.sh
    source "$REPO_DIR/scripts/ubuntu.sh"
    [[ "$WORKSPACE_SETUP_FC_CACHE" == "/usr/bin/fc-cache" ]]
    [[ "$WORKSPACE_SETUP_FC_MATCH" == "/usr/bin/fc-match" ]]
    [[ "$WORKSPACE_SETUP_FC_SCAN" == "/usr/bin/fc-scan" ]]
    [[ "$WORKSPACE_SETUP_GSETTINGS" == "/usr/bin/gsettings" ]]
)

export WORKSPACE_SETUP_FC_CACHE="$FAKE_BIN/fc-cache"
export WORKSPACE_SETUP_FC_MATCH="$FAKE_BIN/fc-match"
export WORKSPACE_SETUP_FC_SCAN="$FAKE_BIN/fc-scan"
export WORKSPACE_SETUP_GSETTINGS="$FAKE_BIN/gsettings"
export WORKSPACE_SETUP_SYSTEMCTL="$FAKE_BIN/systemctl"

# shellcheck source=../scripts/ubuntu.sh
source "$REPO_DIR/scripts/ubuntu.sh"
MESLO_NERD_FONT_ARCHIVE_SHA256="$FIXTURE_SHA256"
sudo() { return 0; }

start_dir=$PWD
install_powerline_fonts
[[ "$PWD" == "$start_dir" ]]
meslo_nerd_font_mono_installed
[[ "$(wc -l < "$CURL_LOG")" == "1" ]]

for style in Regular Bold Italic BoldItalic; do
    test -s "$HOME/.local/share/fonts/MesloLGSNerdFontMono/MesloLGSNerdFontMono-${style}.ttf"
done

# A completed install is a no-op, while a missing face triggers a repair.
install_powerline_fonts
[[ "$(wc -l < "$CURL_LOG")" == "1" ]]
printf 'corrupt\n' \
    > "$HOME/.local/share/fonts/MesloLGSNerdFontMono/MesloLGSNerdFontMono-BoldItalic.ttf"
install_powerline_fonts
[[ "$(wc -l < "$CURL_LOG")" == "2" ]]

# A bad checksum must fail before any font files are installed.
export HOME="$TEST_ROOT/bad-checksum-home"
MESLO_NERD_FONT_ARCHIVE_SHA256=$(printf '0%.0s' {1..64})
if install_powerline_fonts; then
    echo "checksum failure was incorrectly accepted" >&2
    exit 1
fi
[[ ! -d "$HOME/.local/share/fonts/MesloLGSNerdFontMono" ]]

# Configure the default GNOME Terminal profile with the exact Mono family and
# preserve the current desktop font size. A fake PATH gsettings must not run.
export HOME="$TEST_ROOT/home"
MESLO_NERD_FONT_ARCHIVE_SHA256="$FIXTURE_SHA256"
export DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/test-session-bus'
export WAYLAND_DISPLAY='wayland-test'
rm -f "$FONT_STATE" "$USE_SYSTEM_FONT_STATE"
mkdir -p "$HOME/.config/terminator"
printf '[profiles]\n    font = MesloLGS NF 11\n' > "$HOME/.config/terminator/config"
unset UBUNTU_GNOME_TERMINAL_RESTART_REQUIRED
configure_ubuntu_terminal_font
grep -Fxq "'MesloLGS Nerd Font Mono 13'" "$FONT_STATE"
grep -Fxq 'false' "$USE_SYSTEM_FONT_STATE"
grep -Fxq '    font = MesloLGS Nerd Font Mono 11' "$HOME/.config/terminator/config"
[[ "${UBUNTU_GNOME_TERMINAL_RESTART_REQUIRED:-0}" == "1" ]]
[[ ! -e "$BAD_GSETTINGS_LOG" ]]
grep -Fq 'set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:test-profile/ font MesloLGS Nerd Font Mono 13' \
    "$GSETTINGS_LOG"
grep -Fq 'set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:test-profile/ use-system-font false' \
    "$GSETTINGS_LOG"

# An already-correct profile should not request another restart.
unset UBUNTU_GNOME_TERMINAL_RESTART_REQUIRED UBUNTU_TERMINAL_FONT_FILES_CHANGED
configure_ubuntu_terminal_font
[[ "${UBUNTU_GNOME_TERMINAL_RESTART_REQUIRED:-0}" == "0" ]]

# Font installation remains useful on headless Ubuntu, but GUI configuration
# must be skipped without a local display or while connected over SSH.
gsettings_calls_before=$(wc -l < "$GSETTINGS_LOG")
unset WAYLAND_DISPLAY DISPLAY
configure_ubuntu_terminal_font
[[ "$(wc -l < "$GSETTINGS_LOG")" == "$gsettings_calls_before" ]]
export DISPLAY=':0' SSH_CONNECTION='example'
configure_ubuntu_terminal_font
[[ "$(wc -l < "$GSETTINGS_LOG")" == "$gsettings_calls_before" ]]
unset SSH_CONNECTION

# A desktop without GNOME Terminal should be a clean no-op.
export GSETTINGS_NO_TERMINAL_SCHEMA=1
configure_ubuntu_terminal_font
[[ ! -e "$BAD_GSETTINGS_LOG" ]]
unset GSETTINGS_NO_TERMINAL_SCHEMA DISPLAY DBUS_SESSION_BUS_ADDRESS

# Never overwrite a user-selected Terminator font.
printf '[profiles]\n    font = Custom Mono 14\n' > "$HOME/.config/terminator/config"
migrate_terminator_font_name
grep -Fxq '    font = Custom Mono 14' "$HOME/.config/terminator/config"

echo "Ubuntu terminal font tests passed"
