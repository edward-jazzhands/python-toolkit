##############
#~ METADATA ~#
##############

FROM debian:bookworm-slim

# SHELL command is necessary because it sets the default shell 
# for RUN commands. Without it, Dockerfile uses /bin/sh, but we 
# want bash features like source and proper script execution.
SHELL ["/bin/bash", "-c"]

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="ed.jazzhands@gmail.com"
LABEL version="0.3.0"
LABEL description="Edward Jazzhands Development Toolkit Container"

# NOTE: right now the repo is called python toolkit but that might change
LABEL org.opencontainers.image.source="https://github.com/edward-jazzhands/python-toolkit"
LABEL org.opencontainers.image.licenses="MIT"

# This doesn't actually enable the port, it's only metadata for Docker.
# The port is set in the sshd_config file.
EXPOSE 2222

#########################
#~   INITIAL CONFIG    ~#
#########################

# Mark as unhealthy if the SSH service goes down
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep sshd || exit 1

# the ENTRYPOINT sets the program that launches when the container starts up.
# At the moment we only need the SSH Server. In the future this might be changed
# to some kind of app manager/supervisor service to boot more than 1 program.
ENTRYPOINT ["gosu", "root", "/usr/sbin/sshd", "-D"]

# WORKDIR is the default working directory for RUN, CMD,
# ENTRYPOINT, COPY, and ADD instructions. We don't care about the default directory
# for RUN commands (We're just installing programs so it doesn't affect us).
# Therefore it should actually be safe to delete the following line:
WORKDIR /home/devuser/workspace
# If this is deleted then plz test to ensure there's no problems.

# Here we copy the .bashrc file and other config files.
# This is where you would add in your own config files.
# NOTE: This dockerfile is designed so that essential configs
# for programs are not stored in any of these files. These are all
# personal custom OS settings. I have my own favorite shell shortcuts
# and functions, my tmux settings, my global Justfile, my own git settings, etc.
COPY /to_copy_in/.bashrc /home/devuser/.bashrc
COPY /to_copy_in/.tmux.conf /home/devuser/.tmux.conf
COPY /to_copy_in/.justfile /home/devuser/.justfile
COPY /to_copy_in/.gitconfig /home/devuser/.gitconfig
COPY /to_copy_in/.gitignore_global /home/devuser/.gitignore_global

# NOTE: These 3 files, unlike the config files above, are not optional.
# The container is designed so that these are required.
# .profile tells Debian slim to source the .bashrc file, its not included by
# default in slim base images.
# .launch.sh is utilized by SSH server (ForceCommand ~/.launch.sh)
# to automatically start up bash for every user that connects through SSH
# (Also not a default for some reason).
# And .py_help is just the container's custom help splash. Its not *technically*
# necessary but you'd have to modify .launch.sh to get rid of it.
COPY /to_copy_in/.profile /home/devuser/.profile
COPY /to_copy_in/py_help /home/devuser/.py_help
COPY /to_copy_in/.launch.sh /home/devuser/.launch.sh

# NOTE: 568:568 is the default for TrueNAS apps.
# You may need to change the user/group ID for your server
RUN groupadd -g 568 devuser && \
    useradd -m -u 568 -g devuser -s /bin/bash devuser && \
    chown -R 568:568 /home/devuser && \
    chmod +x /home/devuser/.launch.sh && \
    echo 'devuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
 
# Base programs required for setting up other programs
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --force-confdef = (Force configuration defaults)
    # --force-confold = (Force configuration keep old files during upgrades)
    # Together these two settings prevent any interactive prompts during
    # package installation:
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    ca-certificates \
    sudo \
    wget \
    curl \
    tar \
    git \
    gosu \
    # libssl-dev is a library for OpenSSL, which is required by many Python packages.
    libssl-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    

######################
#~     SSH SETUP    ~#
######################

# Copy your sshd_config file to the system /etc/ssh folder (for server/OS level config):
COPY /to_copy_in/sshd_config /etc/ssh/sshd_config

# Copy the password file into the image
COPY /to_copy_in/password /tmp/password

# Copy your public key as the user authorized_keys file:
# COPY id_rsa_devuser.pub /home/devuser/.ssh/authorized_keys

# NOTE: These unfinished comments are for future reference to get
# it working with SSH keys instead of passwords.
# I found it quite tricky to get it working properly, so I left
# it as a password for now.

RUN mkdir /run/sshd && \
    # mkdir -p /home/devuser/.ssh && \
    echo "devuser:$(cat /tmp/password)" | chpasswd && \
    rm /tmp/password && \
    # set permissions:
    # 755: Owner can R+W+X, group and others can R+X
    chmod 755 /run/sshd && \
    # 700: Owner can R+W+X, group and others have no permissions
    # chmod 700 /home/devuser/.ssh && \
    chmod 700 /etc/ssh && \
    # 600: Owner can R+W, group and others have no permissions
    chmod 600 /etc/ssh/sshd_config && \
    # chmod 600 /home/devuser/.ssh/authorized_keys && \
    # set ownership:
    chown root:root /etc/ssh/sshd_config && \
    chown -R root:root /run/sshd
    # chown -R 568:568 /home/devuser/.ssh && \
    # chown -R 568:568 /home/devuser/.ssh/authorized_keys

######################
# ~ Homebrew Setup ~ #
######################

# --- Homebrew Installation ---
RUN gosu devuser bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/devuser/.bashrc

# NOTE: setting ENV PATH= inside the dockerfile like this apparently also
# sets it in the finished container? I think thats whats going on.
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

#########################
# ~ UV / Python Setup ~ #
#########################

ARG PYTHON_VERSIONS="3.8 3.9 3.10 3.11 3.12 3.13"

RUN gosu devuser bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh' && \
    gosu devuser bash -c 'export PATH="/home/devuser/.local/bin:${PATH}" && \
    uv python install $PYTHON_VERSIONS'

ENV PATH="/home/devuser/.local/bin:${PATH}"

######################
#~   Golang Setp   ~#
######################

RUN apt-get update && apt-get install -y wget tar && \
    wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz && \
    rm go1.25.0.linux-amd64.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV PATH=$PATH:/usr/local/go/bin
ENV PATH=$PATH:/home/devuser/go/bin


###################
#~    NODE / JS  ~#
###################

# Set environment variables for NVM and Node
ENV NVM_DIR=/home/devuser/.nvm
ENV NODE_VERSION=22

# We source nvm here to ensure nvm install works in this single RUN command.
# NOTE: I dont fully understand why the `. "$NVM_DIR/nvm.sh"` command seems to be necessary
# every time you use nvm in the dockerfile. Wierd magics going on.
RUN gosu devuser bash -c '\
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "$NODE_VERSION"'

ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"    

# Additionally install pnpm
RUN gosu devuser bash -c '\
    wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -'

#######################
#~   VS CODE Setup   ~#
#######################

# NOTE: VS Code server is not set to always run in this container. It could, but
# at the moment it is used to 1) pre-download VS Code extensions, and 2) Have
# the VS Code server already installed when you go to Remote-SSH connect

# This is apparently how you install VS Code server
RUN gosu devuser mkdir -p /home/devuser/local/share/code-server
RUN gosu devuser wget -O /tmp/vscode-server.tar.gz https://update.code.visualstudio.com/latest/server-linux-x64/stable && \
    gosu devuser tar -xzf /tmp/vscode-server.tar.gz -C /home/devuser/local/share/code-server --strip-components=1 && \
    gosu devuser rm /tmp/vscode-server.tar.gz

###############
# Debian Apps #
###############

# Note: this is running as root instead of devuser
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    bat \
    openssh-server \
    tmux \
    gnupg \
    ripgrep \
    fzf \
    nano \
    neovim \
    # libpng-dev is a library for PNG image support, commonly required by
    # Python packages that work with images (ie. Pillow)
    libpng-dev \
    # build-essential is a package that includes the GCC compiler, make, and other tools
    build-essential \
    # zlib1g-dev is a library for compression, commonly required by
    # Python packages that work with compression
    zlib1g-dev \
    ncurses-term \
    # figlet/toilet are only here because I'm a contributor to PyFiglet.
    figlet \
    toilet \
    hugo \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

###################
#~  ZOXIDE SETUP ~#
###################

RUN gosu devuser bash -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
RUN gosu devuser bash -c 'echo "eval \"$(zoxide init bash)\"" >> ~/.bashrc'

#########################
#~  PYTHON TOOLS SETUP ~#
#########################

RUN gosu devuser uv tool install poetry && \
    gosu devuser uv tool install nox && \
    gosu devuser uv tool install rust-just && \
    gosu devuser uv tool install rich-cli && \
    gosu devuser uv tool install ducktools-pytui && \
    gosu devuser uv tool install harlequin && \
    gosu devuser uv tool install textual-dev && \
    gosu devuser uv tool install cloctui && \
    gosu devuser bash -c '(cd ~/.py_help && uv sync)'
    # The last command needs `bash -c` because it involves `cd` and `&&` within the same
    # logical unit. While `SHELL` instruction handles the outer `RUN`,
    # nested shell logic often benefits from explicit `bash -c`.
    # I honestly cannot claim to understand it. But some of these commands just
    # refuse to work without it, and I don't fully comprehend why. ¯\_(ツ)_/¯

#################
# Homebrew Apps #
#################

RUN gosu devuser brew install \
    cloc \
    lazygit \
    gopass


# #################
# # Node/NPM Apps #
# #################

# NOTE: This is commented out since its standard practice in modern
# javascript to not bother installing any tools globally. All JS
# tools should either be run directly with npx or installed locally per project.

# RUN gosu devuser bash -c 'pnpm install --global \
#     gulp-cli \
#     serve \
#     blowfish-tools'

############################
#~   VS CODE Extensions   ~#
############################

RUN gosu devuser /home/devuser/local/share/code-server/bin/code-server \
    --install-extension visualstudioexptteam.vscodeintellicode \
    --install-extension ms-python.python \
    --install-extension github.copilot \
    --install-extension eamodio.gitlens \
    # Ruff for Python:
    --install-extension charliermarsh.ruff \
    # Markdown linter:
    --install-extension davidanson.vscode-markdownlint \
    # Ultimate Hover, improves hover pop-ups:
    --install-extension szpro.ultimatehover \
    # Docker support:
    --install-extension ms-azuretools.vscode-docker \
    # YAML support:
    --install-extension redhat.vscode-yaml \
    # TOML support:
    --install-extension tamasfe.even-better-toml \
    # TCSS (Textual for Python) suport:
    --install-extension textualize.textual-syntax-highlighter \
    # Justfile support:
    --install-extension kokakiwi.vscode-just

#####################
#~   Golang Apps   ~#
#####################

RUN gosu devuser go install github.com/gopasspw/git-credential-gopass@latest

##################
#~  GIT CONFIG  ~#
##################

ENV GNUPGHOME=/home/devuser/.gnupg

# Make sure the folder exists with correct permissions
RUN mkdir -p "$GNUPGHOME" \
    && chown -R devuser:devuser "$GNUPGHOME" \
    # GnuPG requires the .gnupg directory to have 700 permissions
    # 700 means only the owner can read, write, and execute
    && chmod 700 "$GNUPGHOME"

RUN gosu devuser git config --global core.excludesfile /home/devuser/.gitignore_global && \
    gosu devuser git config --global credential.helper gopass

###########    
# CLEANUP #
###########

ENV DEBIAN_FRONTEND=dialog