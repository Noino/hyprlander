#!/usr/bin/env bash

# sddm-sequoia theme
THEME_DIR=/usr/share/sddm/themes/sequoia_2
THEME_VERSION=1.6.1
THEME_URL=https://codeberg.org/minMelody/sddm-sequoia

CURRENT_REMOTE=$(sudo git -C "$THEME_DIR" remote get-url origin 2>/dev/null)

if [[ "$CURRENT_REMOTE" == "$THEME_URL" ]]; then
    sudo git -C "$THEME_DIR" fetch --tags
    sudo git -C "$THEME_DIR" checkout "$THEME_VERSION"
else
    sudo rm -rf "$THEME_DIR"
    sudo git clone --branch "$THEME_VERSION" --depth 1 -c advice.detachedHead=false "$THEME_URL" "$THEME_DIR"
fi

# wallpaper
sudo cp "${src_dir}/assets/sddm-wallpaper.png" "$THEME_DIR/backgrounds/sddm-wallpaper.png"
sudo tee "$THEME_DIR/theme.conf.user" > /dev/null <<'EOF'
[General]
wallpaper=backgrounds/sddm-wallpaper.png
EOF

# set theme
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<'EOF'
[Theme]
Current=sequoia_2
EOF

# set default session
sudo tee /etc/sddm.conf.d/session.conf > /dev/null <<'EOF'
[Users]
DefaultSession=hyprland-uwsm.desktop
EOF
