#!/usr/bin/env bash

/usr/bin/which go >/dev/null || { sudo pacman -S git go; }
/usr/bin/which yay >/dev/null || { sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si; yay -Syy yay-bin; }

# install stuffs if needed
yay -S --needed adobe-source-code-pro-fonts archlinux-xdg-menu bc blueman bluez bluez-utils brightnessctl btop bzmenu cliphist curl fastfetch firefox ghostty grim gvfs gvfs-mtp hypridle hyprland hyprlock hyprpaper hyprpolkitagent imagemagick iwmenu jq kvantum libspng mousepad mpv mpv-mpris neovim network-manager-applet noto-fonts noto-fonts-emoji npm nvtop nwg-displays nwg-look otf-font-awesome pacman-contrib pamixer pavucontrol pipewire pipewire-alsa pipewire-audio pipewire-pulse playerctl qalculate-gtk qt5ct qt6-5compat qt6-declarative qt6-svg qt6ct ripgrep sddm slurp sof-firmware swaync ttf-droid ttf-fantasque-nerd ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-victor-mono umockdev unzip walker-bin waybar wezterm wget wireplumber wl-clipboard wl-clipboard-history wl-paste wlogout wlsunset xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-desktop-portal-kde xdg-user-dirs xdg-utils yad

# get our working directory straight
cd $(dirname $0)
src_dir=`pwd`;

# source bash configs at end of profile
[[ `rg "${src_dir##*/}" ~/.bash_profile` ]] || echo "[[ -f \"${src_dir}\"/bash_configs ]] && . \"${src_dir}\"/bash_configs" >> ~/.bash_profile

# makes linking ez
[[ -d ~/.config ]] || mkdir ~/.config
cd ~/.config

for d in ${src_dir}/dotconfig/*; do
    # backup conflicting things
    [[ -e "${d##*/}" && ! -L "${d##*/}" ]] && mv "${d##*/}" "${d##*/}".bak
    # remove conflicting links
    [[ -L "${d##*/}" ]] && rm "${d##*/}"
    # make install
    [[ -d $d ]] && ln -s "$d/" || ln -s "$d"
done

# kde default apps thingy
XDG_MENU_PREFIX=arch- kbuildsycoca6


# Gotta rethink think step for :Lazy
#[[ -e  ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]] || git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
#nvim \"${src_dir}\"/dotconfig/nvim/lua/theprimeagen/packer.lua --noplugin -c ":so | :PackerSync"



