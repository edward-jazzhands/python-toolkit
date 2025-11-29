#! ATTENTION
# The .bash_profile file (or just regular .profile) must be present
# in order for .bashrc to be sourced upon user login to bash sessions.

###################
# Welcome Message #
###################

echo "Type 'tkhelp' (Tool-Kit Help) to view all available programs."

##################
# Initialization #
##################

# Sets my global git ignore preferences:
git config --global core.excludesfile /home/devuser/.gitignore_global

# Sets gopass as the default git credential helper:
git config --global credential.helper gopass


############
# THE REST #
############

export mygithub="https://github.com/edward-jazzhands"

alias ls="ls -lFa --color=auto"
alias bat="batcat"
alias cl="clear"
alias gcm="git-credential-manager"
alias resource="source ~/.bashrc"
alias bashrc="nano ~/.bashrc"

# Aliases for Python
alias activate="source .venv/bin/activate"


# Run main launcher script for the python-toolkit
tkhelp() {
    (cd /ptk-help && uv run main.py)
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

# fuzzy cd
fcd() {
  local dir
  dir=$(find . -type d -not -path '*/\.*' | fzf) && cd "$dir"
}

# fuzzy shell history
fsh() {
  eval "$(history | fzf | sed 's/ *[0-9]* *//')"
}

# search by file name
rgf() {
  rg --files --iglob "*$1*"
}

