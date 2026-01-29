#!/usr/bin/env bash
dir="$HOME/Pictures/Screenshots"

file="Screenshot_"
[ "$1" = "window" ] && file="${file}$(hyprctl -j activewindow | jq -r '(.class)')_"
file="${file}$(date "+%Y-%m-%d_%H-%M-%S")_${RANDOM}.png"

notify() {
    local action=$(timeout 5 notify-send -t 5000 -A Open -A Delete -i "$dir/$file" -h string:x-canonical-private-synchronous:screenshot "Screenshot saved in $dir/$file")
    [[ -r "$dir/$file" ]] || { notify-send -t 3000 "Failed to save screenshot"; exit; }
    case "$action" in
        0) xdg-open "$dir/$file" &;;
        1) rm "$dir/$file";;
    esac

}
screen() {
    disable_nss_everywhere
    grim - | tee "$dir/$file" | wl-copy
    restore_nss
    notify
}
window() {
    # disabling nss for active window only might suffice, dont have layers with nss yet
    local ADDR=$(hyprctl -j activewindow | jq -r .address)
    local NSS=$(hyprctl getprop address:$ADDR no_screen_share)
    hyprctl -q dispatch setprop address:$ADDR no_screen_share false
    hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | xargs -I{} grim -g{} - | tee "$dir/$file" | wl-copy
    hyprctl -q dispatch setprop address:$ADDR no_screen_share $NSS
	notify
}
area() {
    disable_nss_everywhere
	grim -g "$(slurp)" - | tee "$dir/$file" | wl-copy
    restore_nss
	notify
}

disable_nss_everywhere() {
    NSS_STATE_FILE=$(mktemp)

    hyprctl -j clients | jq -r '.[] | "\(.address) client"' |
    while read -r addr type; do
        val=${ hyprctl getprop address:$addr no_screen_share 2>/dev/null ; }
        echo "$type $addr $val" >> "$NSS_STATE_FILE"
        hyprctl -q dispatch setprop address:$addr no_screen_share false
    done

    hyprctl -j layers | jq -r '
        .[][].address as $a |
        "\($a) layer"
    ' |
    while read -r addr type; do
        val=${ hyprctl getprop address:$addr no_screen_share 2>/dev/null ; }
        echo "$type $addr $val" >> "$NSS_STATE_FILE"
        hyprctl -q dispatch setprop address:$addr no_screen_share false
    done
}
restore_nss() {
    while read -r type addr val; do
        [[ "$val" == "true" ]] || continue
        hyprctl -q dispatch setprop address:$addr no_screen_share true
    done < "$NSS_STATE_FILE"
    rm -f "$NSS_STATE_FILE"
}

$@;

