return {
  "nvim-mini/mini.files",
  lazy = false,
  opts = {
    windows = {
      preview = true,
      width_focus = 30,
      width_preview = 50,
    },
    options = {
      -- Whether to use for editing directories
      -- overriding the lazyvim default (neotree)
      use_as_default_explorer = true,
    },
  },
}
