#!/bin/ash

# Syntax: ./common-alpine.sh <install zsh flag> <username> <user UID> <user GID> 

USERNAME=$1
USER_UID=$2
USER_GID=$3

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run a root. Use sudo or set "USER root" before running the script.'
    exit 1
fi

# Install git, bash, dependencies, and add a non-root user
apk add --no-cache \
    git \
    build-base \
    fish \
    bash \
    curl \
    shadow

# Clear the file
echo "" > /etc/apk/repositories

# Install brew dependencies
echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/main" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/community" >> /etc/apk/repositories

apk add --no-cache \
    libc6-compat \
    ruby \
    ruby-bigdecimal \
    ruby-etc \
    ruby-irb \
    ruby-json \
    ruby-test-unit    

# Clear the file
echo "" > /etc/apk/repositories

# Add the right repo
echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories


# Create or update a non-root user to match UID/GID - see https://aka.ms/vscode-remote/containers/non-root-user.
if [ "$USER_UID" = "" ]; then
    USER_UID=1000
fi 

if [ "$USER_GID" = "" ]; then
    USER_GID=1000
fi 

if [ "$USERNAME" = "" ]; then
    USERNAME=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)
fi

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
    useradd -s /bin/ash -K MAIL_DIR=/dev/null --uid $USER_UID --gid $USER_GID -m $USERNAME
fi

# Add add sudo support for non-root user
apk add --no-cache sudo
echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

mkdir -p /root/.config/fish
mkdir -p /home/$USERNAME/.config/fish

touch /root/.config/fish/config.fish
touch /home/$USERNAME/.config/fish/config.fish

# Ensure ~/.local/bin is in the PATH for root and non-root users for bash
echo "set -x -g PATH \$PATH \$HOME/.local/bin" | tee -a /root/.config/fish/config.fish >> /home/$USERNAME/.config/fish/config.fish
chown -R $USER_UID:$USER_GID /home/$USERNAME/.config
