#!/bin/bash

set -e

start() {
    echo "Start Hadoop Services" > $LOGFILE
    echo " - Check Ambari Status" >> $LOGFILE
    for i in {1..20}
    do

        #CODE=`curl -s -o /dev/null -I -w "%{http_code}" -u admin:$AMBARI_PASSWORD http://$AMBARI_HOST:8080/api/v1/clusters`
        AMBARI_STATUS=`curl -s -I http://$AMBARI_HOST:8080 | head -n 1|cut -d$' ' -f2`

        if [ 200 = "$AMBARI_STATUS" ]; then
	        echo "  	- Ambari UP!" >> $LOGFILE
            break
        else
	        echo "  	- Ambari Not Started: WAITING" >> $LOGFILE
            sleep 10

        fi
    done
    OUTPUT=`curl -s -u admin:$AMBARI_PASSWORD -H 'X-Requested-By: ambari'  http://$AMBARI_HOST:8080/api/v1/clusters`
    CLUSTER_NAME=`echo $OUTPUT | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`
    echo " - Get Cluster Name: $CLUSTER_NAME" >> $LOGFILE
    echo " - Waiting for Ambari to Detect Services in Cluster" >> $LOGFILE
    for i in {1..20}
    do
        OUTPUT=`curl -s -u admin:$AMBARI_PASSWORD -i -H 'X-Requested-By: ambari'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/HDFS`
        STATE=`echo $OUTPUT | sed -n 's/.*"state" : "\([^\"]*\)".*/\1/p'`
        echo "      - State: $STATE" >> $LOGFILE
        if [ "INSTALLED" = "$STATE" -o "STARTED" = "$STATE" ]; then
        	echo "      - Services Detected!!" >> $LOGFILE
          break
        else
            echo "	- Service Status Unknown: WAITING" >> $LOGFILE
            sleep 10
        fi
    done
    echo " - Start HDFS" >> $LOGFILE
    curl -s -u admin:$AMBARI_PASSWORD -i -H 'X-Requested-By: admin' -X PUT -d '{"RequestInfo": {"context" :"Start HDFS via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/HDFS
    #sleep 20
    #echo " - TAKE HDFS OUT OF SAFEMODE" >> $LOGFILE
    #sudo -u hdfs hdfs dfsadmin -safemode leave
    echo " - Start Remainder of Hadoop Services" >> $LOGFILE

    curl -s -u admin:$AMBARI_PASSWORD -i -H 'X-Requested-By: admin' -X PUT -d '{"RequestInfo": {"context" :"Start all Services via REST"}, "Body": {"ServiceInfo":{"state": "STARTED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services

    echo "Start Hadoop Services Completed" >> $LOGFILE
}

stop() {
    OUTPUT=`curl -s -u admin:$AMBARI_PASSWORD -H 'X-Requested-By: ambari'  http://$AMBARI_HOST:8080/api/v1/clusters`
    CLUSTER_NAME=`echo $OUTPUT | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`
    echo " - Get Cluster Name: $CLUSTER_NAME" >> $LOGFILE
    echo " - Stop Hadoop Services" >> $LOGFILE

    curl -s -u admin:$AMBARI_PASSWORD -i -H 'X-Requested-By: admin' -X PUT -d '{"RequestInfo": {"context" :"Stop all Services via REST"}, "Body": {"ServiceInfo":{"state": "INSTALLED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services

    echo "STOP Hadoop Services Completed" >> $LOGFILE
}




LOGFILE=/var/log/hadoopControl.log
AMBARI_PASSWORD=admin
AMBARI_HOST=localhost
AMBARI_SERVICES="HDFS MAPREDUCE2 YARN ZOOKEEPER HIVE TEZ HAWQ PXF SPARK ZEPPELIN AMBARI_INFRA RANGER"
#ZEPPELIN FIX
mkdir -p /var/run/zeppelin
chown -R zeppelin: /var/run/zeppelin
#PXF Fix
mkdir -p /var/run/pxf
chown -R pxf: /var/run/pxf

if [ "start" = "$1" ]; then
  start
elif [ "stop" = "$1" ]; then
  stop
fi



