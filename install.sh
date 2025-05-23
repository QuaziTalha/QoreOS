#!/bin/bash

set -e

# Temporary build directory
TEMP_DIR=$(mktemp -d)
FINAL_DIR="$HOME/qoreos"

cleanup() {
    echo "\n⚠️ Error occurred. Cleaning up..."
    sudo systemctl disable ly >/dev/null 2>&1 || true
    rm -rf "$TEMP_DIR"
    exit 1
}

trap cleanup ERR

# Dependencies
sudo pacman -S --needed --noconfirm base-devel git xorg xorg-xinit libxft libxinerama freetype2 harfbuzz acpi alsa-utils unzip ncurses pam

# Install a Nerd Font (JetBrainsMono Nerd Font as example)
echo "Installing Nerd Font..."
mkdir -p "$HOME/.local/share/fonts"
curl -fLo "$HOME/.local/share/fonts/JetBrainsMono.zip" \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
cd "$HOME/.local/share/fonts"
unzip -o JetBrainsMono.zip -d JetBrainsMono
rm JetBrainsMono.zip
fc-cache -fv
cd - >/dev/null

# Clone and build suckless tools
build_suckless() {
    repo=$1
    echo "Installing $repo..."
    git clone https://git.suckless.org/$repo "$TEMP_DIR/$repo"

    # Apply Nerd Font in config.def.h if applicable
    if [ "$repo" == "st" ]; then
        echo "Applying JetBrainsMono Nerd Font in st config..."
        sed -i 's|char \\*font = \\".*\\";|char *font = \"JetBrainsMono Nerd Font:pixelsize=14:antialias=true:autohint=true\";|' "$TEMP_DIR/$repo/config.def.h"
    elif [ "$repo" == "dmenu" ]; then
        echo "Applying JetBrainsMono Nerd Font in dmenu config..."
        sed -i 's|#define FONT \\".*\\"|#define FONT \"JetBrainsMono Nerd Font:pixelsize=14\"|' "$TEMP_DIR/$repo/config.def.h" 2>/dev/null || true
    elif [ "$repo" == "dwm" ]; then
        echo "Applying JetBrainsMono Nerd Font in dwm config..."
        sed -i 's|static const char \\*fonts\\[] = {.*};|static const char *fonts[] = { \"JetBrainsMono Nerd Font:pixelsize=14\" };|' "$TEMP_DIR/$repo/config.def.h" 2>/dev/null || true
    fi

    cd "$TEMP_DIR/$repo"
    sudo make clean install
    cd - >/dev/null
}

build_suckless dwm
build_suckless dmenu
build_suckless st

# Install ly (display manager)
echo "Installing ly from package manager..."
sudo pacman -S --noconfirm ly
sudo systemctl enable ly

# Move sources to ~/qoreos for future use
mkdir -p "$FINAL_DIR"
mv "$TEMP_DIR"/* "$FINAL_DIR"/
rmdir "$TEMP_DIR"

# Create dwm-status.sh
cat << 'EOF' > "$HOME/.dwm-status.sh"
#!/bin/bash
while true; do
    VOL=$(amixer get Master | awk -F'[][]' '/%/ { print $2; exit }')
    BATT=$(acpi | awk '{print $4}' | tr -d ',')
    TIME=$(date '+%a %d %b %H:%M')
    xsetroot -name " $VOL |   $BATT |  $TIME"
    sleep 10
done
EOF
chmod +x "$HOME/.dwm-status.sh"

# Setup .xinitrc for dwm with status script
echo '#!/bin/sh' > "$HOME/.xinitrc"
echo '$HOME/.dwm-status.sh &' >> "$HOME/.xinitrc"
echo 'exec dwm' >> "$HOME/.xinitrc"
chmod +x "$HOME/.xinitrc"

echo "\n✅ dwm, dmenu, st, and ly installed successfully. Source code is in ~/qoreos."
echo "▶️ .xinitrc has been configured to launch dwm with status bar." 
echo "🎨 Nerd Font (JetBrainsMono) installed and applied to st, dmenu, and dwm with glyphs in status bar."
