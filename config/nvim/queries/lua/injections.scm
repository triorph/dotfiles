;; Treesitter query injections in lua

;; The contents of vim.treesitter.parse_query should be seen as query/scheme
(expression_list
  value: (function_call
           name: (dot_index_expression) @die (#eq? @die "vim.treesitter.parse_query")
           arguments: (arguments (string) (string) @scheme) (#offset! @scheme  1 0 0 0))
)
