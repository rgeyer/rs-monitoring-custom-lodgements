#!/usr/bin/env bash

# Depends upon package 'jq' on ubuntu & rhel

strip_quotes() {
  echo $(echo $1 | sed -e 's/^"//' -e 's/"$//')
}

get_self_href() {
  echo $(strip_quotes $(echo $1 | jq '.links' | jq 'map(select(.rel == "self"))[0]' | jq '.href'))
}

source /var/spool/cloud/user-data.sh

# This'll contain the Chef/Ohai value for node['platform_family']
PLATFORM=$(strip_quotes $(/opt/rightscale/sandbox/bin/ohai -L /dev/null | jq '.platform_family'))
RS_COOKIE="/tmp/rscookie"
TIMEFRAME=$(date +"%Y_%m_%d")

# Get some platform specific stuff sorted out.
COLLECTD_CONF_DIR=''
COLLECTD_CONF_FILE=''
COLLECTD_PLUGIN_CONF_DIR=''
COLLECTD_RRD_DIR='/var/lib/collectd'

if [ "$PLATFORM" == "rhel" ]
then
  COLLECTD_CONF_DIR='/etc'
  COLLECTD_PLUGIN_CONF_DIR='/etc/collectd.d'
elif [ "$PLATFORM" == "debian" ]
then
  COLLECTD_CONF_DIR='/etc/collectd'
  COLLECTD_PLUGIN_CONF_DIR='/etc/collectd/plugins'

  # Clean up the stuff at /var/lib/collectd/rrd that
  # would have been created on the first execution
  # before a custom config could be created.
  if [ -e "$COLLECTD_RRD_DIR/rrd" ]
  then
    rm -rf $COLLECTD_RRD_DIR/rrd
  fi
else
  echo "Unknown platform ($PLATFORM).  Can't determine if rrdtool is enabled or where the files are stored. Bailing out!"
  exit 1
fi

COLLECTD_CONF_FILE="$COLLECTD_CONF_DIR/collectd.conf"

# Sanity checks before we make any API calls
if [ -e "$COLLECTD_CONF_FILE" ]
then
  COLLECTD_INSTALLED=true
else
  COLLECTD_INSTALLED=false
fi
if [ -n "$(grep "$LoadPlugin ['\"]\?rrdtool['\"]\?" $COLLECTD_CONF_FILE $COLLECTD_PLUGIN_CONF_DIR/*)" ]
then
  RRDTOOL_ENABLED=true
else
  RRDTOOL_ENABLED=false
fi

if [ $COLLECTD_INSTALLED ]
then
  if [ $RRDTOOL_ENABLED == false ]
  then
    echo "rrdtool plugin for collectd does not appear to be installed.  Please install any necessary packages and add 'LoadPlugin rrdtool' to your collectd configuration."
    exit 1
  fi
fi

# Login to the RS API and get the instance info
curl -s -H X_API_VERSION:1.5 -c $RS_COOKIE -X POST \
  -d instance_token="$RS_RN_AUTH" \
  -d account_href=/api/accounts/"$RS_ACCOUNT" \
  https://$RS_SERVER/api/session/instance


instance=$(curl -s -H X_API_VERSION:1.5 -b $RS_COOKIE -X GET https://$RS_SERVER/api/session/instance)

instance_href=$(get_self_href "$instance")

lodgements_index_href="https://$RS_SERVER$instance_href/instance_custom_lodgements"
current_lodgements=$(curl -s -H X_API_VERSION:1.5 -b $RS_COOKIE -X GET -d filter="timeframe==$TIMEFRAME" $lodgements_index_href)

# The benefit of the doubt..
current_metric_count=0

if [ -e "$COLLECTD_RRD_DIR" ]
then
  current_metric_count=$(find $COLLECTD_RRD_DIR -name *.rrd | wc -l)
fi

echo "Found $current_metric_count monitoring metrics"

if [ "$current_lodgements" == "[]" ]
then
  echo "Creating a custom lodgement for monitoring metrics"
  curl -s -H X_API_VERSION:1.5 -b $RS_COOKIE -X POST -d "quantity[][name]"="monitoring_metrics" -d "quantity[][value]"=$current_metric_count -d timeframe=$TIMEFRAME $lodgements_index_href
else
  custom_lodgement_href=$(get_self_href "$(echo $current_lodgements | jq '.[0]')")
  previous_metric_count=$(echo $current_lodgements | jq '.[0].quantity.monitoring_metrics')
  echo "Updating custom lodgement ($custom_lodgement_href) with latest monitoring metrics.  Previous value was $previous_metric_count, updating to $current_metric_count"
  curl -s -H X_API_VERSION:1.5 -b $RS_COOKIE -X PUT -d "quantity[][name]"="monitoring_metrics" -d "quantity[][value]"=$current_metric_count -d timeframe=$TIMEFRAME "https://$RS_SERVER$custom_lodgement_href"
fi