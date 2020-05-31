#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
FROM alpine:3.12

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Location common setup script
ARG COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/claudioluciano/devcontainers/master/scripts/alpine-brew-fish.sh"

# Install git, bash, dependencies, and add a non-root user
RUN apk update \
    && apk add --no-cache wget coreutils ca-certificates \
    #
    # common tools / libs installed, add/modify non-root user
    && wget -q -O /tmp/common-setup.sh $COMMON_SCRIPT_SOURCE \
    && /bin/ash /tmp/common-setup.sh "$USERNAME" "$USER_UID" "$USER_GID" \
    && rm /tmp/common-setup.sh

USER "$USERNAME"

# Install brew
ARG VAR_PATH=$PATH
ENV PATH=/home/linuxbrew/.linuxbrew/bin:$VAR_PATH
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
        && brew install -s patchelf \
        && brew install --ignore-dependencies binutils gmp isl@0.18 libmpc linux-headers mpfr zlib \
        && (brew install --ignore-dependencies gcc || true) \
        && brew install glibc \
        && brew postinstall gcc \
        && brew remove patchelf \
        && brew install -s patchelf \
        && brew config

# update PATH with brew path
RUN echo "set -x -g PATH /home/linuxbrew/.linuxbrew/bin $PATH" >> ~/.config/fish/config.fish

# Install starship prompt
RUN brew install starship

# Make fish use the prompt
RUN echo "starship init fish | source" >> ~/.config/fish/config.fish