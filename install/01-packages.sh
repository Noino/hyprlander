#!/usr/bin/env bash

command -v yay &>/dev/null || { sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si; yay -Syy yay-bin; }

# install stuffs if needed
yay -Sq --needed \
 adobe-source-code-pro-fonts\
 archlinux-xdg-menu\
 bc\
 blueman\
 bluez-utils\
 bluez\
 brightnessctl\
 btop\
 cliphist\
 curl\
 fastfetch\
 ghostty\
 go\
 grim\
 gvfs-mtp\
 gvfs\
 hypridle\
 hyprland\
 hyprlock\
 hyprpaper\
 hyprpicker\
 hyprpolkitagent\
 imagemagick\
 jq\
 kvantum\
 libspng\
 mousepad\
 mpv-mpris\
 mpv\
 neovim\
 network-manager-applet\
 noto-fonts-emoji\
 noto-fonts\
 npm\
 nvtop\
 nwg-displays\
 nwg-look\
 otf-font-awesome\
 pacman-contrib\
 pamixer\
 pavucontrol\
 pipewire-alsa\
 pipewire-audio\
 pipewire-pulse\
 pipewire\
 playerctl\
 power-profiles-daemon\
 qalculate-gtk\
 qt5ct\
 qt6-5compat\
 qt6-declarative\
 qt6-svg\
 qt6ct\
 ripgrep\
 sddm\
 slurp\
 sof-firmware\
 swaync\
 ttf-droid\
 ttf-fantasque-nerd\
 ttf-fira-code\
 ttf-jetbrains-mono-nerd\
 ttf-jetbrains-mono\
 ttf-victor-mono\
 umockdev\
 unzip\
 waybar\
 wezterm\
 wget\
 wireplumber\
 wl-clipboard-history\
 wl-clipboard\
 wl-paste\
 wlogout\
 wlsunset\
 xdg-desktop-portal-gtk\
 xdg-desktop-portal-hyprland\
 xdg-desktop-portal-kde\
 xdg-desktop-portal\
 xdg-user-dirs\
 xdg-utils\
 yad\
 zen-browser-bin\
;

command -v walker &>/dev/null || {
    git clone --branch v0.13.26 --depth 1 https://github.com/abenz1267/walker /tmp/walker
    cd /tmp/walker/cmd
    go build -o walker
    sudo cp walker /usr/bin/
}

