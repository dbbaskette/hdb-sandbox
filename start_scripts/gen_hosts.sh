SCRIPT=$(readlink -f "$0")
echo "# File is generated from ${SCRIPT}" > /etc/hosts
echo "# Do not remove the following line, or various programs" >> /etc/hosts
echo "# that require network functionality will fail." >> /etc/hosts
echo "127.0.0.1		localhost.localdomain localhost" >> /etc/hosts

function get_ip() {
	ip addr | grep 'inet ' | grep -v -E " lo" | awk '{ print $2 }' | awk -F'/' '{print $1}'
}


HOST=$(get_ip)
NUM=5
while [ -z "$HOST" ]; do
	HOST=$(get_ip)
	sleep 5
	NUM=$(($NUM-1))
	if [ $NUM -le 0 ]; then
		HOST="127.0.0.1"
		echo "Failed to update IP"
		break
	fi
done
echo "$HOST	`hostname` sandbox ambari.hortonworks.com" >> /etc/hosts


echo "# File is generated from ${SCRIPT}" > /data/hawq/master/pg_hba.conf
echo "local    all         gpadmin         ident" >> /data/hawq/master/pg_hba.conf
echo "host     all         gpadmin         127.0.0.1/28    trust" >> /data/hawq/master/pg_hba.conf
echo "host all all $HOST/32 trust" >> /data/hawq/master/pg_hba.conf

echo 0 > /proc/sys/kernel/hung_task_timeout_secs
# ethtool -K eth0 tso off
# ethtool -K eth1 tso off
