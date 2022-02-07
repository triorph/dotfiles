#!/bin/bash
daymode=$(grep "gruvbox-light" ~/.config/bat/config)
if [[ "$daymode" == "" ]]; then
    set_daymode
else
    set_nightmode
fi
