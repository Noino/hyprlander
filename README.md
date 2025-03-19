# Stumbling through my first real try at linux desktop

## install

be sure to grab submodules too
```
git clone --recurse-submodules ... 
```

Dependencies: yes!
This is not a complete list, and it assumes hyprland, on other systems you dont need most of them
```
sudo pacman -S git go
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
yay -S ripgrep wl-clipboard-history wl-paste wlsunset hyprpaper hyprlock eww wezterm firefox wlogout wofi grimblast npm neovim ttf-jetbrains-mono-nerd
```



## Acknowledgments

Sources of copypasta inspiration
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

