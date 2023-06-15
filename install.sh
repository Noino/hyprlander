#!/usr/bin/env bash

# get our working directory straight
cd $(dirname $0)
src_dir=`pwd`;

# source bash configs at end of profile
[[ `rg "${src_dir##*/}" ~/.bash_profile` ]] || echo "[[ -f \"${src_dir}\"/bash_configs ]] && . \"${src_dir}\"/bash_configs" >> ~/.bash_profile


cd ~/.config

for d in ${src_dir}/dotconfig/*; do 
	[[ -e "${d##*/}" && ! -L "${d##*/}" ]] && mv "${d##*/}" "${d##*/}".bak
	[[ -L "${d##*/}" ]] && rm "${d##*/}"
	[[ -d $d ]] && ln -s "$d/" || ln -s "$d" 
done





