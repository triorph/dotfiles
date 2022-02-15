
export LESS="--quit-if-one-screen --RAW-CONTROL-CHARS --no-init"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nvim'
   export XIVIEWER='icat'
else
   export EDITOR='nvim'
   export XIVIEWER='icat'
fi

alias gca="git commit -v -a"
alias gca!="git commit -v -a --amend --reset-author"
alias gdh="git diff -r HEAD^"
alias ls="lsd --group-dirs first"
alias ll="lsd --group-dirs first --color=always -la | less"
# alias fd="fdfind"
unalias duf
alias cat="bat --style plain --paging never"
alias bs="bat --style plain"
alias xgrep="fd -tf .py . | xargs grep --color=always --exclude-dir={.git,.svn.CVS} "
alias xgrepfull="fd -tf .py . | xargs grep --color=always -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} "
alias edit="$EDITOR"
alias diff="delta"
alias df="duf | less"
alias icat="kitty +kitten icat"
alias plint="pylama --linters=print,mccabe,pycodestyle,pyflakes --ignore=E501,W0612,W605,E231,E203"
eval "$(mcfly init zsh)"
