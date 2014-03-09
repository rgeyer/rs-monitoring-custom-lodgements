#!/usr/bin/env bash

if [ "$RS_DISTRO" == "ubuntu" ]
then
  echo "LoadPlugin rrdtool" > /etc/collectd/plugins/rrdtool.conf
elif [ "$RS_DISTRO" == "centos" ]
then
  yum install -y collectd-rrdtool
  echo "LoadPlugin rrdtool" > /etc/collectd.d/rrdtool.conf
fi

/etc/init.d/collectd restart