## Kitty

Kitty as a terminal editor.

diff.conf and dracula.conf are just the files for the Dracula theme.

Also includes a script `togglekitty` that allows kitty to work in a quake-mode style (like yakuake).
(Note: with awesome WM this is no longer needed. Togglekitty is more of a hack for ubuntu (that didn't seem to work with 21.04 anyway))

To install togglekitty:

```
ln -s dotfiles/kitty/togglekitty ~/.local/bin/togglekitty
```

and then make a binding in your window manager to call this. I have my gnome keyboard settings to call togglekitty when I hit ctrl+\`

The other config files can be installed via symlinks the normal way

```
ln -s dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf
ln -s dotfiles/kitty/diff.conf ~/.config/kitty/diff.conf
ln -s dotfiles/kitty/dracula.conf ~/.config/kitty/dracula.conf
```
