return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {},
        pyright = {},
        rust_analyzer = {},
        tsserver = {},
        gopls = {},
        solargraph = {},
      },
    },
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
    "jose-elias-alvarez/null-ls.nvim",
    opts = function()
      local nls = require("null-ls")
      local builtins = nls.builtins
      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
        sources = {
          builtins.formatting.stylua,
          builtins.formatting.shfmt,
          builtins.formatting.isort.with({
            extra_args = { "--profile=black" },
          }),
          builtins.formatting.black,
          builtins.diagnostics.shellcheck,
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
          builtins.diagnostics.eslint,
          builtins.diagnostics.pylama.with({
            extra_args = { "--linters=print,mccabe,pycodestyle,pyflakes", "--ignore=E501,W0612,W605,E231,E203" },
          }),
          builtins.diagnostics.checkstyle.with({
            extra_args = {
              "-c",
              "./checkstyle-rules.xml",
            },
            condition = function(utils)
              return utils.root_has_file({ "checkstyle-rules.xml" })
            end,
            env = {
              JAVA_HOME = vim.env.HOME .. "/.asdf/installs/java/openjdk-19",
            },
          }),
        },
      }
    end,
  },
}
