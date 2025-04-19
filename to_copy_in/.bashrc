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