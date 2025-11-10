#!!! WARNING !!!#
# This file is REQUIRED in order to source the
# .bashrc file upon logging in through SSH.

# The .bash_profile is placed in the home directory,
# and it is executed by the system when a user logs in.
# This is a standard thing in Linux systems.
# It is used to set up the environment for the user.

# Debian Slim by does not include the .bashrc
# or .bash_profile files.

# source the .bashrc file
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# run ptk-help
cd ~/.ptk-help || exit 1
uv run main.py
cd ~