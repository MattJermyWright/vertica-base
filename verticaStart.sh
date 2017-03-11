#!/bin/bash

# Enable NTP
service ntp restart


# Setup Vertica configuration directory
export VERTICACONF=$VERTICADATA/config
mkdir -p $VERTICACONF

# Any non-zero exits should be fatal
set -e

# Vertica should be shut down properly
function shut_down() {
  echo "Shutting Down"
  gosu dbadmin /opt/vertica/bin/admintools -t stop_db -d docker -i
  echo "Saving configuration file for future use"
  /bin/cp -af /opt/vertica/config/admintools.conf $VERTICACONF
  exit
}

trap "shut_down" SIGKILL SIGTERM SIGHUP SIGINT EXIT

# Get / copy over vertica config data if it exists
if [ -n "$(ls -A "$VERTICACONF")" ]; then
  echo "Copying config files from previous database"
  /bin/cp -af $VERTICACONF/admintools.conf /opt/vertica/config
  chown -R dbadmin:verticadba /opt/vertica/config
fi

chown -R dbadmin:verticadba "$VERTICADATA"
if [ -z "$(ls -A "$VERTICACONF/admintools.conf")" ]; then
  echo "Creating database"
  gosu dbadmin /opt/vertica/bin/admintools -t drop_db -d docker
  gosu dbadmin /opt/vertica/bin/admintools -t create_db -s localhost -d docker -c /home/dbadmin/docker/catalog -D /home/dbadmin/docker/data --skip-fs-checks
else
  echo "Starting existing database"
  gosu dbadmin /opt/vertica/bin/admintools -t start_db -d docker -i
fi

echo "Vertica is now running"

while true; do
   sleep 1
done
