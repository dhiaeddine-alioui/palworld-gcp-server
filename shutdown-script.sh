#!/bin/bash

# Define username and password
USERNAME="serveruser"

export PALSERVERDIR=/home/$USERNAME/Steam/steamapps/common
gcloud storage cp -r \$PALSERVERDIR/PalServer/Pal/Saved gs://pal-server-storage/saved-linux-games/ && \
timestamp=\$(date +'%Y-%m-%d_%H-%M-%S') && \
tar -czf /tmp/backup_\$timestamp.tar.gz \$PALSERVERDIR/PalServer/Pal/Saved && \
gcloud storage cp /tmp/backup_\$timestamp.tar.gz gs://pal-server-storage/backup-saved-games/ && \
rm /tmp/backup_\$timestamp.tar.gz && \
echo 'Folder compressed and copied to GCS bucket.' \