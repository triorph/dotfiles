vim.g.mapleader=" "
vim.g.dashboard_default_executive = "telescope"
vim.g.indentLine_fileTypeExclude = {'dashboard'}

vim.g.dashboard_preview_command="cat"
vim.g.dashboard_preview_pipeline="lolcat"
vim.g.dashboard_preview_file_height = 12
vim.g.dashboard_preview_file_width = 80
vim.g.dashboard_preview_file="~/.config/nvim/logo.cat"
vim.cmd[[
autocmd FileType dashboard set showtabline=0 | autocmd WinLeave <buffer> set showtabline=4
nmap <Leader>ss :<C-u>SessionSave<CR>
nmap <Leader>sl :<C-u>SessionLoad<CR>
nnoremap <silent> <Leader>fh :DashboardFindHistory<CR>
nnoremap <silent> <Leader>ff :DashboardFindFile<CR>
nnoremap <silent> <Leader>tc :DashboardChangeColorscheme<CR>
nnoremap <silent> <Leader>fa :DashboardFindWord<CR>
nnoremap <silent> <Leader>fb :DashboardJumpMark<CR>
nnoremap <silent> <Leader>cn :DashboardNewFile<CR>

]]
-- vim.api.nvim_set_keymap("n", "<leader>fh", "<cmd>DashboardFindHistory<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>DashboardFindFile <cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>tc", "<cmd>DashboardChangeColorscheme<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>xl", "<cmd>Trouble loclist<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "gR", "<cmd>Trouble lsp_references<cr>",
--   {silent = true, noremap = true}
-- )
-- 
