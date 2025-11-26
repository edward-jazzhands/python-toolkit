#!/bin/bash
# set -eu will cause exit immediately if any command fails
set -eu

# Get UID/GID from environment variables (default to 568)
PUID=${PUID:-568}
PGID=${PGID:-568}

# Only modify user/group if they differ from current values
CURRENT_UID=$(id -u devuser)
CURRENT_GID=$(id -g devuser)
HOME_DIR="/home/devuser"


if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then

    if [ "$CURRENT_UID" != "$PUID" ]; then
        echo "Changing UID from $CURRENT_UID to $PUID"
        # OLD: This automatically activates a chown of the home dir and is slow
        # usermod -u "$PUID" devuser
        # NEW: This is faster, but requires a manual chown of the home dir:
        sed -i "s/^devuser:x:[0-9]*:/devuser:x:$PUID:/" /etc/passwd
    else
        echo "Using default UID of $PUID"
    fi

    if [ "$CURRENT_GID" != "$PGID" ]; then
        echo "Changing GID from $CURRENT_GID to $PGID"
        # OLD: same reason as above
        # groupmod -g "$PGID" devuser
        # NEW:
        sed -i "s/^devuser:x:[0-9]*:/devuser:x:$PGID:/" /etc/group
    else
        echo "Using default GID of $PGID"
    fi
    
    echo "Updating ownership of $HOME_DIR"

    # Update ownership of home directory and any other directories
    # REMOVED. TOO SLOW.
    # chown -R "$PUID":"$PGID" /home/devuser

    START_TIME=$(date +%s)

    # New faster method:
    # Selective chown: only operate on files that don't already match ownership.
    find "$HOME_DIR" \( -not -uid "$PUID" -o -not -gid "$PGID" \) \
    -exec chown "$PUID:$PGID" {} +

    END_TIME=$(date +%s)
    ELAPSED_SECONDS=$((END_TIME - START_TIME))
    echo "Time elapsed for chown of home dir: ${ELAPSED_SECONDS}s"
fi

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
    echo "****************************************************"
fi

# Write code-server config as devuser
su -s /bin/bash devuser -c "cat > /home/devuser/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:5001
auth: password
password: $PASSWORD
cert: false
EOF"