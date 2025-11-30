#!/bin/bash
# set -eu will cause exit immediately if any command fails
set -eu

# Get UID/GID from environment variables
PUID=${PUID:-3001}
PGID=${PGID:-3000}

# Only modify user/group if they differ from current values
CURRENT_UID=$(id -u devuser)
CURRENT_GID=$(id -g devuser)
HOME_DIR="/home/devuser"
SENTINEL_FILE="$HOME_DIR/.initialized"


# ╔════════════╗
# ║  Password  ║
# ╚════════════╝
if [ -n "$PASSWORD" ]; then
    echo "devuser:$PASSWORD" | chpasswd
    echo "Password set from environment variable"
else
    echo "****************************************************"
    echo "* WARNING: No password set for devuser! Auto-generating one for you..."
    echo "* HINT: You can set your own password by setting the PASSWORD environment variable:"
    echo "* docker run -e PASSWORD=yourpassword ..."
    echo "****************************************************"
    echo ""
    PASSWORD=$(openssl rand -base64 32)
    echo "devuser:$PASSWORD" | chpasswd
    echo "* Auto-generated container password for devuser:"
    echo "* $PASSWORD"
    echo ""
    echo "****************************************************"
    echo "* IMPORTANT: Save this password - it won't be shown again!"
    echo "This password is used for both SSH login (devuser) and for the code-server Web UI."
    echo "Note that you can also modify the code-server config file to use a different password."
    echo "If you have bind-mounted the container's home dir, you can modify the config file there."
    echo "(~/.config/code-server/config.yaml)"
    echo "****************************************************"
fi

# ╔════════════════╗
# ║  Copy Configs  ║
# ╚════════════════╝
if [ ! -f "$SENTINEL_FILE" ]; then
    echo "--- First run: Performing initialization... ---"

    # Copy default configs to home dir
    cp -r /default-configs/. $HOME_DIR
    mv $HOME_DIR/code-server-config.yaml $HOME_DIR/.config/code-server/config.yaml

    chown devuser:devuser $HOME_DIR/.bashrc
    chown devuser:devuser $HOME_DIR/.bash_profile
    chown devuser:devuser $HOME_DIR/.gitignore_global
    chown devuser:devuser $HOME_DIR/.gitconfig
    chown devuser:devuser $HOME_DIR/.tmux.conf
    chown devuser:devuser $HOME_DIR/.justfile
    chown devuser:devuser $HOME_DIR/.config/code-server/config.yaml
    printf $PASSWORD > $HOME_DIR/.config/code-server/config.yaml

else
    echo "--- Volume already initialized. Not copying configs ---"
fi

# ╔══════════════════╗
# ║  Set User/Group  ║
# ╚══════════════════╝
if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then

    START_TIME=$(date +%s)
    if [ "$CURRENT_UID" != "$PUID" ]; then
        echo "Changing UID from $CURRENT_UID to $PUID"
        usermod -u "$PUID" devuser
    else
        echo "Using default UID of $PUID"
    fi

    if [ "$CURRENT_GID" != "$PGID" ]; then
        echo "Changing GID from $CURRENT_GID to $PGID"
        groupmod -g "$PGID" devuser
    else
        echo "Using default GID of $PGID"
    fi
    END_TIME=$(date +%s)
    ELAPSED_SECONDS=$((END_TIME - START_TIME))
    echo "Time elapsed for user/group mod: ${ELAPSED_SECONDS}s"
fi

# ╔════════════╗
# ║  Env vars  ║
# ╚════════════╝
# Append any new runtime environment variables that are not already in /etc/environment
# Skip HOME because we don't want root's home dir, also skip PASSWORD
printenv | grep -v "^HOME=" | grep -v "^PASSWORD=" | while IFS= read -r line; do
    key=$(echo "$line" | cut -d= -f1)
    if ! grep -q "^${key}=" /etc/environment 2>/dev/null; then
        echo "$line" >> /etc/environment
    fi
done

