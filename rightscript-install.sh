#!/usr/bin/env bash

# Make sure you add "curl" as a package for the RightScript

CRON_HOURLY_DIR=/etc/cron.hourly

if [ ! -e "$CRON_HOURLY_DIR" ]
then
  echo "This script expects anacron type functionality with an /etc/cron.hourly directory. No /etc/cron.hourly directory was found."
fi

cd /tmp
curl -O http://stedolan.github.io/jq/download/linux64/jq
chmod +x jq
mv jq /usr/bin/

cp $RS_ATTACH_DIR/create_custom_lodgement.sh $CRON_HOURLY_DIR
chmod +x $CRON_HOURLY_DIR/create_custom_lodgement.sh