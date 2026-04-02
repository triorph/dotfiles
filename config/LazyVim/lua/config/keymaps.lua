-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true, silent = true }, opts or {}))
end

-- BufferLine: jump to buffer by index
map("n", "<leader>1", "<cmd>BufferLineGoToBuffer 1<CR>", { desc = "Buffer 1" })
map("n", "<leader>2", "<cmd>BufferLineGoToBuffer 2<CR>", { desc = "Buffer 2" })
map("n", "<leader>3", "<cmd>BufferLineGoToBuffer 3<CR>", { desc = "Buffer 3" })
map("n", "<leader>4", "<cmd>BufferLineGoToBuffer 4<CR>", { desc = "Buffer 4" })
map("n", "<leader>5", "<cmd>BufferLineGoToBuffer 5<CR>", { desc = "Buffer 5" })
map("n", "<leader>6", "<cmd>BufferLineGoToBuffer 6<CR>", { desc = "Buffer 6" })
map("n", "<leader>7", "<cmd>BufferLineGoToBuffer 7<CR>", { desc = "Buffer 7" })
map("n", "<leader>8", "<cmd>BufferLineGoToBuffer 8<CR>", { desc = "Buffer 8" })
map("n", "<leader>9", "<cmd>BufferLineGoToBuffer 9<CR>", { desc = "Buffer 9" })

-- ZenMode (grouped with UI toggles)
map("n", "<leader>uz", "<cmd>ZenMode<CR>", { desc = "Toggle Zen Mode" })

-- Copy to clipboard
map("v", "\\y", '"+y', { desc = "Yank to clipboard" })
map("n", "\\Y", '"+yg_', { desc = "Yank to end of line to clipboard" })
map("n", "\\y", '"+y', { desc = "Yank to clipboard" })

-- Paste from clipboard
map("n", "\\p", '"+p', { desc = "Paste from clipboard" })
map("n", "\\P", '"+P', { desc = "Paste from clipboard (before)" })
map("v", "\\p", '"+p', { desc = "Paste from clipboard" })
map("v", "\\P", '"+P', { desc = "Paste from clipboard (before)" })

-- Move selected lines up/down (ThePrimeagen style)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Change all occurrences of word under cursor (MaskDask style)
map("n", "cg*", "*Ncgn", { desc = "Change all occurrences of word" })
map("n", "g.", '/\\V\\C<C-r>"<CR>cgn<C-a><Esc>', { desc = "Repeat last change on next match" })

-- Escape: clear highlights, flash char state, and short-message
map("n", "<Esc>", function()
  vim.cmd.nohlsearch()
  vim.cmd.echo()
  if require("flash.plugins.char").state ~= nil then
    require("flash.plugins.char").state:hide()
  end
end)

-- Disable F1 (too close to Esc)
map("n", "<F1>", "<Nop>")
map("i", "<F1>", "<Nop>")

-- Auto-split on commas (with auto-indent), useful without autoformatting
-- TODO: check that the comma is of type @punctuation.delimiter via treesitter
map("n", "<leader>,", ":s/,/,\\r/g<CR>`[v`]=<CR><Esc>:nohl<CR>", { desc = "Split on commas" })

-- Navigation / LSP helpers
map("n", "gF", LazyVim.pick("grep_cword"), { desc = "Grep word under cursor" })
map("n", "gk", vim.diagnostic.open_float, { desc = "Show diagnostics" })
map({ "n", "v" }, "gx", vim.lsp.buf.code_action, { desc = "Code action" })
-- Note: renaming is handled by LazyVim's default <leader>cr binding
