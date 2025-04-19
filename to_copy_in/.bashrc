export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export UV_LINK_MODE=copy

# Add local bin to PATH (This is mostly used by uv, pipx, and other global tools)
. "$HOME/.local/bin/env"


alias proj="cd ~/workspace/vscode-projects"
alias ls="ls -lFa --color=auto"
alias bat="batcat"

echo "Type 'tkhelp' (Tool-Kit Help) to get started."

# FUNCTIONS

tkhelp() {
    (cd ~/.py_help && uv run main.py)
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