#!/bin/bash

# Define username and password
USERNAME="serveruser"
PASSWORD="serveruser"

# Create the user with bash as default shell
sudo useradd -m -s /bin/bash $USERNAME

# Set the password for the user
echo -e "$PASSWORD\n$PASSWORD" | sudo passwd $USERNAME

# Check if user creation and password setup were successful
if [ $? -eq 0 ]; then
    echo "User $USERNAME created successfully with password $PASSWORD"
else
    echo "Failed to create user or set password"
    exit 1
fi

# Switch to the newly created user
sudo su - $USERNAME

