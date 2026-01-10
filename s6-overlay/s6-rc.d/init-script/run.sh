#!/bin/sh
set -eu

HOME_DIR="/home/coder"
SENTINEL_FILE="$HOME_DIR/.initialized"


# ╔════════════════╗
# ║  Copy Configs  ║
# ╚════════════════╝
if [ ! -f "$SENTINEL_FILE" ]; then
    echo "--- First run: Performing initialization... ---"

    # Copy default configs to home dir
    cp -r /default-configs/. $HOME_DIR

    mkdir -p "$HOME_DIR/.config/code-server"
    mv "$HOME_DIR/code-server-config.yaml" "$HOME_DIR/.config/code-server/config.yaml"
    
    echo "password: $PASSWORD" >> "$HOME_DIR/.config/code-server/config.yaml"
    echo "code-server-config.yaml after adding password:"
    cat "$HOME_DIR/.config/code-server/config.yaml"
    echo ""

    # chown devuser:devuser "$HOME_DIR/.bashrc"
    # chown devuser:devuser "$HOME_DIR/.bash_profile"
    # chown devuser:devuser "$HOME_DIR/.gitignore_global"
    # chown devuser:devuser "$HOME_DIR/.gitconfig"
    # chown devuser:devuser "$HOME_DIR/.tmux.conf"
    # chown devuser:devuser "$HOME_DIR/.justfile"
    # chown devuser:devuser "$HOME_DIR/.config/code-server/config.yaml"

else
    echo "--- Volume already initialized. Not copying configs ---"
fi

# We do this first to ensure sudo works below when renaming the user.
# Otherwise the current container UID may not exist in the passwd database.
eval "$(fixuid -q)"

if [ "${DOCKER_USER-}" ]; then
  USER="$DOCKER_USER"
  if [ -z "$(id -u "$DOCKER_USER" 2>/dev/null)" ]; then
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null
    # Unfortunately we cannot change $HOME as we cannot move any bind mounts
    # nor can we bind mount $HOME into a new home as that requires a privileged container.
    sudo usermod --login "$DOCKER_USER" coder
    sudo groupmod -n "$DOCKER_USER" coder

    sudo sed -i "/coder/d" /etc/sudoers.d/nopasswd
  fi
fi

# Allow users to have scripts run on container startup to prepare workspace.
# https://github.com/coder/code-server/issues/5177
if [ -d "${ENTRYPOINTD}" ]; then
  find "${ENTRYPOINTD}" -type f -executable -print -exec {} \;
fi

exec dumb-init /usr/bin/code-server "$@"