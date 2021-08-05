function! myspacevim#before() abort


let g:neoformat_python_black = {
    \ 'exe': 'black',
    \ 'stdin': 1,
    \ 'args': ['-q', '-'],
    \ }
let g:neoformat_enabled_python = ['black']

let g:neomake_python_pylama_args = ["-i E501,E231,E203,W605,W0612 --linters print,mccabe,pycodestyle,pyflakes"]
let g:neoformat_json_jq = {
    \ 'exe': 'jq',
    \ 'stdin': 1,
    \ 'args': ['--indent', '4']
    \ }
let g:neoformat_json_prettier = {'exe': 'prettier', 'stdin': 1, 'args': ['--tab-width', '4']}

endfunction

function! myspacevim#after() abort










endfunction
