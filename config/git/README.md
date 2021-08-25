## Git configuration

The attributes and ignore file can be linked via symlink

```
ln -s dotfiles/git/gitattributes ~/.gitattributes
ln -s dotfiles/git/ignore ~/.config/git/ignore
```

The gitconfig file needs to be copied and have its credentials added in.

```
cp dotfiles/git/gitconfig ~/.gitconfig
```
