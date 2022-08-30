
export LESS="--quit-if-one-screen --RAW-CONTROL-CHARS --no-init"

# from https://github.com/beauwilliams/awesome-fzf/blob/master/awesome-fzf.zsh
# Checkout to existing branch or else create new branch. gco <branch-name>.
# Falls back to fuzzy branch selector list powered by fzf if no args.
fzf-checkout(){
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ "$#" -eq 0 ]]; then
            local branches branch
            branches=$(git branch -a) &&
            branch=$(echo "$branches" |
            fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
            git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
        elif [ `git rev-parse --verify --quiet $*` ] || \
             [ `git branch --remotes | grep  --extended-regexp "^[[:space:]]+origin/${*}$"` ]; then
            echo "Checking out to existing branch"
            git checkout "$*"
        else
            echo "Creating new branch"
            git checkout -b "$*"
        fi
    else
        echo "Can't check out or create branch. Not in a git repo"
    fi
}

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nvim'
   export XIVIEWER='icat'
else
   export EDITOR='nvim'
   export XIVIEWER='icat'
fi

function search_code {
   rg -n "$1" | fzf --delimiter=':' -n 1,3.. --preview-window 'right,70%,+{2}-/2' --preview 'bat --color=always {1} -H {2} --style=plain'
}

alias gca="git commit -v -a"
alias gca!="git commit -v -a --amend --reset-author"
alias gdh="git diff -r HEAD^"
alias ls="lsd --group-dirs first"
alias ll="lsd --group-dirs first --color=always -la | less"
alias cat="bat --style plain --paging never"
alias bs="bat --style plain"
alias emacs="emacs -nw"
alias xgrep="fd -tf .py . | xargs grep --color=always --exclude-dir={.git,.svn.CVS} "
alias xgrepfull="fd -tf .py . | xargs grep --color=always -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} "
alias edit="$EDITOR"
alias diff="delta"
alias icat="kitty +kitten icat"
alias plint="pylama --linters=print,mccabe,pycodestyle,pyflakes --ignore=E501,W0612,W605,E231,E203"
alias rgs="search_code"
alias sshbac="TERM=xterm-256color ssh"  # include TERM in ssh for the *bac servers
alias gcb="fzf-checkout"
eval "$(mcfly init zsh)"


