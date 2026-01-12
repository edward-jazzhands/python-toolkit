# ░       ░░░        ░░  ░░░░  ░░░░░░░░       ░░░░      ░░░       ░░░░      ░░░        ░
# ▒  ▒▒▒▒  ▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒
# ▓  ▓▓▓▓  ▓▓      ▓▓▓▓▓  ▓▓  ▓▓▓▓▓▓▓▓▓       ▓▓▓  ▓▓▓▓  ▓▓       ▓▓▓  ▓▓▓   ▓▓      ▓▓▓
# █  ████  ██  ██████████    ██████████  ████  ██        ██  ███  ███  ████  ██  ███████
# █       ███        █████  ███████████       ███  ████  ██  ████  ███      ███        █
                                                                                                                                   
# Dockerfile responsibilities:

#     Base OS + system packages
#     Language runtimes (Python, Node, Go)
#     Package managers (uv, npm, etc.) with configs pointing to $HOME
#     CLI tools (tmux, fzf, zoxide, Oh My Zsh)
#     Sane default dotfiles (copied on first run via init script)
#     fixuid setup
    
# User responsibilities (via bind mount + scripts):
    
#     /home/coder bind mount for persistence
#     Optional bootstrap.sh for their preferred global tools
#     Code-Server extensions
#     Personal config overrides


# Start from the code-server Debian base image
FROM codercom/code-server:latest

# Current version of the container
LABEL version="0.6.1"
LABEL maintainer="ed.jazzhands@gmail.com"
LABEL description="Dev Barge Container by Edward Jazzhands"
LABEL org.opencontainers.image.source="https://github.com/edward-jazzhands/dev-barge"
LABEL org.opencontainers.image.licenses="MIT"

USER root

# SHELL for bash features during dockerfile build
SHELL ["/bin/bash", "-c"]

# Set non-interactive
ENV DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Github CLI (This must go before the gh install using apt-get, below)
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# These apt apps already included in base image:
# curl \ dumb-init \ git \ git-lfs \ htop \ locales \ lsb-release \ 
# man-db \ nano \ openssh-client \ procps \ sudo \ vim-tiny \ wget \ zsh \


RUN apt-get update && apt-get install -y --no-install-recommends \
    # --force-confdef = (Force configuration defaults)
    # --force-confold = (Force keep old files during upgrades)
    # Together these two settings prevent any interactive prompts during package installation
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    # tar \
    make \
    bat \
    tmux \
    ripgrep \
    fzf \
    neovim \
    ncurses-term \
    gh \
    # gnupg \
    # gosu \
    ca-certificates \
    # libpng-dev is a library for PNG image support, 
    # commonly required by Python packages that work with images (ie. Pillow)
    libpng-dev \
    # libssl-dev is a library for OpenSSL, which is required by many Python packages:
    libssl-dev \
    # build-essential is a package that includes the GCC compiler, make, and other tools
    build-essential \
    # zlib1g-dev is a library for compression,
    # commonly required by Python packages that work with compression
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/*


#########################
# ~ UV / Python Setup ~ #
#########################

# UV by default uses hardlinks for cache and virtual environments.
# But this is inside a container where the projects are bind mounted.
# This means the UV cache folder will be on a different file system than
# the projects themselves. So we want to tell it to copy files into each
# venv instead of hardlinking. If this is not set, UV will do this
# anyway (hardlink creation will not work and it will revert to copying),
# but it will print a warning every single time, which is annoying
# and may confuse some people.
# ENV UV_LINK_MODE=copy

# This is here for reference, but not used. This stays as the default.
# ENV UV_CACHE_DIR=/usr/local/uv/cache

# The directory in which to install uv using the standalone installer and
# self update feature. Defaults to ~/.local/bin.
ENV UV_INSTALL_DIR=/usr/local/bin

# Specifies the directory to place links to installed, managed Python executables.
ENV UV_PYTHON_BIN_DIR=/usr/local/bin

# Specifies the directory for caching the archives of managed Python installations before installation.
# ENV UV_PYTHON_CACHE_DIR=/usr/local/uv/python_cache

# Whether to install the Python executable into the ENV UV_PYTHON_BIN_DIR= directory.
ENV UV_PYTHON_INSTALL_BIN=1

# Specifies the directory for storing managed Python installations.
ENV UV_PYTHON_INSTALL_DIR=/usr/local/uv/python_installs

# Specifies the "bin" directory for installing tool executables.
# ENV UV_TOOL_BIN_DIR=/usr/local/bin

# Specifies the directory where uv stores managed tools.
# ENV UV_TOOL_DIR=/usr/local/uv/tools

# Poetry by default creates virtual environments in its own cache location.
# We want it to instead create .venv folders inside the project directory.
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

RUN mkdir -p /usr/local/uv/python_installs

ARG PYTHON_VERSIONS="3.10 3.14 3.14t"

RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv python install $PYTHON_VERSIONS


#################
#~  NODE / JS  ~#
#################

ENV NODE_VERSION=22
ENV PATH="$PNPM_HOME:$PATH"
ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

# nvm's installation directory.
ENV NVM_DIR=/usr/local/nvm

# where node, npm, and global packages for the active version of node are installed.
ENV NVM_BIN=/usr/local/nvm/versions/node/v$NODE_VERSION/bin

# node's include file directory (useful for building C/C++ addons for node).
ENV NVM_INC=/usr/local/nvm/versions/node/v$NODE_VERSION/include/node

# pnpm's installation directory.
ENV PNPM_HOME=/usr/local/pnpm

RUN mkdir -p /usr/local/nvm/versions/node/v$NODE_VERSION/bin && \
    mkdir -p /usr/local/nvm/versions/node/v$NODE_VERSION/include/node && \
    mkdir -p /usr/local/pnpm

# NVM. NOTE: We need this to run as a self contained bash command here because
# NVM requires its own bash init script to be sourced in order to work.
RUN bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "$NODE_VERSION" && \
    nvm cache clear && \
    npm cache clean --force'

    # PNPM
RUN wget -qO- https://get.pnpm.io/install.sh | bash


##########
# Golang #
##########

# Download + install Go SDK
RUN wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz && \
    rm go1.25.0.linux-amd64.tar.gz

# ENV GOCACHE="/usr/local/go/cache/go-build"
# ENV GOMODCACHE="/usr/local/go/cache/go-mod"
ENV GOPATH="/usr/local/go"
ENV GOROOT="/usr/local/go"
# ENV GOTOOLDIR="/usr/local/go/pkg/tool/linux_amd64"

ENV PATH="/usr/local/go/bin:/usr/local/go/pkg/tool/linux_amd64:$PATH"

# NOTE: config folder should stay in home dir. Here for reference.
# ENV GOENV="/usr/local/go/config/go/env"
# ENV GOTELEMETRYDIR="/usr/local/go/config/telemetry"

# RUN mkdir -p /usr/local/go/cache/go-build && \
    # mkdir -p /usr/local/go/cache/go-mod && \
    # mkdir -p /usr/local/go/config/go/env && \
    # mkdir -p /usr/local/go/config/telemetry
    # chown -R devuser:devuser /usr/local/go

    
##############
# S6-Overlay #
##############

# Download S6-overlay
RUN wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v3.2.1.0/s6-overlay-noarch.tar.xz && \
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v3.2.1.0/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz
    
# NOTE: In s6-overlay, the folder structure itself IS the configuration.
# You can't see that here since I just copy the entire folder structure.
COPY /s6-overlay/s6-rc.d/ /etc/s6-overlay/s6-rc.d

# Remember to add new services here as well:
RUN chmod +x /etc/s6-overlay/s6-rc.d/init-script/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-script/init.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/gunicorn/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/code-server/run

######################
# Dev-Help and Admin #
######################

# devhelp is the container's custom help splash. It can be called with `devhelp`.
COPY /devhelp /usr/local/devhelp

RUN cd /usr/local/devhelp && \
    uv sync --no-editable --locked && \
    uv cache clean && \
    chmod -R a+rX . && \
    find . -type d -name ".venv" -prune -o -type f -exec chmod 775 {} +
    
    # Nukes ACLs; || true if no setfacl in base image
    # setfacl -b -R . || true  

# ptk-admin-panel is the container's admin panel. It is a web app built with
# Flask and React. It is started with the container by S6-Overlay and served
# on port 5000.
# This is at the end of the file because it's a git submodule, and it needs
# to be improved without affecting the rest of the image.

COPY /ptk-admin-panel /usr/local/ptk-admin-panel

RUN cd /usr/local/ptk-admin-panel && \
    uv sync --no-editable --locked && \
    uv cache clean && \
    chmod -R a+rX . && \
    find . -type d -name ".venv" -prune -o -type f -exec chmod 775 {} +
    # Nukes ACLs; || true if no setfacl in base image
    # setfacl -b -R . || true  

################
# Finilization #
################

# These can change fairly frequently, so it goes near the end of the file.
COPY /default-configs/ /default-configs

# Oh My Zsh installs as coder user
# USER coder
# RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
#     | sh -s -- --unattended

# Docker info
EXPOSE 8080 8081 8082

# Port
ENV PORT=8080

# (From Code-Server original - Entrypoint script is now run by s6-overlay)
# Use our custom entrypoint script first
# COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
# ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]

# The /init is set up by S6-Overlay. It will create this file
# This overrides the ENTRYPOINT set by the code-server base image
ENTRYPOINT ["/init"]

# Healthcheck will check whether S6-Overlay is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep s6-svscan || exit 1

# Set back to dialog for root
ENV DEBIAN_FRONTEND=dialog

USER coder
ENV SHELL=/bin/zsh
ENV DEBIAN_FRONTEND=dialog

