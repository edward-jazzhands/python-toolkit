# If not running interactively, don't do anything
# NOTE: This safety check basically prevents programs and scripts from sourcing
# this file since they shouldn't have any business sourcing it. It's a defensive
# check to prevent bugs and recommended for this to always be present.
# You may have seen other bashrc files that instead do something like:
# [ -n "$PS1" ] - However, that is considered to be less robust
# than the below method
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# NOTE: The defaults for this are 500/500
# For setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# This toggles if sessions should append to the session history file
#shopt -s histappend

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
# (This is mostly defensive, if this wasn't here then there's not a lot
# of things affected. But doesn't hurt to have it.)
shopt -s checkwinsize

# Defensive check in case we're in some minimal environment that didn't set up the
# bash competions already (Does nothing if it's already enabled in /etc/bash.bashrc
# and /etc/profile sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# This sets the prompt to be color if we find color or 256 in TERM.
if [[ $TERM == *"color"* ]] || [[ $TERM == *"256"* ]]; then
    PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
else
    PS1="\u@\h:\w\$ "
fi

# If this is an xterm set the title to user@host:dir
# (This updates the terminal tab title)
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

dotfiles_list=(
    ".exports"
    ".functions"
    ".aliases"
    ".tools"
)

for dotfile in "${dotfiles_list[@]}"; do
    source "$HOME/$dotfile" && echo "✅ sourced $HOME/.$dotfile"
done

welcome()
echo "Type 'devhelp' to view all available CLI programs."