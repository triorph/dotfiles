#!/bin/bash
wal -t -s -i ~/Wallpapers -q
feh --bg-fill `jq -er ".wallpaper" ~/.cache/wal/colors.json`
