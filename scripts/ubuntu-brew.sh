#!/usr/bin/env bash

# Syntax: ./common-debian.sh <username> <user UID> <user GID>

set -e

USERNAME=${1:-"$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"}
USER_UID=${2:-1000}
USER_GID=${3:-1000}

if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run a root. Use sudo or set "USER root" before running the script.'
    exit 1
fi

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Get to latest versions of all packages
apt-get -y upgrade

# Install common dependencies
apt-get -y install --no-install-recommends \
    build-essential \
    software-properties-common \
    git \
    curl \
    locales

# Ensure at least the en_US.UTF-8 UTF-8 locale is available.
# Common need for both applications and things like the agnoster ZSH theme.
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen 
locale-gen

# Install libssl1.1 if available
if [[ ! -z $(apt-cache --names-only search ^libssl1.1$) ]]; then
    apt-get -y install  --no-install-recommends libssl1.1
fi
 
# Install appropriate version of libssl1.0.x if available
LIBSSL=$(dpkg-query -f '${db:Status-Abbrev}\t${binary:Package}\n' -W 'libssl1\.0\.?' 2>&1 || echo '')
if [ "$(echo "$LIBSSL" | grep -o 'libssl1\.0\.[0-9]:' | uniq | sort | wc -l)" -eq 0 ]; then
    if [[ ! -z $(apt-cache --names-only search ^libssl1.0.2$) ]]; then
        # Debian 9
        apt-get -y install  --no-install-recommends libssl1.0.2
    elif [[ ! -z $(apt-cache --names-only search ^libssl1.0.0$) ]]; then
        # Ubuntu 18.04, 16.04, earlier
        apt-get -y install  --no-install-recommends libssl1.0.0
    fi
fi

echo "Creating user"

# Create or update a non-root user to match UID/GID - see https://aka.ms/vscode-remote/containers/non-root-user.
if id -u $USERNAME > /dev/null 2>&1; then
    # User exists, update if needed
    if [ "$USER_GID" != "$(id -G $USERNAME)" ]; then 
        groupmod --gid $USER_GID $USERNAME 
        usermod --gid $USER_GID $USERNAME
    fi
    if [ "$USER_UID" != "$(id -u $USERNAME)" ]; then 
        usermod --uid $USER_UID $USERNAME
    fi
else
    # Create user
    groupadd --gid $USER_GID $USERNAME
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME
fi

# Add add sudo support for non-root user
apt-get install -y sudo
echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

mkdir -p /root/.config/fish
mkdir -p /home/$USERNAME/.config/fish

touch /root/.config/fish/config.fish
touch /home/$USERNAME/.config/fish/config.fish

# Ensure ~/.local/bin is in the PATH for root and non-root users for bash
echo "set -x -g PATH \$PATH \$HOME/.local/bin" | tee -a /root/.config/fish/config.fish >> /home/$USERNAME/.config/fish/config.fish
chown -R $USER_UID:$USER_GID /home/$USERNAME/.config
