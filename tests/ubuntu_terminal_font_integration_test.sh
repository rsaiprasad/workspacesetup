#!/usr/bin/env bash

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/workspacesetup-font-integration.XXXXXX")
trap 'rm -rf -- "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"

# shellcheck source=../scripts/ubuntu.sh
source "$REPO_DIR/scripts/ubuntu.sh"

# The CI image already provides these dependencies. Avoid modifying the runner
# while exercising the real pinned download, checksum, archive, and Fontconfig.
sudo() { return 0; }

install_powerline_fonts
meslo_nerd_font_mono_installed

for style in Regular Bold Italic BoldItalic; do
    details=$("$WORKSPACE_SETUP_FC_SCAN" --format='%{family[0]}|%{spacing}' \
        "$HOME/.local/share/fonts/MesloLGSNerdFontMono/MesloLGSNerdFontMono-${style}.ttf")
    [[ "$details" == "$MESLO_NERD_FONT_FAMILY|100" ]]
done

for codepoint in e0a0 e0b0 e0b2 276f; do
    details=$("$WORKSPACE_SETUP_FC_MATCH" --format='%{family[0]}|%{spacing}' \
        "$MESLO_NERD_FONT_FAMILY:charset=$codepoint")
    [[ "$details" == "$MESLO_NERD_FONT_FAMILY|100" ]]
done

echo "Ubuntu terminal font integration test passed"
