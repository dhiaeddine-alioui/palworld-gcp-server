#!/bin/bash

# Define username and password
USERNAME="serveruser"
PASSWORD="serveruser"

# Create the user with bash as default shell
echo "Creating New user : $USERNAME ..."
sudo deluser --remove-home $USERNAME
sudo useradd -m -s /bin/bash $USERNAME

# Set the password for the user
echo "Setting password ..."
echo -e "$PASSWORD\n$PASSWORD" | sudo passwd $USERNAME

# Add the new user to the sudo group
echo "Add $USERNAME to 'sudo' group ..."
sudo usermod -aG sudo $USERNAME

# Configure sudo to allow passwordless execution for specific commands for the new user
echo "Configure sudo for passwordless execution..."
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USERNAME

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

# Download server files from bucket
export PALSERVERDIR=/home/$USERNAME/Steam/steamapps/common
gcloud storage cp gs://pal-server-storage/pal-server-files/palworld-server-ubuntu-v0.1.3.0.tar \$PALSERVERDIR
tar -xvf \$PALSERVERDIR/palworld-server-ubuntu-v0.1.3.0.tar -C \$PALSERVERDIR
rm \$PALSERVERDIR/palworld-server-ubuntu-v0.1.3.0.tar
rm -r \$PALSERVERDIR/PalServer/Pal/Saved
gcloud storage cp -r gs://pal-server-storage/saved-linux-games/Saved \$PALSERVERDIR/PalServer/Pal

cat <<EOS | sudo tee /etc/systemd/system/palserver.service >/dev/null
[Unit]
Description=Palworld Server
After=network.target

[Service]
Type=simple
User=$USERNAME
Restart=no|always|on-success|on-failure|on-abnormal|on-abort|on-watchdog
RestartSec=30s
ExecStart=/home/$USERNAME/Steam/steamapps/common/PalServer/PalServer.sh

[Install]
WantedBy=multi-user.target
EOS

sudo systemctl daemon-reload
sudo systemctl enable palserver.service
sudo systemctl start palserver.service

EOF

# Check if setup was successful
if [ $? -eq 0 ]; then
    echo "Setup completed successfully."
else
    echo "Setup failed."
    exit 1
fi
