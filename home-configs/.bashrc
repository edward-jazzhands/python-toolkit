#! ATTENTION
# The .bash_profile file (or just regular .profile) must be present
# in order for .bashrc to be sourced upon user login to bash sessions.


echo "Type 'tkhelp' (Tool-Kit Help) to view all available programs."

###########
# EXPORTS #
###########

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# UV by default uses symlinks for cache and virtual environments.
# But this is inside a container where the projects are bind mounted.
# This means the UV cache folder will be on a different file system than
# the projects themselves. so we want to force it to copy files into each
# venv instead of symlinking. That is what this variable does:
export UV_LINK_MODE=copy

# Poertry by default creates virtual environments in a special secret
# cache location. We don't want that, we want it to create .venv folders
# inside the project directory:
export POETRY_VIRTUALENVS_IN_PROJECT=true

# This is because some apps such as git credential manager expect a program called
# 'libicu' to be available in the system to handle internationalization
# (ie. characters from other languages).
# This program is fairly large and is not needed in a container.
# This will make it ignore the error and continue running.
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Add local bin env folder to PATH (This is used by uv)
. "$HOME/.local/bin/env"

export projects="$HOME/workspace/vscode-projects"
export mygithub="https://github.com/edward-jazzhands"

###########
# ALIASES #
###########

alias ls="ls -lFa --color=auto"
alias bat="batcat"
alias cl="clear"
alias gcm="git-credential-manager"
alias resource="source ~/.bashrc"
alias bashrc="nano ~/.bashrc"

# Aliases for Python
alias activate="source .venv/bin/activate"


#############
# FUNCTIONS #
#############

# ~ Generic functions ~ #
# --------------------- #

# Run main launcher script for the python-toolkit
tkhelp() {
    (cd ~/ptk-help && uv run main.py)
}

# Prints a color gradient to test truecolor support
colortest() {
  awk 'BEGIN{
      s=" "; s=s s s s s s s s;
      for (colnum = 0; colnum<77; colnum++) {
          r = 255-(colnum*255/76);
          g = (colnum*510/76);
          b = (colnum*255/76);
          if (g>255) g = 510 - g;
          printf "\033[48;2;%d;%d;%dm%s\033[0m", r,g,b,substr(s,colnum%8+1,1);
      }
      printf "\n";
  }'
}

# ~ Fuzzy functions ~ #
# ------------------- #

# fuzzy cd
fcd() {
  local dir
  dir=$(find . -type d -not -path '*/\.*' | fzf) && cd "$dir"
}

# fuzzy shell history
fsh() {
  eval "$(history | fzf | sed 's/ *[0-9]* *//')"
}

# ~ Ripgrep functions ~ #
# --------------------- #

# search by file name
rgf() {
  rg --files --iglob "*$1*"
}

