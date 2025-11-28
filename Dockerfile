####################################
#~ PROGRAMMING TOOLKIT DOCKERFILE ~#
####################################

# ███████████████████████████████
# █                             █
# █  ▄   ▘▜  ▌      ▄▖▗         █
# █  ▙▘▌▌▌▐ ▛▌█▌▛▘  ▚ ▜▘▀▌▛▌█▌  █
# █  ▙▘▙▌▌▐▖▙▌▙▖▌   ▄▌▐▖█▌▙▌▙▖  █
# █                       ▄▌    █
# █                             █
# ███████████████████████████████

# Use multi-stage build for downloading large archives
FROM debian:bookworm-slim AS builder

# Set non-interactive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Download Go SDK
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates && \
    wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz

# Download S6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.2.1.0/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.2.1.0/s6-overlay-x86_64.tar.xz /tmp


# ███████████████████████████████
# █                             █
# █   ▄▖         ▌  ▄▖▗         █
# █   ▚ █▌▛▘▛▌▛▌▛▌  ▚ ▜▘▀▌▛▌█▌  █
# █   ▄▌▙▖▙▖▙▌▌▌▙▌  ▄▌▐▖█▌▙▌▙▖  █
# █                       ▄▌    █
# █                             █
# ███████████████████████████████


FROM debian:bookworm-slim

# SHELL for bash features
SHELL ["/bin/bash", "-c"]

# Set non-interactive
ENV DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

LABEL maintainer="ed.jazzhands@gmail.com"
LABEL version="0.6.0"
LABEL description="The Programming Toolkit Container by Edward Jazzhands"

LABEL org.opencontainers.image.source="https://github.com/edward-jazzhands/programming-toolkit"
LABEL org.opencontainers.image.licenses="MIT"

# This does not actually enable the ports, it's only metadata for Docker.
# Technically it's not even necessary for this to be here.
EXPOSE 22 5000 5001 5002

# Healthcheck will check whether S6-Overlay is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep s6-svscan || exit 1

# The /init is set up by S6-Overlay. It will create this file
ENTRYPOINT ["/init"]

# WORKDIR sets the working directory for the container. Once set,
# all RUN commands will be executed in this directory
WORKDIR /home/devuser

######################
#~   USER CONFIG    ~#
######################

# If building the image locally, you can pass in the UID/GID
# of the user you want to create.
# These can still be overridden by the environment variables
# PUID and PGID on container run. But it may be more convenient
# to set them here if building locally.
ARG PUID=3001
ARG PGID=3000

COPY /default-configs/ /default-configs

# ptk-help is the container's custom help splash. It is configured to
# show on login in the .bash_profile file and can be called with `ptk-help`
COPY /ptk-help /ptk-help

RUN groupadd -g ${PGID} devuser && \
    # -m forces creation of a home directory  |  -u sets the UID
    # -g sets the group. Group must already exist (we created it above).
    # -s sets the user’s login shell
    useradd -m -u ${PUID} -g devuser -s /bin/bash devuser && \
    # -R means recursive.
    chown -R devuser:devuser /home/devuser && \
    chown -R devuser:devuser /ptk-help && \
    chown -R devuser:devuser /default-configs && \
    # Add devuser to sudoers:
    echo 'devuser ALL=(root) ALL' >> /etc/sudoers

######################
#~     SSH SETUP    ~#
######################

COPY /required-configs/sshd_config /etc/ssh/sshd_config

RUN mkdir /run/sshd && \
    # SSH Server wants the following permissions and ownership
    # Owner has full, others have read/write:
    chmod 755 /run/sshd && \
    # Owner has full, others have no access:
    chmod 700 /etc/ssh && \
    # Owner can read/write, others have no access:
    chmod 600 /etc/ssh/sshd_config && \
    # Set owner to root for sshd_config and /run/sshd dir:
    chown root:root /etc/ssh/sshd_config && \
    chown -R root:root /run/sshd

######################
#~    APPS SETUP    ~#
######################


# GitHub CLI setup (moved up for apt consolidation)
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Consolidated apt installs (all packages in one RUN; includes gh)
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --force-confdef = (Force configuration defaults)
    # --force-confold = (Force keep old files during upgrades)
    # Together these two settings prevent any interactive prompts during package installation
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    ca-certificates \
    sudo \
    wget \
    curl \
    tar \
    git \
    gosu \
    make \
    bat \
    openssh-server \
    tmux \
    gnupg \
    ripgrep \
    fzf \
    nano \
    neovim \
    btop \
    ncurses-term \
    figlet \
    toilet \
    hugo \
    gh \
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

# Copy from builder stage (avoids baking downloads into final layers)
# NOTE: try changing Go dir to /opt/go
COPY --from=builder /usr/local/go /usr/local/go/
COPY --from=builder /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
COPY --from=builder /tmp/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-x86_64.tar.xz

#########################
# ~ Code-Server Setup ~ #
#########################

#! NOTE: This MUST run as root
RUN curl -fsSL https://code-server.dev/install.sh | sh && \
    # I am not sure that it creates any folders in the devuser home dir
    # when it installs. But it's here just in case.
    chown -R devuser:devuser /home/devuser

# NOTE: The devuser/.config and devuser/.local/share/code-server folders
# persist data between container runs when they are bind mounted to the host
# (or if the entire home dir is bind mounted).

######################
# ~ Homebrew Setup ~ #
######################

ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV MANPATH="/home/linuxbrew/.linuxbrew/share/man${MANPATH+:$MANPATH}:"
ENV INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"

# Create Homebrew directory with proper ownership
RUN mkdir -p /home/linuxbrew && \
    chown -R devuser:devuser /home/linuxbrew

RUN gosu devuser bash -c "NONINTERACTIVE=1 $(curl -fsSL \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

RUN gosu devuser brew install cloc lazygit gopass && \
    gosu devuser brew cleanup -s --prune=0

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
ENV UV_LINK_MODE=copy

ENV UV_CACHE_DIR=/opt/uv/cache

# The directory for storage of credentials when using a plain text backend.
ENV UV_CREDENTIALS_DIR=/opt/uv/credentials

# The directory in which to install uv using the standalone installer and
# self update feature. Defaults to ~/.local/bin.
ENV UV_INSTALL_DIR=/opt/uv/bin

# Specifies the directory to place links to installed, managed Python executables.
ENV UV_PYTHON_BIN_DIR=/opt/uv/python_bin

# Specifies the directory for caching the archives of managed Python installations before installation.
ENV UV_PYTHON_CACHE_DIR=/opt/uv/python_cache

# Whether to install the Python executable into the ENV UV_PYTHON_BIN_DIR= directory.
ENV UV_PYTHON_INSTALL_BIN=1

# Specifies the directory for storing managed Python installations.
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python_installs

# Specifies the "bin" directory for installing tool executables.
ENV UV_TOOL_BIN_DIR=/opt/uv/tool_bin

# Specifies the directory where uv stores managed tools.
ENV UV_TOOL_DIR=/opt/uv/tools

# Specifies the directory where uv stores pyx credentials.
ENV PYX_CREDENTIALS_DIR=/opt/uv/pyx_credentials

# Equivalent to the --break-system-packages command-line argument. If set to true, uv will 
# allow the installation of packages that conflict with system-installed packages.
# WARNING: UV_BREAK_SYSTEM_PACKAGES=true is intended for use in continuous integration (CI) 
# or containerized environments and should be used with caution, as modifying the system 
# Python can lead to unexpected behavior.
ENV UV_BREAK_SYSTEM_PACKAGES=1

# Poertry by default creates virtual environments in its own cache location.
# We want it to instead create .venv folders inside the project directory.
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

ENV PATH="/opt/uv/bin:/opt/uv/tool_bin:${PATH}"

RUN mkdir -p /opt/uv/{cache,credentials,bin,python_bin,python_cache,python_installs,tool_bin,tools,pyx_credentials} && \
    chown -R devuser:devuser /opt/uv

ARG PYTHON_VERSIONS="3.10 3.11 3.12 3.13 3.14"

RUN gosu devuser bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv python install $PYTHON_VERSIONS'

# Python tools + project syncs + cleanup
RUN gosu devuser bash -c 'uv tool install poetry && \
    uv tool install nox && \
    uv tool install rust-just && \
    uv tool install rich-cli && \
    uv tool install ducktools-pytui && \
    uv tool install harlequin && \
    uv tool install textual-dev && \
    uv tool install cloctui && \
    cd /ptk-help && uv sync && \
    uv cache clean'

#################
#~  NODE / JS  ~#
#################

# nvm's installation directory.
ENV NVM_DIR=/opt/nvm

# where node, npm, and global packages for the active version of node are installed.
ENV NVM_BIN=/opt/nvm/versions/node/v$NODE_VERSION/bin

# node's include file directory (useful for building C/C++ addons for node).
ENV NVM_INC=/opt/nvm/versions/node/v$NODE_VERSION/include/node

# pnpm's installation directory.
ENV PNPM_HOME=/opt/pnpm

ENV NODE_VERSION=22
ENV PATH="$PNPM_HOME:$PATH"
ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

RUN mkdir -p /opt/nvm/versions/node/v$NODE_VERSION/bin && \
    mkdir -p /opt/nvm/versions/node/v$NODE_VERSION/include/node && \
    mkdir -p /opt/pnpm && \
    chown -R devuser:devuser /opt/nvm && \
    chown -R devuser:devuser /opt/pnpm

# NVM
RUN gosu devuser bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "$NODE_VERSION" && \
    nvm cache clear && \
    npm cache clean --force'

    # PNPM
RUN gosu devuser bash -c 'wget -qO- https://get.pnpm.io/install.sh | bash - && \
    pnpm store prune'

RUN printf "\n\n" >> /etc/bash.bashrc && \
    printf '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /etc/bash.bashrc && \
    printf "\n\n" >> /etc/bash.bashrc && \
    printf '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /etc/bash.bashrc

##########
# Zoxide #
##########

RUN gosu devuser bash -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'

# Remember that modifying /etc/bash.bashrc must be done as root:
RUN printf "\n\n" >> /etc/bash.bashrc && \
    printf 'eval "$(zoxide init bash)"' >> /etc/bash.bashrc

##########
# Golang #
##########

ENV PATH="/usr/local/go/bin:${PATH}"

ENV GOCACHE="/opt/go/cache/go-build"
ENV GOMODCACHE="/opt/go/cache/go-mod"
ENV GOPATH="/opt/go"

# NOTE: config folder should stay in home dir
# ENV GOENV="/opt/go/config/go/env"
# ENV GOTELEMETRYDIR="/opt/go/config/telemetry"

# NOTE: not changing the default go install dir as of right now.
# Try changing it to /opt/go/sdk in the future.
ENV GOROOT="/usr/local/go"
ENV GOTOOLDIR="/usr/local/go/pkg/tool/linux_amd64"

RUN mkdir -p /opt/go/cache/go-build && \
    mkdir -p /opt/go/cache/go-mod && \
    mkdir -p /opt/go/config/go/env && \
    mkdir -p /opt/go/config/telemetry && \
    chown -R devuser:devuser /opt/go

# Golang apps + optional mod cache cleanup (uncomment if mod cache not needed in image)
RUN gosu devuser bash -c \
    'go install github.com/gopasspw/git-credential-gopass@latest && \
    go clean -modcache'
    

###############
# GNUPG / GCM #
###############

# This is because git credential manager expects a program called
# 'libicu' to be available in the system to handle internationalization
# (ie. characters from other languages).
# This program is fairly large and is not needed at the moment.
# This will make it ignore the error and continue running.
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

ENV GNUPGHOME=/opt/gnupg

RUN mkdir -p "$GNUPGHOME" && \
    chown -R devuser:devuser "$GNUPGHOME" && \
    chmod 700 "$GNUPGHOME"

##############
# S6-Overlay #
##############

COPY /s6-overlay/s6-rc.d/ /etc/s6-overlay/s6-rc.d

RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay*.tar.xz && \
    # Remember to add new apps here as well:
    chmod +x /etc/s6-overlay/s6-rc.d/init-script/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-script/run.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/sshd/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/gunicorn/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/code-server/run


###################
# PTK Admin Panel #
###################

# ptk-admin-panel is the container's admin panel. It is a web app built with
# Flask and React. It is started with the container by S6-Overlay and served
# on port 5000.
# This is at the end of the file because it's a git submodule, and it needs
# to be improved without affecting the rest of the image. So we cache it last.

COPY /ptk-admin-panel /ptk-admin-panel

# NOTE: This possibly does not need to run as devuser. Experiment
# with running this as root instead.
RUN chown -R devuser:devuser /ptk-admin-panel && \
    gosu devuser bash -c \
    '(cd /ptk-admin-panel && uv sync && uv cache clean)'

###########
# Cleanup #
###########

# Capture all ENV variables (excluding some problematic ones) and write to /etc/environment
RUN env | grep -v "^HOME=" | grep -v "^PWD=" | grep -v "^SHLVL=" | grep -v "^_=" | grep -v "^HOSTNAME=" > /etc/environment

# This will configure PAM (Pluggable Authentication Modules) to allow reading environment
# variables from the user's environment. This is necessary for SSH to preserve the PATH
# variable and all other env vars created in the container.
RUN sed -i '/pam_env.so # \[1\]/s/pam_env.so/pam_env.so readenv=1 user_readenv=1/' /etc/pam.d/sshd

ENV DEBIAN_FRONTEND=dialog

