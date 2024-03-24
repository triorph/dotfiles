
export LESS="--quit-if-one-screen --RAW-CONTROL-CHARS --no-init"
export FZF_DEFAULT_OPTS="--layout=reverse --height=10 -0"

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

fzf-vim-config(){
    items=("default" "LazyVim")
    config=$(printf "%s\n" "${items[@]}"| fzf --prompt="Choose your neovim config" --height=~10 --exit-0 )
    if [[ -z $config ]]; then
        echo "Nothing selected"
        return 0
    elif [[ $config == "default" ]]; then
        config = ""
    fi
  NVIM_APPNAME=$config nvim $@
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

function kubeexec {
    kubectl exec -n "buildeng-$1-bamboo" --stdin --tty "$2" --container bamboo-agent  -- /bin/bash
}

function gitbranchcleanup {
  git branch -vv \
    | grep ": gone" \
    | awk '{print $1}' \
    | fzf -m -0 --layout=reverse --height=10 \
        --header="Delete which git branches? (tab/shift+tab to multi-select)" \
    | xargs git branch -D
}

ssh_all_prod() {                                          
  for server in bbac ccbac depbac ecobac engbac idbac itbac jcbac jsbac mbac sabac sbac sgbac ssbac subac sdcbac soxbac tbac trebac; do
    echo -n "$server: "
    ssh $server "$*"
  done
}

[ "$TERM" = "xterm-kitty" ] && [ "$SSH_CONNECTION" = "" ] && alias ssh="kitty +kitten ssh"

[[ ! -f ~/opt/homebrew/opt/asdf/libexec/asdf.sh ]] || source /opt/homebrew/opt/asdf/libexec/asdf.sh
[[ ! -f ~/.asdf/plugins/java/set-java-home.zsh ]] || source ~/.asdf/plugins/java/set-java-home.zsh
export NVIM_APPNAME="LazyVim"

alias gca="git commit -v -a"
alias gca!="git commit -v -a --amend --reset-author"
alias gdh="git diff -r HEAD^"
alias gdname="gd --cached --name-only --diff-filter=ACM -r"
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
alias nvims="fzf-vim-config"
alias vims="fzf-vim-config"
alias dbash="docker run --entrypoint /bin/bash -it --pull always"
alias dsh="docker run --entrypoint /bin/sh -it --pull always"
alias vim="JAVA_HOME=~/.asdf/installs/java/openjdk-19/ nvim"
bindkey '^x^e' edit-command-line


