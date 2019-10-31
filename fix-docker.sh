#!/bin/bash
# Import our environment variables from systemd
for e in $(tr "\000" "\n" < /proc/1/environ); do
  eval "export $e"
done

export OLD_SOFTWARE_GROUP_ID=$(getent group $SOFTWARE_GROUP | cut -d: -f3)

if [ "$SOFTWARE_GROUP_ID" != "$OLD_SOFTWARE_GROUP_ID" ]; then
  groupmod -g $SOFTWARE_GROUP_ID $SOFTWARE_GROUP
  find /software/ -group $OLD_SOFTWARE_GROUP_ID -exec chgrp -h $SOFTWARE_GROUP_ID {} \;

  echo "Changed SOFTWARE_GROUP_ID from $OLD_SOFTWARE_GROUP_ID to $SOFTWARE_GROUP_ID" | systemd-cat -t fix-software -p info
else
  echo "SOFTWARE_GROUP_ID $SOFTWARE_GROUP_ID not changed" | systemd-cat -t fix-software -p info
fi