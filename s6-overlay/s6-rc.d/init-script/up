#!/bin/bash
source /command/.s6-env

if [ -f /run/secrets/devuser_password ]; then
    SECRET=$(cat /run/secrets/devuser_password)
    echo "devuser:$SECRET" | chpasswd
elif [ -n "$PASSWORD" ]; then
    echo "devuser:$PASSWORD" | chpasswd
else
    echo "WARNING: No password set for devuser. SSH login will be unavailable."
fi