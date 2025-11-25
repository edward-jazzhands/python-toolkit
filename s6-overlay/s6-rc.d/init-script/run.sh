#!/bin/bash

# Check if docker secrets are mounted
if [ -f /run/secrets/devuser_password ]; then
    SECRET=$(cat /run/secrets/devuser_password)
    echo "devuser:$SECRET" | chpasswd
# Fallback to environment variable
elif [ -n "$PASSWORD" ]; then
    echo "devuser:$PASSWORD" | chpasswd
else
    echo "WARNING: No password set for devuser. SSH login will be unavailable."
fi