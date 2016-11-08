line="50"

#------- Start script ---------

echo "Starting mysql"
/etc/init.d/mysqld start

echo "Starting Postgresql"
/etc/init.d/postgresql start;sleep 5

echo "Start HDFS"
echo "Start name node"
su -l hdfs -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf start namenode";sleep 5
tail -$line  /var/log/hadoop/hdfs/hadoop-hdfs-namenode-*.log

echo "Start data node"
su -l hdfs -c  "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf start datanode";sleep 5
tail -$line  /var/log/hadoop/hdfs/hadoop-hdfs-datanode-*.log

echo "Start secondary name node"
su -l hdfs -c  "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf start secondarynamenode";sleep 5
tail -$line  /var/log/hadoop/hdfs/hadoop-hdfs-secondarynamenode-*.log

echo "Start YARN"
echo "Start Resource Manager"
su -l yarn -c  "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager"
tail -$line  /var/log/hadoop-yarn/yarn/yarn-yarn-resourcemanager-*.log

echo "Start JobTracker History Server"
su -l mapred -c  "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver"
tail -$line  /var/log/hadoop-yarn/yarn/yarn-yarn-historyserver-*.log

echo "Start Node Manager"
su -l yarn -c  "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start nodemanager"
tail -$line  /var/log/hadoop-yarn/yarn/yarn-yarn-nodemanager-*.log

echo "Start ZooKeeper"
su - zookeeper -c "export  ZOOCFGDIR=/etc/zookeeper/conf ; export ZOOCFG=zoo.cfg ; source /etc/zookeeper/conf/zookeeper-env.sh ; /usr/lib/zookeeper/bin/zkServer.sh start"

echo "Start HBase"
echo "Start HBase Master"
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master; sleep 25"
tail -$line  /var/log/hbase/hbase-hbase-master-*.log

echo "Start HBase RegionServers"
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver";sleep 5
tail -$line  /var/log/hbase/hbase-hbase-regionserver-*.log

echo "Start Hive Metastore"
/etc/init.d/mysqld start
su -l hive -c "env HADOOP_HOME=/usr nohup hive --service metastore > /var/log/hive/hive.out 2> /var/log/hive/hive.log &"
tail -$line  /var/log/hive/hive.log

echo "Start HiveServer2"
su -l hive -c "nohup /usr/lib/hive/bin/hiveserver2 -hiveconf hive.metastore.uris=\" \" > /var/log/hive/hive-server2.log 2>/var/log/hive/hive-server2.log &"
tail -$line  /var/log/hive/hive.log

echo "Start Tez"
su - tez -c "/usr/lib/tez/sbin/tez-daemon.sh start ampoolservice"
tail -$line  /var/log/tez/tez.log

echo "Start WebHCat"
su -l hcat -c "/usr/lib/hcatalog/sbin/webhcat_server.sh start"
tail -$line  /var/log/webhcat/webhcat.log

echo "Start Oozie"
su - oozie -c "cd /var/log/oozie; /usr/lib/oozie/bin/oozie-start.sh"
tail -$line  /var/log/oozie/oozie.log


# echo "Starting Ganglia"
# /etc/init.d/gmetad stop
# /etc/init.d/gmond stop
# /etc/init.d/hdp-gmetad start
# /etc/init.d/hdp-gmond start


# echo "starting Nagios"
# /etc/init.d/nagios start;sleep 5

# echo "Starting Ambari server"
# ambari-server start; sleep 5

# echo "Starting Ambari agent"
# ambari-agent start

echo "Service associated with port"
netstat -nltp

echo
echo
echo "Java Process"
ps auxwwwf | grep java | grep -v grep | awk '{print $1, $11,$12}'
echo

