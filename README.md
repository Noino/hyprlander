# Stumbling through my first real try at linux desktop

## install

be sure to grab submodules too
```
git clone --recurse-submodules ...
```

Dependencies: yes!
This is probably not a complete list 🤷‍♂
```
sudo pacman -S git go
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
yay -Rsn yay-debug
yay -S yay-bin
yay -S -needed adobe-source-code-pro-fonts bc blueman bluez bluez-utils brightnessctl btop bzmenu cliphist curl eww fastfetch firefox ghostty grim gvfs gvfs-mtp hypridle hyprland hyprlock hyprpaper hyprpolkitagent imagemagick iwmenu jq kvantum libspng mousepad mpv mpv-mpris neovim network-manager-applet noto-fonts noto-fonts-emoji npm nvtop nwg-displays nwg-look otf-font-awesome pacman-contrib pamixer pavucontrol pipewire pipewire-alsa pipewire-audio pipewire-pulse playerctl qalculate-gtk qt5ct qt6-5compat qt6-declarative qt6-svg qt6ct ripgrep sddm slurp sof-firmware swaync ttf-droid ttf-fantasque-nerd ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-victor-mono umockdev unzip walker-bin waybar wezterm wget wireplumber wl-clipboard wl-clipboard-history wl-paste wlogout wlsunset xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-desktop-portal-kde xdg-user-dirs xdg-utils yad

```

Refer to JaKooLit's dotfiles on how to install sddm theme and gtk icons - or just use his stuff, since this is a no options or gui configs and strictly the way i want it




## Acknowledgments

Sources of inspiration
- https://github.com/Gl00ria/dotfiles
- https://github.com/JaKooLit/Arch-Hyprland
- https://github.com/Axarva/dotfiles-2.0
- https://github.com/fufexan/dotfiles
- https://github.com/end-4/dots-hyprland
- https://github.com/druskus20/eugh
- https://github.com/lauroro/hyprland-dotfiles
- https://github.com/ChrisTitusTech/hyprland-titus
- https://codeberg.org/JustineSmithies/hyprland-dotfiles
- https://github.com/niraj998/dotfiles
- https://github.com/RMackner/RMackner
- https://github.com/rxyhn/tokyo

