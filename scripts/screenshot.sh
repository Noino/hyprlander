#!/bin/bash
dir="$HOME/Pictures/Screenshots"

file="Screenshot_"
[ "$1" = "window" ] && file="${file}$(hyprctl -j activewindow | jq -r '(.class)')_"
file="${file}$(date "+%Y-%m-%d_%H-%M-%S")_${RANDOM}.png"

notify() {
    action=$(timeout 5 notify-send -t 5000 -A Open -A Delete -i "$dir/$file" -h string:x-canonical-private-synchronous:screenshot "Screenshot saved in $dir/$file")
    [[ -r "$dir/$file" ]] || { notify-send -t 3000 "Failed to save screenshot"; exit; }
    case "$action" in
        0) xdg-open "$dir/$file" &;;
        1) rm "$dir/$file";;
    esac

}
screen() {
    grim - | tee "$dir/$file" | wl-copy
    notify
}
window() {
    hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | xargs -I{} grim -g{} - | tee "$dir/$file" | wl-copy
	notify
}
area() {
	grim -g "$(slurp)" - | tee "$dir/$file" | wl-copy
	notify
}

$@;
exit;

