-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_user_command("SplunkFormat", function()
  vim.cmd([[
%!jq -c '{"t":.result._time, "m": .result.message}'
%norm d3f"
%norm f"df:
%norm f"x$xx
%g/^/m0
	]])
end, {})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "cpp", "h", "cuda" },
  callback = function()
    vim.opt.shiftwidth = 4
    vim.opt.tabstop = 4
    vim.opt.expandtab = false
    vim.b.autoformat = false
  end,
})
