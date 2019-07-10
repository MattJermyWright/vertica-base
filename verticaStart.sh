#!/bin/bash

# Make sure sysctl is correct - assume's admin-level permissions
sysctl -w kernel.pid_max=524288

# Enable NTP
service ntp restart

# Any non-zero exits should be fatal
set -e

# Vertica should be shut down properly
function shut_down() {
  echo "Shutting Down"
  gosu dbadmin /opt/vertica/bin/admintools -t stop_db -d docker -i
  exit
}

trap "shut_down" SIGKILL SIGTERM SIGHUP SIGINT EXIT

mkdir -p $VERTICA_CONFIG

if [ -f $VERTICA_CONFIG/admintools.conf ]; then
  # echo "Copy database config..."
  # /bin/cp -af $VERTICA_CONFIG/admintools.conf /opt/vertica/config
  # chown -R dbadmin:verticadba /opt/vertica/config
  rm -f /opt/vertica/config/admintools.conf &&  ln -s $VERTICA_CONFIG/admintools.conf /opt/vertica/config/admintools.conf
  echo "Starting existing database..."
  gosu dbadmin /opt/vertica/bin/admintools -t start_db -d docker -i

else
  echo "Can't find original configuration - dropping any original db..."
  gosu dbadmin /opt/vertica/bin/admintools -t drop_db -d docker
  echo "Creating database..."
  gosu dbadmin /opt/vertica/bin/admintools -t create_db -s localhost -d docker -c $VERTICA_DATA/catalog -D $VERTICA_DATA/data --skip-fs-checks
  echo "Linking configs..."
  /bin/cp -af /opt/vertica/config/admintools.conf $VERTICA_CONFIG/
  rm -f /opt/vertica/config/admintools.conf && ln -s $VERTICA_CONFIG/admintools.conf /opt/vertica/config/admintools.conf
  # /bin/cp -af /opt/vertica/config/admintools.conf $VERTICA_CONFIG/
fi


# Get / copy over vertica config data if it exists
# if [ -n "$(ls -A "$VERTICA_CONFIG")" ]; then
#   echo "Copying config files from previous database"
#   /bin/cp -af $VERTICA_CONFIG/admintools.conf /opt/vertica/config
#   chown -R dbadmin:verticadba /opt/vertica/config
# fi

# chown -R dbadmin:verticadba "$VERTICA_DATA"
# if [ -z "$(ls -A "$VERTICA_CONFIG/admintools.conf")" ]; then
#   echo "Creating database"
#   gosu dbadmin /opt/vertica/bin/admintools -t drop_db -d docker
#   gosu dbadmin /opt/vertica/bin/admintools -t create_db -s localhost -d docker -c /home/dbadmin/docker/catalog -D /home/dbadmin/docker/data --skip-fs-checks
# else
#   echo "Starting existing database"
#   gosu dbadmin /opt/vertica/bin/admintools -t start_db -d docker -i
# fi

echo "Vertica is now running"

while true; do
   sleep 1
done
