###################
#~  OS AND APPS  ~#
###################

FROM debian:bookworm-slim
SHELL ["/bin/bash", "-c"]
ARG PYTHON_VERSIONS="3.8 3.9 3.10 3.11 3.12 3.13"

# WORKDIR is the default working directory for RUN, CMD,
# ENTRYPOINT, COPY, and ADD instructions. It is set here because?
# ?????????
WORKDIR /home/devuser/workspace


RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sudo \
    wget \
    tar \
    make \
    bat \
    openssh-server \
    git \
    tmux \
    gosu \
    gnupg \
    libssl-dev \
    ca-certificates \
    ripgrep \
    fzf \
    nano \
    neovim \
    libpng-dev \
    build-essential \
    zlib1g-dev \
    ncurses-term \
    # figlet/toilet are only here because I'm a contributor to PyFiglet.
    figlet \
    toilet \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the .bashrc file and other config files
COPY /to_copy_in/py_help /home/devuser/.py_help
COPY /to_copy_in/.bashrc /home/devuser/.bashrc
COPY /to_copy_in/.profile /home/devuser/.profile
COPY /to_copy_in/.tmux.conf /home/devuser/.tmux.conf
COPY /to_copy_in/.justfile /home/devuser/.justfile
COPY /to_copy_in/.gitconfig /home/devuser/.gitconfig
COPY /to_copy_in/.gitignore_global /home/devuser/.gitignore_global
COPY /to_copy_in/.launch.sh /home/devuser/.launch.sh

# 568:568 is the default for TrueNAS apps
RUN groupadd -g 568 devuser && \
    useradd -m -u 568 -g devuser -s /bin/bash devuser && \
    chown -R 568:568 /home/devuser && \
    echo 'devuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# GNUPGHOME is the directory where GnuPG stores its configuration and keyrings.
# This allows for storing the GPG keys in the data storage of the container/
# server that gets bind mounted into the container, so we can reuse the keys
# across container restarts and updates.
ENV GNUPGHOME=/home/devuser/workspace/.gnupg

# Make sure the folder exists with correct permissions
RUN mkdir -p "$GNUPGHOME" \
    && chown -R devuser:devuser "$GNUPGHOME" \
    && chmod 700 "$GNUPGHOME"

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

################################
# ~ GENERIC PACKAGE MANAGERS ~ #
################################

# --- Homebrew Installation ---
RUN gosu devuser bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/devuser/.bashrc

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Install Homebrew packages
RUN gosu devuser brew install \
    --cask git-credential-manager \
    cloc \
    lazygit \
    gopass

###################
# ~ UV / Python ~ #
###################

RUN gosu devuser bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

ENV PATH="/home/devuser/.local/bin:${PATH}"

RUN gosu devuser uv python install $PYTHON_VERSIONS && \
    gosu devuser uv tool install poetry && \
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

###################
#~    NODE / JS  ~#
###################

# Set environment variables for NVM and Node
ENV NVM_DIR=/home/devuser/.nvm
ENV NODE_VERSION=22

# We source nvm here to ensure nvm install works in this single RUN command.
RUN gosu devuser bash -c '\
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "$NODE_VERSION"'

ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"    

# RUN gosu devuser bash -c '\
#     . "$NVM_DIR/nvm.sh" && \
#     npm install --global gulp-cli'

RUN gosu devuser bash -c '. "$NVM_DIR/nvm.sh"'

RUN gosu devuser npm install --global \
    gulp-cli \
    typescript \
    serve \
    hugo \
    blowfish-tools

# If you needed to use `nvm` functions (like `nvm use` or `nvm alias`) in *another* RUN command,
# you would still need to source nvm.sh again for that specific RUN command's shell.
# For example:
# RUN . "$NVM_DIR/nvm.sh" && nvm use 18 # if you wanted to switch versions in a build step    

#######################
#~   VS CODE STUFF   ~#
#######################

RUN gosu devuser mkdir -p /home/devuser/local/share/code-server
RUN gosu devuser wget -O /tmp/vscode-server.tar.gz https://update.code.visualstudio.com/latest/server-linux-x64/stable && \
    gosu devuser tar -xzf /tmp/vscode-server.tar.gz -C /home/devuser/local/share/code-server --strip-components=1 && \
    gosu devuser rm /tmp/vscode-server.tar.gz

# Install extensions
RUN gosu devuser /home/devuser/local/share/code-server/bin/code-server \
    --install-extension ms-python.python \
    --install-extension github.copilot \
    --install-extension charliermarsh.ruff \
    --install-extension davidanson.vscode-markdownlint \
    --install-extension eamodio.gitlens \
    --install-extension szpro.ultimatehover \
    --install-extension visualstudioexptteam.vscodeintellicode \
    --install-extension ms-azuretools.vscode-docker \
    # YAML support
    --install-extension redhat.vscode-yaml \
    # TOML support
    --install-extension tamasfe.even-better-toml \
    # TCSS (Textual) suport
    --install-extension textualize.textual-syntax-highlighter \
    # Justfile support
    --install-extension kokakiwi.vscode-just


###################
#~      GIT      ~#
###################

RUN gosu devuser git config --global core.excludesfile ~/.gitignore_global && \
    gosu devuser git config --global credential.credentialStore gpg

########################
#~ METADATA & EXECUTE ~#
########################
LABEL maintainer="ed.jazzhands@gmail.com"
LABEL version="0.3.0"
LABEL description="Edward Jazzhands Global Development Toolkit Container"
LABEL org.opencontainers.image.source="https://github.com/edward-jazzhands/python-toolkit"
LABEL org.opencontainers.image.licenses="MIT"

# This doesn't actually enable the port, it's only metadata for Docker.
# The port is set in the sshd_config file.
EXPOSE 2222

# Mark as unhealthy if the SSH service goes down
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep sshd || exit 1

ENTRYPOINT ["gosu", "root", "/usr/sbin/sshd", "-D"]