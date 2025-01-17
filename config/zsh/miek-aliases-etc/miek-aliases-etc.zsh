
export LESS="--quit-if-one-screen --RAW-CONTROL-CHARS --no-init"
# comment this out, as neovim/lazyvim now uses fzf and this 
# setting was breaking the live search
# export FZF_DEFAULT_OPTS="--layout=reverse --height=10 -0"

# double check everything we expect to be installed actually is 
# (since its a bit manual these days)
function health-check() {
  type -p fd
  type -p rg
  type -p fzf
  type -p bat
  type -p lsd
  type -p cargo
  type -p nvim
  type -p delta
  type -p docker
  type -p emacs
  type -p jq
  type -p zoxide
  type -p tmux
  type -p mise
}
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

# Lets you choose which nvim config to use with fzf for selection
fzf-vim-config(){
    items=("default" "LazyVim")
    config=$(printf "%s\n" "${items[@]}"| fzf --layout=reverse --prompt="Choose your neovim config" --height=~10 --exit-0 )
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

# pipes rg into fzf and bat to let you browse your search
function search_code {
   rg -n "$1" | fzf --layout=reverse --delimiter=':' -n 1,3.. --preview-window 'right,70%,+{2}-/2' --preview 'bat --color=always {1} -H {2} --style=plain'
}

# exec into the bamboo build nodes (legacy)
function kubeexec {
    kubectl exec -n "buildeng-$1-bamboo" --stdin --tty "$2" --container bamboo-agent  -- /bin/bash
}

# fzf to remove stale git branches from your local repository
function gitbranchcleanup {
  git branch -vv \
    | grep ": gone" \
    | awk '{print $1}' \
    | fzf -m -0 --layout=reverse --height=10 \
        --header="Delete which git branches? (tab/shift+tab to multi-select)" \
    | xargs git branch -D
}

# Prefer kitty +kitten ssh, but be smart and only use it from kitty and from the host machine, and use
# default ssh otherwise
[ "$TERM" = "xterm-kitty" ] && [ "$SSH_CONNECTION" = "" ] && alias ssh="kitty +kitten ssh"

# all in on LazyVim at this point. Should probably just move it over my main config.
export NVIM_APPNAME="LazyVim"
export VSCODE=code

# git  aliases
alias gca="git commit -v -a"
alias gca!="git commit -v -a --amend --reset-author"
alias gdh="git diff -r HEAD^"
alias gdname="gd --cached --name-only --diff-filter=ACM -r"
# ls aliases, only if lsd is installed
! type lsd > /dev/null || alias ls="lsd --group-dirs first"
! type lsd > /dev/null || alias ll="lsd --group-dirs first --color=always -la | less"
# cat aliases, only if bat is installed
! type bat > /dev/null || alias cat="bat --style plain --paging never"
! type bat > /dev/null || alias bs="bat --style plain"
# diff alias, only if delta is installed
! type delta > /dev/null || alias diff="delta"

# fzf aliases, only if fzf is installed
! type fzf > /dev/null || alias gcb="fzf-checkout"
! type fzf > /dev/null || alias nvims="fzf-vim-config"
! type fzf > /dev/null || alias vims="fzf-vim-config"
! type fzf > /dev/null || alias rgs="search_code"
# editor aliases
alias emacs="emacs -nw"
alias edit="$EDITOR"
alias vim="nvim"
alias health_check="health-check"

# allow image viewing in the kitty terminal
alias icat="kitty +kitten icat"

# docker aliases
alias dbash="docker run --entrypoint /bin/bash -it --pull always"
alias dsh="docker run --entrypoint /bin/sh -it --pull always"

# edit your shell in an editor if the line is too complicated
bindkey '^x^e' edit-command-line

# I think this is supposed to be ~/.zprofile and I got confused at some point, but 
# doesn't hurt to keep (especially with the check)
[[ ! -f ~/.zsh_profile ]] || source ~/.zsh_profile  

# local fzf changes, if they exist
[[ ! -f ~/.fzf.zsh ]] || (source ~/.fzf.zsh && bindkey "ç" fzf-cd-widget)

# atlas kitt context setup, only if atlas cli exists
export KUBECONFIG=$([[ ! -f /opt/atlassian/bin/atlas ]] || /opt/atlassian/bin/atlas kitt context:create --pid=$$)


