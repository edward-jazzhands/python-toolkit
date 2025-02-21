export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Add local bin to PATH (This is mostly used by uv, pipx, and other global tools)
. "$HOME/.local/bin/env"

tkhelp() {
    (cd ~/.py_help && uv run main.py)
}

alias proj="cd ~/workspace/vscode-projects"
alias ls="ls -lFa --color=auto"
alias bat="batcat"

echo "Type 'tkhelp' (Tool-Kit Help) to get started."