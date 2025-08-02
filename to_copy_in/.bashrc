export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# UV by default uses symlinks for cache and virtual environments.
# But this is inside a container, so we want to force it to copy
# files instead of symlinking. That is what this variable does:
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

export proj="$HOME/workspace/vscode-projects"
alias proj="cd ~/workspace/vscode-projects"
alias ls="ls -lFa --color=auto"
alias bat="batcat"
alias cl="clear"

echo "Type 'tkhelp' (Tool-Kit Help) to get started."

#############
# FUNCTIONS #
#############

# ~ Generic functions ~ #
# --------------------- #

# Run main launcher script for the python-toolkit
tkhelp() {
    (cd ~/.py_help && uv run main.py)
}

# reload the .bashrc file
resource () {
  source "$HOME/.bashrc"
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

# fuzzy nano
fnano() {
  local file
  file=$(find . -type f -not -path '*/\.*' | fzf) && ${EDITOR:-nano} "$file"
}

# fuzzy batcat
fbat() {
  local file
  file=$(find . -type f -not -path '*/\.*' | fzf) && bat "$file"
}

# ~ Ripgrep functions ~ #
# --------------------- #

# search by file name
rgf() {
  rg --files --iglob "*$1*"
}

