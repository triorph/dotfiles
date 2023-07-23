-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

local opts = { noremap = true, silent = true }
local key_mapper = function(mode, key, result)
  vim.api.nvim_set_keymap(mode, key, result, { noremap = true, silent = true })
end
local verbal_key_mapper = function(mode, key, result)
  vim.api.nvim_set_keymap(mode, key, result, { noremap = true })
end
local ncmdmap = function(key, cmd)
  key_mapper("n", key, "<cmd>" .. cmd .. "<CR>")
end

local function nmap_keymap(keymap, command)
  vim.api.nvim_set_keymap("n", keymap, "<cmd>" .. command .. "<CR>", opts)
end

ncmdmap("<leader>1", "BufferLineGoToBuffer 1")
ncmdmap("<leader>2", "BufferLineGoToBuffer 2")
ncmdmap("<leader>3", "BufferLineGoToBuffer 3")
ncmdmap("<leader>4", "BufferLineGoToBuffer 4")
ncmdmap("<leader>5", "BufferLineGoToBuffer 5")
ncmdmap("<leader>6", "BufferLineGoToBuffer 6")
ncmdmap("<leader>7", "BufferLineGoToBuffer 7")
ncmdmap("<leader>8", "BufferLineGoToBuffer 8")
ncmdmap("<leader>9", "BufferLineGoToBuffer 9")
-- nmap_keymap("<leader><leader>", "<c-^>")

key_mapper("i", "jj", "<ESC>")
key_mapper("i", "kk", "<ESC>")
key_mapper("i", "jk", "<ESC>")
-- commenting
vim.api.nvim_set_keymap("n", "<leader>/", "gcc", { silent = true })
vim.api.nvim_set_keymap("v", "<leader>/", "gc", { silent = true })

-- ZenMode
ncmdmap("<leader>vz", "ZenMode")

--  Copy to clipboard
verbal_key_mapper("v", "\\y", '"+y')
verbal_key_mapper("n", "\\Y", '"+yg_')
verbal_key_mapper("n", "\\y", '"+y')

--  Paste from clipboard
verbal_key_mapper("n", "\\p", '"+p')
verbal_key_mapper("n", "\\P", '"+P')
verbal_key_mapper("v", "\\p", '"+p')
verbal_key_mapper("v", "\\P", '"+P')

-- primagen move visual chunk
key_mapper("v", "J", ":m '>+1<CR>gv=gv")
key_mapper("v", "K", ":m '<-2<CR>gv=gv")

-- MaskDask change same text again
vim.api.nvim_set_keymap("n", "cg*", "*Ncgn", { silent = true })
key_mapper("n", "g.", '/\\V\\C<C-r>"<CR>cgn<C-a><Esc>')

--  make extra pushes of escape clear various highlights
vim.keymap.set("n", "<Esc>", function()
  require("notify").dismiss({}) -- clear notifications
  vim.cmd.nohlsearch() -- clear highlights
  vim.cmd.echo() -- clear short-message
  if require("flash.plugins.char").state ~= nil then -- clear flash char highlight
    require("flash.plugins.char").state:hide()
  end
end)

-- Undo F1 as I keep hitting it accidentally when trying to hit ESC for exiting insert mode (less of a problem after capslock mapping)
key_mapper("n", "<F1>", "<Nop>")
key_mapper("i", "<F1>", "<Nop>")

-- Auto-split on commas (with auto-indent), in case you don't have autoformatting setup.
-- TODO: some version of this that checks that the , is of type @punctiation.delimiter
-- (might have to make a custom method)
key_mapper("n", "<leader>,", ":s/,/,\\r/g<CR>`[v`]=<CR><Esc>:nohl<CR>")

-- basic navigation if lsp isn't present
ncmdmap("gF", "Telescope grep_string")

vim.api.nvim_create_user_command("SplunkFormat", function()
  vim.cmd([[
%!jq -c '{"t":.result._time, "m": .result.message}'
%norm d3f"
%norm f"df:
%norm f"x$xx
%g/^/m0
	]])
end, {})
