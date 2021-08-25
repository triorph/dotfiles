vim.g.dashboard_default_executive = "telescope"
vim.g.dashboard_preview_command = "cat"
vim.g.dashboard_preview_pipeline = "lolcat"
vim.g.dashboard_preview_file_height = 12
vim.g.dashboard_preview_file_width = 80
vim.g.dashboard_preview_file = "~/.config/nvim/logo.cat"
vim.cmd([[
autocmd FileType dashboard set showtabline=0 | autocmd WinLeave <buffer> set showtabline=4
]])
vim.api.nvim_set_keymap("n", "<leader>ss", "<cmd>SessionSave<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>sl", "<cmd>SessionLoad<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>fh", "<cmd>DashboardFindHistory<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>DashboardFindFile <cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>tc", "<cmd>DashboardChangeColorscheme<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>fa", "<cmd>DashboardFindWord<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>fb", "<cmd>DashboardJumpMark<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>cn", "<cmd>DashboardNewFile<cr>", { silent = true, noremap = true })
