# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

if [ -f $HOME/.env ]; then
    . $HOME/.env
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

if [[ "$OSTYPE" == "darwin"* ]]; then
    export CLICOLOR=1
    # Needed to use the mono assemblies from other formulae
    export MONO_GAC_PREFIX="/usr/local"
fi

# zsh-only
if [ -n "$ZSH_VERSION" ]; then
    bindkey "^N" clear-screen

    setopt HIST_IGNORE_DUPS INC_APPEND_HISTORY

    HISTSIZE=1000000
    SAVEHIST=10000

    autoload -Uz compinit && compinit
    autoload -Uz colors && colors
else # bash only
    bind -x '"\C-n": printf "\33[H\33[2J"'

    HISTFILESIZE=1000000
    HISTSIZE=10000

    # don't put duplicate lines or lines starting with space in the history.
    # See bash(1) for more options
    HISTCONTROL=ignoreboth

    # append to the history file, don't overwrite it
    shopt -s histappend

    # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    shopt -s checkwinsize

    # If set, the pattern "**" used in a pathname expansion context will
    # match all files and zero or more directories and subdirectories.
    shopt -s globstar

    if [ -f $HOME/.git-completion.bash ] && [ -f $HOME/.git-prompt.sh ]; then
        . $HOME/.git-completion.bash
        . $HOME/.git-prompt.sh
        PS1='\[\033[0;32m\]\u@\h \[\033[0;34m\]\w$(__git_ps1 " (%s)") \$\[\e[00m\] '
    fi

    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
    # sources /etc/bash.bashrc).
    if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
        fi
    fi
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm|xterm-color|*-256color) color_prompt=yes;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" \
        || eval "$(dircolors -b)"
            alias ls='ls --color=auto'
            alias grep='grep --color=auto'
            alias fgrep='fgrep --color=auto'
            alias egrep='egrep --color=auto'
fi

# Alias definitions.
alias ssh='TERM=xterm-256color ssh'
alias t='tmux'

psearch() {
    local pids
    pids=$(pgrep -d, "$@") || return 1
    ps -o pid,ppid,comm,args -ww -p "$pids"
}

if [ -x /usr/bin/mint-fortune ]; then
    /usr/bin/mint-fortune
fi

export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR" ]; then
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

if [ -d "$HOME/.rbenv/bin" ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi

export LS_COLORS="di=1;94:ln=1;96:so=1;95:pi=1;93:ex=1;92:bd=1;90;40:cd=1;90;40:or=1;91:mi=1;91"
export PATH="$HOME/.local/bin:$HOME/jk_repo/bin:$HOME/jk_repo/build:$PATH"

if [ -x "$(command -v nvim)" ]; then
    alias vim='nvim'
fi

if [ -f "$HOME/.claude-token" ]; then
    source "$HOME/.claude-token"
fi
