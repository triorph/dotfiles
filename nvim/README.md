## Neovim

Works as your config folder, can install with

```
ln -s dotfiles/nvim ~/.config/nvim
```

You'll have to manually install packer to your nvim local/share folder, then the init.lua should work.

Not quite sure on the exact steps we have to run to get Packer to work, but I usually type

```
:PackerInstall
:wq
nvim
:PackerCompile
```

### Features:

- Autoformatting with Format plugin, using mostly black/stylua but also trims all whitespace.
- LSP with auto setup of all parsers (overkill probably, will maybe fix later)
  - lsp-saga for some nice functions to go with this
  - Trouble to help collect all the results from this
- GitSigns to see what files have been changed
- GitBlame to see a codelens on the current line of who last changed it
- A simple start-screen dashboard with a pretty rainbow logo
- Telescope to easily fuzzy search for files/grep for lines of code
- which-key to see what options are available after you press your leader
- bufferline shows your buffers like they are tabs at the top of the screen
- lualine for a basic status line at the bottom of the screen
- nvim-compe for command line completion (still working on getting keymappings right for this)
- kommentary to handle toggling comments in code (still working on getting keymappings right for this)
- Treesitter for correct tagging of words for colour schemes and code completeness
- IndentBlankLine for better viewing your indentation

### Display

- TokyoNight theme
- ZenMode available (keymap = F11 in normal mode)
- Twilight mode to only show colour for the currently being edited code (auto-turns on in ZenMode)

### To do

Still not quite right, but getting much closer now.

- Get commenting working the way I want it to (apparently it is impossible to bind to Ctrl+/ in vim, so I'm stuck with learning some new muscle memory instead. C'est la vie)
- Linters working into some "all errors" view (like LSP does for Trouble)
- Telescope to view sessions and switch between them
