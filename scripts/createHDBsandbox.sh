#!/usr/bin/env bash
###########################################################################################################################
##HDB on HDP sandbox setup script

# This version is desgined to be used with the Packer build process at https://github.com/dbbaskette/hdb-sandbox
# You must insert your PIVNET API Token into the Packer json file for the Downloads to work
########################################################################################################################### 

#Customize HDB install bits location
export PIV_NET_BASE=https://network.pivotal.io/api/v2/products/pivotal-hdb/releases/4480
export PIV_NET_HDB=$PIV_NET_BASE/product_files/15012/download
export PIV_NET_ADDON=$PIV_NET_BASE/product_files/15011/download
export PIV_NET_MADLIB=$PIV_NET_BASE/product_files/10951/download
export PIV_NET_EULA=$PIV_NET_BASE/eula_acceptance
export HDB_VERSION=2.1.2.0
export HDP_VERSION=2.5.0.0
export AMB_VERSION=2.4.2.0

#Customize which services to deploy and other configs
export ambari_services="HDFS MAPREDUCE2 YARN ZOOKEEPER HIVE TEZ HAWQ PXF SPARK ZEPPELIN"
export ambari_password="admin"
export cluster_name=hdp
export host_count=1
export ambari_stack_version=2.5

################
# Script start #
################
set -e 
ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

#add /etc/hosts entry
echo "${ip} $(hostname -f) $(hostname) sandbox" | sudo tee -a /etc/hosts

#remove any files from previous install attempts
rm -rf /staging
rm -rf ~/ambari-bootstrap
rm -rf /usr/lib/hue
rm -f /etc/init.d/startup_script

#install python sh module from pip - used later by sandbox splash screen page
yum install -y epel-release
yum install -y python-pip
pip install sh

yum install -y git python-argparse
cd ~
#git clone https://github.com/seanorama/ambari-bootstrap.git
git clone https://github.com/dbbaskette/ambari-bootstrap.git

 
#install Ambari
echo "Installing Ambari..."
install_ambari_server=true ~/ambari-bootstrap/ambari-bootstrap.sh

#install zeppelin service defn
#git clone https://github.com/hortonworks-gallery/ambari-zeppelin-service.git /var/lib/ambari-server/resources/stacks/HDP/2.4/services/ZEPPELIN
#sed -i.bak '/dependencies for all/a \  "ZEPPELIN_MASTER-START": ["NAMENODE-START", "DATANODE-START"],' /var/lib/ambari-server/resources/stacks/HDP/2.4/role_command_order.json


export headers="Authorization:Token $1"


#AUTHENTICATE
echo "Authenticating with Pivotal Network"

curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "$headers" -X GET https://network.pivotal.io/api/v2/authentication


#ACCEPT EULA
echo "Accept Pivotal EULA"

curl -X POST --header "$headers" $PIV_NET_EULA



#HAWQ setup
echo "Setting up HAWQ service defn..."

mkdir /staging
chmod a+rx /staging
wget -O "/staging/hdb.tar.gz" --post-data="" --header="Authorization: Token $1" $PIV_NET_HDB
wget -O "/staging/hdb-addons.tar.gz" --post-data="" --header="Authorization: Token $1" $PIV_NET_ADDON
wget -O "/staging/madlib.tar.gz" --post-data="" --header="Authorization: Token $1" $PIV_NET_MADLIB

# TEMP DOWNLOAD OF NEW CODE
#wget -O "/staging/hdb.tar.gz" https://s3-us-west-2.amazonaws.com/hdb-concourse-ci/hdb_latest/hdb-2.0.1.0-1625.tar.gz
#wget -O "/staging/hdb-addons.tar.gz"  https://s3-us-west-2.amazonaws.com/hdb-concourse-ci/hdb_latest/hdb-add-ons-2.0.1.0-1625.tar.gz

tar -xvzf /staging/hdb.tar.gz -C /staging/
tar -xvzf /staging/hdb-addons.tar.gz -C /staging/
tar -xvzf /staging/madlib.tar.gz -C /staging/

yum install -y httpd
service httpd start
chkconfig httpd on
cd /staging/hdb-2*
./setup_repo.sh
cd /staging/hdb-add*
./setup_repo.sh  
yum install -y hawq-ambari-plugin
/var/lib/hawq/add-hawq.py -u admin -p admin --stack HDP-2.5

#restart Ambari
echo "Restarting Ambari..."
service ambari-server restart
service ambari-agent restart
sleep 5
curl -u admin:admin -H  X-Requested-By:ambari http://localhost:8080/api/v1/hosts

#make VM look like sandbox
echo "Make VM look like sandbox..."
cd ~
#wget https://github.com/abajwa-hw/security-workshops/raw/master/scripts/startup-HDB.zip
#wget https://github.com/dbbaskette/hdb-sandbox/raw/master/startup-HDB.zip
#wget https://github.com/dbbaskette/hdb-sandbox/raw/meetup-lab/startup-HDB.zip
#git clone https://github.com/dbbaskette/hdb-sandbox.git
mkdir -p /usr/lib/hue/tools
mv ~/start_scripts /usr/lib/hue/tools

#unzip startup-HDB.zip -d /
ln -s /usr/lib/hue/tools/start_scripts/startup_script /etc/init.d/startup_script


#rm -f startup-HDB.zip
echo $2 > /virtualization

#boot in text only and remove rhgb
#plymouth-set-default-theme text
sed -i "s/rhgb//g" /boot/grub/grub.conf

#add startup_script and splash page to startup
echo "setterm -blank 0" >> /etc/rc.local
echo "/etc/rc.d/init.d/startup_script start" >> /etc/rc.local

echo "export HDB_VERSION=$HDB_VERSION" >> /etc/rc.local
echo "export HDP_VERSION=$HDP_VERSION" >> /etc/rc.local
echo "export AMB_VERSION=$AMB_VERSION" >> /etc/rc.local


echo "python /usr/lib/hue/tools/start_scripts/splash.py" >> /etc/rc.local
 

#provide custom configs for HAWQ, and HDFS proxy users
echo "Creating custom configs..."
cat << EOF > ~/ambari-bootstrap/deploy/configuration-custom.json
{
  "configurations" : {
    "hdfs-site": {
        "dfs.allow.truncate": "true",
        "dfs.block.access.token.enable": "false",
        "dfs.block.local-path-access.user": "gpadmin",
        "dfs.client.read.shortcircuit": "true",
        "dfs.client.socket-timeout": "300000000",
        "dfs.client.use.legacy.blockreader.local": "false",
        "dfs.datanode.handler.count": "60",
        "dfs.datanode.socket.write.timeout": "7200000",                                
        "dfs.namenode.handler.count": "600",
        "dfs.support.append": "true",
        "dfs.replication": "1"

    },
    "hawq-site":{
        "hawq_master_address_port":"10432",
        "hawq_master_temp_directory":"/data/hawq/tmp",
        "hawq_segment_temp_directory":"/data/hawq/tmp"

    },
    "hdfs-client":{
        "dfs.default.replica":"1"
    },
    "yarn-site":{
        "yarn.scheduler.minimum-allocation-mb":"320"
    },

    "hawq-env":{
        "hawq_password":"gpadmin",
        "vm.overcommit_memory":"1"

    },
    "core-site": {
        "hadoop.proxyuser.root.groups": "*",
        "hadoop.proxyuser.root.hosts": "*",        
        "ipc.client.connection.maxidletime": "3600000",
        "ipc.client.connect.timeout": "300000",
        "ipc.server.listen.queue.size": "3300"
    },
    "zeppelin-config": {
    "zeppelin.interpreters": "org.apache.zeppelin.spark.SparkInterpreter,org.apache.zeppelin.spark.PySparkInterpreter,org.apache.zeppelin.spark.SparkSqlInterpreter,org.apache.zeppelin.spark.DepInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter,org.apache.zeppelin.phoenix.PhoenixInterpreter,org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkRInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.postgresql.PostgreSqlInterpreter,org.apache.zeppelin.file.HDFSFileInterpreter"
    }


  }
}
EOF

echo "Starting cluster install..."



#generate BP using Ambari recommendation API and deploy HDP
cd ~/ambari-bootstrap/deploy/
./deploy-recommended-cluster.bash
sleep 5

#wait until cluster deployed
source ~/ambari-bootstrap/extras/ambari_functions.sh
ambari_configs
ambari_wait_request_complete 1

##post install steps
sudo -u zeppelin /usr/hdp/current/zeppelin-server/bin/install-interpreter.sh -a

cd ~

cat << EOF > ~/zeppelin-psql.json
{
      "name": "psql",
      "group": "psql",
      "properties": {
        "postgresql.driver.name": "org.postgresql.Driver",
        "postgresql.password": "gpadmin",
        "postgresql.url": "jdbc:postgresql://sandbox:10432/demos",
        "postgresql.max.result": "1000",
        "postgresql.user": "gpadmin"
      },
      "interpreterGroup": [
        {
          "class": "org.apache.zeppelin.postgresql.PostgreSqlInterpreter",
          "name": "sql"
        }
      ],
      "dependencies": [],
      "option": {
        "remote": true,
        "perNoteSession": false,
        "perNoteProcess": false,
        "isExistingProcess": false,
        "isUserImpersonate": false
      }
}
EOF

cat << EOF > ~/zeppelin-hdfs.json
{
      "name": "hdfs",
      "group": "file",
      "properties": {
        "hdfs.maxlength": "1000",
        "hdfs.user": "hdfs",
        "hdfs.url": "http://sandbox:50070/webhdfs/v1/"
      },
      "interpreterGroup": [
        {
          "class": "org.apache.zeppelin.file.HDFSFileInterpreter",
          "name": "hdfs"
        }
      ],
      "dependencies": [],
      "option": {
        "remote": true,
        "perNoteSession": false,
        "perNoteProcess": false,
        "isExistingProcess": false,
        "isUserImpersonate": false
      }
    }
EOF



#echo "Pointing Zeppelin at Demos database by default"
#sed -i 's/\"postgresql.url.*/\"postgresql.url\": \"jdbc:postgresql:\/\/localhost:10432\/gpadmin\",/g' /etc/zeppelin/conf/interpreter.json



curl -u admin:$ambari_password -i -H 'X-Requested-By: zeppelin' -X PUT -d '{"RequestInfo": {"context" :"Stop ZEPPELIN via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://localhost:8080/api/v1/clusters/$cluster_name/services/ZEPPELIN
sleep 30
curl -u admin:$ambari_password -i -H 'X-Requested-By: zeppelin' -X PUT -d '{"RequestInfo": {"context" :"Start ZEPPELIN via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://localhost:8080/api/v1/clusters/$cluster_name/services/ZEPPELIN

sleep 20

echo "Update Zeppelin configs for HAWQ"
curl http://localhost:9995/api/interpreter/setting -d @/root/zeppelin-psql.json
echo "Update Zeppelin configs for HDFS"
curl http://localhost:9995/api/interpreter/setting -d @/root/zeppelin-hdfs.json
#MOVED TO DEMO SCRIPTS
#echo "Add Demo Notebook to Apache Zeppelin"
#curl http://localhost:9995/api/notebook/import -d @/opt/hawq-sandbox-demos/HAWQ-Demonstration.json



echo "Configure local connections to HAWQ and reload HAWQ configs.."

ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

echo "# File is generated from ${SCRIPT}" > /data/hawq/master/pg_hba.conf
echo "local    all         gpadmin         ident" >> /data/hawq/master/pg_hba.conf
echo "host     all         gpadmin         127.0.0.1/28    trust" >> /data/hawq/master/pg_hba.conf
echo "host all all ${ip}/32 trust" >> /data/hawq/master/pg_hba.conf



# ADD PG defaults to .bashrc
sudo -u gpadmin bash -c "echo 'export PGPORT=10432' >> /home/gpadmin/.bashrc"
sudo -u gpadmin bash -c "echo 'source /usr/local/hawq/greenplum_path.sh' >> /home/gpadmin/.bashrc"
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; hawq stop cluster -a --reload"

#create a demos database - JUST IN CASE
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh;createdb -p 10432 demos"



echo "Installing MADlib"
#TEMP # HACK FOR MADLIB ISSUES
#wget -O "/staging/madlib191.gppkg" https://s3.amazonaws.com/hdb-sandbox/madlib191.gppkg
#sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh;gppkg -i /staging/madlib191.gppkg"
#yum install -y dos2unix
#dos2unix /staging/remove_compression.sh
#TEMP

# TEMP REPLACED BY ABOVE
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh;gppkg -i /staging/madlib*.gppkg"
chmod +x /staging/remove_compression.sh
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh;/staging/remove_compression.sh --prefix /usr/local/hawq/madlib"
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; /usr/local/hawq/madlib/bin/madpack install -s madlib -p hawq -c gpadmin@sandbox:10432/template1"
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; /usr/local/hawq/madlib/bin/madpack install -s madlib -p hawq -c gpadmin@sandbox:10432/gpadmin"
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; /usr/local/hawq/madlib/bin/madpack install -s madlib -p hawq -c gpadmin@sandbox:10432/demos"


#Setup /etc/issue
echo -e "To login to the shell, use:\n----------------------\n   username: root\n   password: hadoop\n\nGPADMIN Credentials:\n----------------------\n   username: gpadmin\n   password: gpadmin\n" >> /etc/issue

#Download Demos
echo "Installing HAWQ Demo"
cd /opt
git clone https://github.com/dbbaskette/hawq-sandbox-demos.git
cd hawq-sandbox-demos
./setup.sh




echo "getting ready to export VM"
rm -f /etc/udev/rules.d/*-persistent-net.rules
sed -i '/^HWADDR/d'  /etc/sysconfig/network-scripts/ifcfg-eth0 
sed -i '/^UUID/d'  /etc/sysconfig/network-scripts/ifcfg-eth0 


echo "reduce VM size"
cd /opt
yum clean all
wget -O "/tmp/zero_machine.sh" http://dev2.hortonworks.com.s3.amazonaws.com/stuff/zero_machine.sh
chmod +x /tmp/zero_machine.sh
rm -rf /staging/*
rm -rf ~/ambari-bootsrap
rm -rf ~/hdb-sandbox
rm -rf /opt/hawq-sandbox-demos
/tmp/zero_machine.sh
/bin/rm -f /tmp/zero_machine.sh





echo "Install is complete. Access Ambari on port 8080, Zeppelin on port 9995"

exit
