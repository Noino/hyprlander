#!/usr/bin/env bash

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

# dms rewrites its settings all the time, so git tracks a default and each machine keeps its own copy
dms_dir="${src_dir}/dotconfig/DankMaterialShell"
[[ -f "$dms_dir/settings.json" ]] || cp "$dms_dir/settings.default.json" "$dms_dir/settings.json"

[[ -L ~/.config/.scripts ]] && rm ~/.config/.scripts
ln -s "${src_dir}"/scripts ~/.config/.scripts

# TPM + plugins
[[ -d ~/.tmux/plugins/tpm ]] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

# resurrect is unmaintained upstream, so we carry fixes for dotted session names and empty saves
resurrect_dir="${src_dir}/dotconfig/tmux/plugins/tmux-resurrect"
resurrect_patch="${src_dir}/install/patches/tmux-resurrect.patch"
git -C "$resurrect_dir" apply --reverse --check "$resurrect_patch" 2>/dev/null \
    || git -C "$resurrect_dir" apply "$resurrect_patch" \
    || echo "tmux-resurrect: $resurrect_patch no longer applies, check it by hand" >&2

# kde default apps thingy
XDG_MENU_PREFIX=arch- kbuildsycoca6


# Gotta rethink think step for :Lazy
#[[ -e  ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]] || git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
#nvim \"${src_dir}\"/dotconfig/nvim/lua/theprimeagen/packer.lua --noplugin -c ":so | :PackerSync"



