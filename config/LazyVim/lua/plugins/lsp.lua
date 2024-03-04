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
  {
    "nvimtools/none-ls.nvim",
    opts = function()
      local nls = require("null-ls")
      local builtins = nls.builtins
      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
        sources = {
          builtins.formatting.stylua,
          builtins.formatting.isort.with({
            extra_args = { "--profile=black" },
          }),
          builtins.formatting.black,
          builtins.formatting.prettier.with({
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
              "vue",
              "css",
              "scss",
              "less",
              "html",
              "json",
              "jsonc",
              "markdown",
              "graphql",
              "handlebars",
            },
          }),
        },
      }
    end,
  },
}
