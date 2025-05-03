# The .profile file is placed in the home directory,
# and it is executed by the system when a user logs in.
# This is a standard thing in Linux systems.
# It is used to set up the environment for the user.

# Debian Slim by default will not have a .profile file
# and thus will not source .bashrc. We need to do this manually.


# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi