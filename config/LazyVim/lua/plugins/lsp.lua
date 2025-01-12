return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps")
      keys[#keys + 1] = { "gR", "<cmd>Telescope lsp_references<cr>" }
      keys[#keys + 1] = { "gT", "<cmd>Telescope lsp_type_definitions<cr>" }
      keys[#keys + 1] = { "gi", "<cmd>Telescope lsp_implementations<cr>" }
      keys[#keys + 1] = { "gr", vim.lsp.buf.rename }
      -- code actions
      keys[#keys + 1] = { "gx", vim.lsp.buf.code_action, mode = { "n", "v" }, has = "codeAction" }
    end,
  },
}
