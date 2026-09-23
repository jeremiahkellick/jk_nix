source ~/.bash_profile

if [ -f $HOME/.git-prompt.sh ]; then
    . $HOME/.git-prompt.sh
    precmd () { __git_ps1 "%{$fg[green]%}%n@%m %{$fg[blue]%}%~" " $%{$reset_color%} " }
fi
