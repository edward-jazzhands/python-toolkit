#!!! WARNING !!!#
# This file is REQUIRED in order to source the
# .bashrc file and the .bash_ext file upon logging in through SSH.

# The .bash_profile is placed in the home directory,
# and it is executed by the system when a user logs in.
# This is a standard thing in Linux systems.
# It is used to set up the environment for the user.

# The .bash_ext file is created by the dockerfile inside the container.
# It is a file where programs can store their PATH variables and related
# setup commands without clogging up the .bashrc file.

# Debian Slim does not include the .bashrc
# or .bash_profile files.

# source the .bashrc file if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# run ptk-help
cd /ptk-help
uv run main.py
cd ~