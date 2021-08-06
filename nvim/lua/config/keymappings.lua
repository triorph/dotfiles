local key_mapper = function(mode, key, result)
  vim.api.nvim_set_keymap(
    mode,
    key,
    result,
    {noremap = true, silent = true}
  )
end
key_mapper('i', 'jj', '<ESC>')
key_mapper('i', 'kk', '<ESC>')
key_mapper('i', ':w', '<ESC>:w')
key_mapper('i', 'jk', '<ESC>')
