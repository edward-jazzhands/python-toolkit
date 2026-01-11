# History
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Completion
autoload -Uz compinit
compinit

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD

# Prompt
if [[ $TERM == *"color"* ]] || [[ $TERM == *"256"* ]]; then
    PS1="%* %F{green}%n@%m%f:%F{blue}%~%f%# "
else
    PS1="%* %n@%m:%~%# "
fi

# Terminal title
case "$TERM" in
    xterm*|rxvt*)
        precmd() { print -Pn "\e]0;%n@%m: %~\a" }
        ;;
esac

dotfiles_list=(
    ".exports"
    ".functions"
    ".aliases"
    ".tools"
)

for dotfile in "${dotfiles_list[@]}"; do
    source "$HOME/$dotfile" && echo "✅ sourced $HOME/$dotfile"
done

welcome()
echo "Type 'devhelp' to view all available CLI programs."