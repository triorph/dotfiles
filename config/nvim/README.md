## Neovim

Works as your config folder, can install with

```
ln -s dotfiles/nvim ~/.config/nvim
```

You'll have to manually install packer to your nvim local/share folder, then the init.lua should work.

The first time you run, you need to manually run some commands to get stuff working:

```
:lua require("plugins")
:PackerSync
:COQdeps
:CHADdeps
```

then wait for them to finish, quit and open again to run:

```
:COQsnips compile
:PackerCompile
```

### Features:

- Autoformatting with null-ls plugin, using mostly black/stylua but also trims all whitespace.
- Linting with null-ls plugin, putting the results into the neovim LSP client
- LSP with auto setup of all parsers (overkill probably, will maybe fix later)
  - lsp-saga for some nice functions to go with this
  - Trouble to help collect all the results from this
- GitSigns to see what files have been changed
- GitBlame to see a codelens on the current line of who last changed it
- Telescope to easily fuzzy search for files/grep for lines of code
- which-key to see what options are available after you press your leader
- bufferline shows your buffers like they are tabs at the top of the screen
- lualine for a basic status line at the bottom of the screen
- COQ for fast autocomplete
- lightspeed for character based movement
- Comment.nvim to handle toggling comments in code (still working on getting keymappings right for this)
- Treesitter for correct tagging of words for colour schemes and code completeness
- IndentBlankLine for better viewing your indentation

### Display

- TokyoNight theme, also have gruvbox, rose-pine, catpuccin, nightfox all available
- ZenMode available (keymap = vz in normal mode)
- Twilight mode to only show colour for the currently being edited code (auto-turns on in ZenMode)

### To do

Still not quite right, but getting much closer now.

- Telescope to view sessions and switch between them
- Improved startup time (have plugins lazy-loading now which might be enough?)
