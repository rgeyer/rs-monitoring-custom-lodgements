rs-monitoring-custom-lodgements
===============================

Tools for creating a RightScale custom lodgement for monitoring metrics.

The ruby script is unfinished, it required too many dependencies on the target box to be reliable and practical.

create_custom_lodgements.sh
---------------------------
A shell script which is meant to be executed on a RightScale managed server to
detect the number of collectd metrics are being collected.

It checks your collectd.conf file and all of your *.conf plugin config files to
make sure that the collectd rrdtool plugin is installed and enabled.

It then counts metrics by counting the number of *.rrd files found /var/lib/collectd
using this one-liner.

```
find /var/lib/collectd -name *.rrd | wc -l
```
