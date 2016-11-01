#!/usr/bin/env bash
###########################################################################################################################
##HDB on HDP sandbox setup script

# This version is desgined to be used with the Packer build process at https://github.com/dbbaskette/hdb-sandbox
# You must insert your PIVNET API Token into the Packer json file for the Downloads to work
########################################################################################################################### 

#Customize HDB install bits location
export PIV_NET_BASE=https://network.pivotal.io/api/v2/products/pivotal-hdb/releases/2397
export PIV_NET_HDB=$PIV_NET_BASE/product_files/7634/download
export PIV_NET_ADDON=$PIV_NET_BASE/product_files/7633/download
export PIV_NET_MADLIB=$PIV_NET_BASE/product_files/7727/download
export PIV_NET_EULA=https://network.pivotal.io/api/v2/products/pivotal-hdb/releases/2397/eula_acceptance

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

#ACCEPT EULA
export headers="{Authorization:Token $1}"
curl -X POST --header $headers $PIV_NET_EULA

#HAWQ setup
echo "Setting up HAWQ service defn..."
echo "GOT API KEY " $1
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
wget https://github.com/dbbaskette/hdb-sandbox/raw/master/startup-HDB.zip
#wget https://github.com/dbbaskette/hdb-sandbox/raw/meetup-lab/startup-HDB.zip


unzip startup-HDB.zip -d /
ln -s /usr/lib/hue/tools/start_scripts/startup_script /etc/init.d/startup_script
rm -f startup-HDB.zip
echo "vmware" > /virtualization

#boot in text only and remove rhgb
#plymouth-set-default-theme text
sed -i "s/rhgb//g" /boot/grub/grub.conf

#add startup_script and splash page to startup
echo "setterm -blank 0" >> /etc/rc.local
echo "/etc/rc.d/init.d/startup_script start" >> /etc/rc.local


# MOVED THESE CHANGE TO ORIGINAL SPLASH FILE
#sed -i "/greet_win.addstr(2, 2, \"http:\/\/hortonworks.com/a greet_win.addstr(3, 2, \"---------------------------------------------\");greet_win.addstr(4, 2, \"username: root      password:  hadoop\");greet_win.addstr(5, 2, \"username: gpadmin   password:  gpadmin\")" /usr/lib/hue/tools/start_scripts/splash.py
#sed -i 's/greet_win.addstr(3, 2/    greet_win.addstr(3, 2/' /usr/lib/hue/tools/start_scripts/splash.py

#sed -i "/ip_win.addstr(4, 2, \"http:\/\/%s:8080/a ip_win.addstr(5, 2, \"username: admin   password: admin\")" /usr/lib/hue/tools/start_scripts/splash.py
#sed -i "s/ip_win.addstr(5, 2, \"username:/        ip_win.addstr(5, 2, \"username:/" /usr/lib/hue/tools/start_scripts/splash.py

#sed -i "/ip_win.addstr(5, 2, \"username:/aip_win.addstr(7, 2, \"To Launch Apache Zeppelin enter this address in browser:\")" /usr/lib/hue/tools/start_scripts/splash.py
#sed -i "s/ip_win.addstr(7, 2, \"To Launch/        ip_win.addstr(7, 2, \"To Launch/" /usr/lib/hue/tools/start_scripts/splash.py

#sed -i "/ip_win.addstr(7, 2, \"To Launch/a ip_win.addstr(8, 2, \"http:\/\/%s:9995\" \% ip)" /usr/lib/hue/tools/start_scripts/splash.py
#sed -i "s/ip_win.addstr(8, 2, \"http:\/\/%s:9995\" \% ip)/        ip_win.addstr(8, 2, \"http:\/\/%s:9995\" \% ip)/" /usr/lib/hue/tools/start_scripts/splash.py

#sed -i "s/curses.endwin()/ curses.endwin()/"  /usr/lib/hue/tools/start_scripts/splash.py

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
    "zeppelin.interpreters": "org.apache.zeppelin.spark.SparkInterpreter,org.apache.zeppelin.spark.PySparkInterpreter,org.apache.zeppelin.spark.SparkSqlInterpreter,org.apache.zeppelin.spark.DepInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter,org.apache.zeppelin.phoenix.PhoenixInterpreter,org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkRInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.postgresql.PostgreSqlInterpreter"
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
        "postgresql.url": "jdbc:postgresql://localhost:5432/gpadmin",
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





#echo "Pointing Zeppelin at gpadmin database by default"
#sed -i 's/\"postgresql.url.*/\"postgresql.url\": \"jdbc:postgresql:\/\/localhost:10432\/gpadmin\",/g' /etc/zeppelin/conf/interpreter.json

#read -p "Press any key to continue... " -n1 -s


echo "Downloading demo HAWQ demo notebook and restarting Zeppelin"
notebook_id=2BQPFYB1X
sudo -u zeppelin  mkdir /usr/hdp/current/zeppelin-server/notebook/$notebook_id
sudo -u zeppelin wget https://gist.githubusercontent.com/abajwa-hw/2f72d084dd1d0c5889783ecf0cd967ab/raw -O /usr/hdp/current/zeppelin-server/notebook/$notebook_id/note.json
curl -u admin:$ambari_password -i -H 'X-Requested-By: zeppelin' -X PUT -d '{"RequestInfo": {"context" :"Stop ZEPPELIN via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://localhost:8080/api/v1/clusters/$cluster_name/services/ZEPPELIN
sleep 30
curl -u admin:$ambari_password -i -H 'X-Requested-By: zeppelin' -X PUT -d '{"RequestInfo": {"context" :"Start ZEPPELIN via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://localhost:8080/api/v1/clusters/$cluster_name/services/ZEPPELIN

sleep 10

echo "Update Zeppelin configs for HAWQ"
#curl -sSL https://gist.githubusercontent.com/dbbaskette/8dd2bd949f8a6eac4e7083f942748149/raw | sudo -E python
curl http://localhost:9995/api/interpreter/setting -d @/root/zeppelin-psql.json


echo "import data into hive"
cd /tmp
wget https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/data/sample_07.csv

sudo -u hdfs hive -e "CREATE TABLE sample_07 (
code string ,
description string ,
total_emp int ,
salary int )
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TextFile; "

sudo -u hdfs hive -e "load data local inpath '/tmp/sample_07.csv' into table sample_07;"

echo "import retail sample data from pivotal github"
cd /tmp
git clone https://github.com/pivotalsoftware/pivotal-samples.git
cd /tmp/pivotal-samples/sample-data/
sudo -u hdfs ./load_data_to_HDFS.sh
sudo -u hdfs hdfs dfs -chmod -R 777 /retail_demo
sudo -u hdfs hive -f /tmp/pivotal-samples/hive/create_hive_tables.sql

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

echo "Installing MADlib"
wget https://raw.githubusercontent.com/apache/incubator-madlib/master/deploy/hawq_install.sh -O /staging/hawq_install.sh
chmod +x /staging/hawq_install.sh
echo "sandbox.hortonworks.com" >> /staging/hostsfile



tar xvf /staging/madlib*.gppkg -C /staging/
#/staging/hawq_install.sh -r /staging/madlib*.rpm -f /staging/hostsfile -d /usr/local/hawq --prefix /usr/local/hawq/madlib
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; /staging/hawq_install.sh -r /staging/madlib*.rpm -f /staging/hostsfile -d /usr/local/hawq --prefix /usr/local/hawq -s"

chmod +x /staging/remove_compression.sh
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh;/staging/remove_compression.sh"

sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; /usr/local/hawq/madlib/bin/madpack install -s madlib -p hawq -c gpadmin@sandbox:10432"
sudo -u gpadmin bash -c "source /usr/local/hawq/greenplum_path.sh; /usr/local/hawq/madlib/bin/madpack install -s madlib -p hawq -c gpadmin@sandbox:10432"

#Setup /etc/issue
echo -e "To login to the shell, use:\n----------------------\n   username: root\n   password: hadoop\n\nGPADMIN Credentials:\n----------------------\n   username: gpadmin\n   password: gpadmin\n" >> /etc/issue

echo "getting ready to export VM"
rm -f /etc/udev/rules.d/*-persistent-net.rules
sed -i '/^HWADDR/d'  /etc/sysconfig/network-scripts/ifcfg-eth0 
sed -i '/^UUID/d'  /etc/sysconfig/network-scripts/ifcfg-eth0 


echo "reduce VM size"
wget http://dev2.hortonworks.com.s3.amazonaws.com/stuff/zero_machine.sh
chmod +x zero_machine.sh
rm -rf /staging/*
rm -rf ~/ambari-bootsrap
./zero_machine.sh
/bin/rm -f zero_machine.sh





echo "Install is complete. Access Ambari on port 8080, Zeppelin on port 9995"
echo "A demo HAWQ notebook is available at http://VM_ADDRESS:9995/#/notebook/2BQPFYB1X"
echo "To take an export of this VM, shutdown and stop the VM first then export the .ova file by running below from on your local laptop (replace HDB_sandbox with the name of your VM). This will export the .ova file in your Mac's Downloads dir"
echo "/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/ovftool --acceptAllEulas ~/Documents/Virtual\ Machines.localized/HDB_sandbox.vmwarevm/HDB_sandbox.vmx ~/Downloads/HDB_sandbox.ova"

exit
