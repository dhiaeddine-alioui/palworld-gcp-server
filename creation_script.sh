#!/bin/bash

# Define username and password
USERNAME="serveruser"
PASSWORD="serveruser"

# Create the user with bash as default shell
echo "Creating New user : $USERNAME ..."
sudo deluser --remove-home $USERNAME
sudo useradd -m -s /bin/bash $USERNAME

# Check if user creation was successful
if [ $? -ne 0 ]; then
    echo "Failed to create user."
    exit 1
fi

# Set the password for the user
echo "Setting password ..."
echo -e "$PASSWORD\n$PASSWORD" | sudo passwd $USERNAME

# Check if password setup was successful
if [ $? -ne 0 ]; then
    echo "Failed to set password."
    exit 1
fi

# Add the new user to the sudo group
echo "Add $USERNAME to 'sudo' group ..."
sudo usermod -aG sudo $USERNAME

# Check if adding to sudo group was successful
if [ $? -ne 0 ]; then
    echo "Failed to add user to 'sudo' group."
    exit 1
fi

# Configure sudo to allow passwordless execution for specific commands for the new user
echo "Configure sudo for passwordless execution..."
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/add-apt-repository, /usr/bin/dpkg, /usr/bin/apt, /usr/bin/echo, /usr/bin/debconf-set-selections" | sudo tee /etc/sudoers.d/$USERNAME

# Disable the requirement for a TTY
# echo "Defaults:$USERNAME !requiretty" | sudo tee -a /etc/sudoers.d/$USERNAME


# Switch to the newly created user and execute commands
echo "Switching to user $USERNAME and performing setup..."
sudo -u $USERNAME bash <<EOF
cd ~

# Add multiverse repository and install steamcmd
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo echo steam steam/question select "I AGREE" | sudo debconf-set-selections
sudo echo steam steam/license note '' | sudo debconf-set-selections
sudo apt install steamcmd -y

export PATH=$PATH:/usr/games

# Install steam sdk
mkdir -p ~/.steam/sdk64/
steamcmd +login anonymous +app_update 1007 +quit
cp ~/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so ~/.steam/sdk64/
EOF

# Check if setup was successful
if [ $? -eq 0 ]; then
    echo "Setup completed successfully."
else
    echo "Setup failed."
    exit 1
fi
