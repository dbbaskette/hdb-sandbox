#!/usr/bin/env bash
 # This script is designed to permanently disable Autostart of many of the Hadoop Components.
# After running it, Only HDFS, YARN, AMBARI, HAWQ and PXF will Autostart

sed -i -e 's/all: Startup Ambari/all: Startup Ambari ##/g' /usr/lib/hue/tools/start_scripts/start_deps.mf
sed -i -e 's/Startup: Ambari HDFS YARN Zookeeper/Startup: Ambari HDFS YARN Zookeeper ##/g' /usr/lib/hue/tools/start_scripts/start_deps.mf
sed -i -e 's/HDFS: namenode datanode/HDFS: namenode datanode ##/g' /usr/lib/hue/tools/start_scripts/start_deps.mf
