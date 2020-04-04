#/bin/bash

#GLOBAL VARIABLES
declare DEBUG=1

declare CONTROLLER='10.91.192.31'
declare COMPUTE1='10.91.192.32'
declare BLOCK1='10.91.192.33'
declare OBJECT1='10.91.192.34'
declare OBJECT2='10.91.192.35'
declare SUBNET='10.91.192.0/24'

declare HOSTS=($CONTROLLER $COMPUTE1 $BLOCK1 $OBJECT1 $OBJECT2)
declare PASSWORD='zxcvb123'
declare USER='root'

declare Proxy='http://87.254.212.120:8080'
declare ProxyCmd="export http_proxy=$Proxy;export https_proxy=$Proxy;export ftp_proxy=$Proxy"

log (){
	varDate=$(date +"%Y-%m-%d %H:%M:%S");
	echo -e "[$varDate] $@";
}

log_debug (){
	varDate=$(date +"%Y-%m-%d %H:%M:%S");
	[ $DEBUG != 0 ] && echo -e "[$varDate] [DEBUG] $@";
}

log_warn (){
	varDate=$(date +"%Y-%m-%d %H:%M:%S");
	>&2 echo "[$varDate] warning : $@"
}  

log_error (){
	>&2 echo "Error: $@"
	exit 1;
} 

executeCmd (){
	host=$1;
	cmd=$2;
	failedWithError=$3; # failedWithError = true | false, default false.
	response=$(sshpass -p $PASSWORD ssh -o "StrictHostKeyChecking no" -q $USER\@$host "$cmd");
	rc=$(sshpass -p $PASSWORD ssh -o "StrictHostKeyChecking no" -q $USER\@$host "echo $?");

	log_debug "  command on $host, command = ' $cmd '; "
	
	if [ $rc !=  "0" ]; then
		if ( $failedWithError ); then
			log "Executing command on $host, command = ' $cmd '; " 
			log_error "Command failed on $host, return code = $rc, $response"
		else
			log_warn "$host: $response"
		fi
	else
		if [ "$response" != "" ]; then
			log_debug "response from $host: $response"
		fi
	fi
}

executeCmdOnHosts (){
	cmd=$1
	for host in ${HOSTS[@]}; 
	do
	executeCmd "$host" "$cmd"
	done
}


main (){
	log "Starting to install openstack mandatory services on configured nodes"

	executeCmdOnHosts "systemctl status firewalld.service; getenforce; "

	#1. install chrony service
	log "install chrony services"
	cmd="$ProxyCmd; yum install chrony; sed -i 's/#*server/\#server/g' /etc/chrony.conf; echo 'server $CONTROLLER iburst' >> /etc/chrony.conf; sed -i 's/#*allow/\#allow/g' /etc/chrony.conf; "
	executeCmdOnHosts "$cmd"
	cmd2="sed -i 's/#*server/\#server/g' /etc/chrony.conf; echo 'server 10.8.147.40 iburst' >> /etc/chrony.conf; sed -i 's/#*allow/\#allow/g' /etc/chrony.conf; echo 'allow $SUBNET' >> /etc/chrony.conf;"
	executeCmd "$CONTROLLER" "$cmd2" true
	executeCmdOnHosts "systemctl enable chronyd.service ; systemctl restart chronyd.service; chronyc sources"

	#2. install openstack repo
	# yum install centos-release-openstack-ocata
	# yum install https://rdoproject.org/repos/rdo-release.rpm
	# yum upgrade
	# yum install python-openstackclient
	# yum install openstack-selinux

	#2. install mandantory service on controller node
	cmd="yum -y install mariadb mariadb-server python2-PyMySQL"
	executeCmd "$CONTROLLER" "$cmd" true
	#copy file openstack.cnf to /etc/my.cnf.d/ [manuel step]
	cmd="systemctl enable mariadb.service; systemctl start mariadb.service;"
	executeCmd "$CONTROLLER" "$cmd" true
	#run command mysql_secure_installation to set password for mariadb, manuel step, suggest password zxcb123


	#3. install message queue
	cmd="yum -y install rabbitmq-server; systemctl enable rabbitmq-server.service; systemctl start rabbitmq-server.service"
	executeCmd "$CONTROLLER" "$cmd" true
	cmd="rabbitmqctl add_user openstack zxcb123; rabbitmqctl set_permissions openstack \".*\" \".*\" \".*\"; "
	executeCmd "$CONTROLLER" "$cmd" true


	#4. set memorycache 
	cmd="yum -y install memcached python-memcached"
	executeCmd "$CONTROLLER" "$cmd" true
	cmd="sed -i 's/#*OPTIONS/\#OPTIONS/g' /etc/chrony.conf;; echo 'OPTIONS=\"-l 127.0.0.1,::1, controller\"' >> /etc/sysconfig/memcached;"
	executeCmd "$CONTROLLER" "$cmd" true
	cmd="systemctl enable memcached.service; systemctl start memcached.service"


	#5. identity service
	# mysql -u root -p
	# CREATE DATABASE keystone;
	# GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost'  IDENTIFIED BY 'zxcvb123';
	# GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%'  IDENTIFIED BY 'zxcvb123';
	# yum -y install openstack-keystone httpd mod_wsgi

	#6. image service
	
}

main