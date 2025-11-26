#!/bin/bash

# Get UID/GID from environment variables (default to 568)
PUID=${PUID:-568}
PGID=${PGID:-568}

# Only modify user/group if they differ from current values
CURRENT_UID=$(id -u devuser)
CURRENT_GID=$(id -g devuser)

if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
    echo "Updating devuser UID to $PUID and GID to $PGID"
    
    # Modify group ID
    groupmod -o -g "$PGID" devuser
    
    # Modify user ID
    usermod -o -u "$PUID" devuser
    
    # Update ownership of home directory and any other directories
    chown -R "$PUID":"$PGID" /home/devuser
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

# Write code-server config
mkdir -p /home/devuser/.config/code-server
cat > /home/devuser/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:5001
auth: password
password: $PASSWORD
cert: false
EOF
chown -R "$PUID":"$PGID" /home/devuser/.config