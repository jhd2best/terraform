#!/usr/bin/env bash

set -x

FOLDER=${1:-mainnet.min}

while :; do
   if command -v rclone; then
      break
   else
      echo waiting for rclone ...
      sleep 10
   fi
done

sleep 30

# stop harmony service
sudo systemctl stop harmony.service

unset shard

# determine the shard number
shard=$(cat shard.txt)
if [ $shard != 0 ]; then
   rclone sync -P release:pub.harmony.one/${FOLDER}/harmony_db_${shard} data/harmony_db_${shard}
fi

# download beacon chain db anyway
rclone sync -P release:pub.harmony.one/${FOLDER}/harmony_db_0 data/harmony_db_0

# restart the harmony service
sudo systemctl start harmony.service
