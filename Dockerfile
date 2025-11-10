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
LABEL version="0.4.0"
LABEL description="Edward Jazzhands Programming Toolkit Container"

LABEL org.opencontainers.image.source="https://github.com/edward-jazzhands/programming-toolkit"
LABEL org.opencontainers.image.licenses="MIT"

# This doesn't actually enable the port, it's only metadata for Docker.
# The port is set in the sshd_config file.
#! Test what this actually does to ensure its needed
EXPOSE 22 5000

#########################
#~   INITIAL CONFIG    ~#
#########################

# Mark as unhealthy if the SSH service goes down
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep sshd || exit 1

# This entrypoint launches S6-Overlay. It will create this file.
ENTRYPOINT ["/init"]

# WORKDIR controls what folder you're dropped into if you docker exec
# into the container. I almost never do that but its a small convenience.
WORKDIR /home/devuser

# Here we copy the .bashrc file and other config files.
# This is where you would add in your own config files.
# NOTE: This dockerfile is designed so that essential configs
# are not stored in any of these files. These are all
# personal custom OS settings. I have my own favorite shell shortcuts
# and functions, my tmux settings, my global Justfile, my own git settings, etc.
#! Just ensure there's a .profile or .bash_profile file included!
COPY /home-configs/ /home/devuser

# ptk-help is the container's custom help splash. It is configured to
# show on login in the .bash_profile file
COPY /ptk-help /home/devuser/ptk-help

# ptk-admin-panel
COPY /ptk-admin-panel /home/devuser/ptk-admin-panel

# NOTE: 568:568 is the default for TrueNAS apps.
# You may need to change the user/group ID for your server
# First add group 568 and name it devuser
RUN groupadd -g 568 devuser && \
    # Then add UID 568 named devuser. `-s /bin/bash devuser` -> default shell for devuser
    useradd -m -u 568 -g devuser -s /bin/bash devuser && \
    # Set ownership of /devuser because we created it before the OS got a chance
    # the -R flag makes it recursive (i think?)
    chown -R 568:568 /home/devuser && \
    # This line adds devuser to sudoers as NOPASSWD:
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
    
# Append 2 blank lines to the end of the .bashrc file for formatting
RUN gosu devuser bash -c 'printf "\n\n" >> ~/.bashrc'

######################
#~     SSH SETUP    ~#
######################

COPY sshd_config /etc/ssh/sshd_config

# Copy the password file into the image
COPY password /tmp/password

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

# Append 2 blank lines to the end of the .bashrc file for formatting
RUN gosu devuser bash -c 'printf "\n\n" >> ~/.bashrc'

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

    # Append 2 blank lines to the end of the .bashrc file for formatting
RUN gosu devuser bash -c 'printf "\n\n" >> ~/.bashrc'

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
RUN gosu devuser bash -c 'printf "%s\n" "eval \"\$(zoxide init bash)\"" >> ~/.bashrc'

# Append 2 blank lines to the end of the .bashrc file for formatting
RUN gosu devuser bash -c 'printf "\n\n" >> ~/.bashrc'

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
    gosu devuser bash -c '(cd ~/ptk-help && uv sync)' && \
    gosu devuser bash -c '(cd ~/ptk-admin-panel && uv sync)'
    # The last command needs `bash -c` because it involves `cd`
    # and `&&` within the same logical unit. While `SHELL` instruction
    # handles the outer `RUN`, nested shell logic often requires
    # explicit `bash -c`.

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

##################
#~  GITHUB CLI  ~#
##################

RUN mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt update \
	&& apt install gh -y


##############    
# S6-OVERLAY #
##############


# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.2/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.2/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

RUN chmod +x /etc/s6-overlay/s6-rc.d/sshd/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/gunicorn/run


###########    
# CLEANUP #
###########

ENV DEBIAN_FRONTEND=dialog