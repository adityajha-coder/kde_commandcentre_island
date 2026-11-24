#!/bin/sh
# Installs KDE Island into ~/.config/quickshell/kde_commandcentre_island and creates a default config.
# Usage: ./install.sh [--autostart]
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DEST="$CFG/quickshell/kde_commandcentre_island"

mkdir -p "$DEST" "$CFG/kde_commandcentre_island"
cp -r "$SRC"/shell.qml "$SRC"/ConfigStore.qml "$SRC"/Island.qml \
      "$SRC"/components "$SRC"/services "$SRC"/scripts "$SRC"/assets "$DEST"/

if [ ! -f "$CFG/kde_commandcentre_island/config.json" ]; then
    cp "$SRC/config.default.json" "$CFG/kde_commandcentre_island/config.json"
    echo "Created $CFG/kde-island/config.json"
fi

if [ "$1" = "--autostart" ]; then
    mkdir -p "$CFG/autostart"
    cat > "$CFG/autostart/kde-island.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=KDE Island
Exec=quickshell -c kde-island
X-KDE-autostart-after=panel
EOF
    echo "Autostart entry written."
fi

echo "Installed to $DEST"
echo "Run it with:  quickshell -c kde-island"
