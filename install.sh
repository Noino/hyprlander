#!/usr/bin/env bash

/usr/bin/which go >/dev/null || { echo "Gotta install golang first" && exit 1; }
/usr/bin/which rg >/dev/null || { echo "Gotta install ripgrep first" && exit 2; }
/usr/bin/which npm >/dev/null || { echo "Gotta install npm *vomit*" && exit 3; }

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

[[ -e  ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]] || git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
nvim \"${src_dir}\"/dotconfig/nvim/lua/theprimeagen/packer.lua --noplugin -c ":so | :PackerSync"



