#!/bin/bash

PROJECT_PATH="/home/lijma/gits/tmms"
APP_NAME="tmms-1.0"
SEVER_IP=""
PACKAGE_DEPLOY_PATH="/opt/tomcat1/webapps/"
SERVER_START_CMD="sudo service tomcat1 start"
SERVER_SHUTDOWN_CMD="sudo service tomcat1 stop"
TARGET_PATH="target/tmms-1.0.war"

exeCmd(){
	sshpass -p '**' ssh root@${SEVER_IP} $1
} 

main(){
	cd ${PROJECT_PATH}

	echo "reduilding the package."
	mvn clean install > /dev/null
	
	echo "shut down the web server"
	exeCmd "${SERVER_SHUTDOWN_CMD}"
	
	echo "undeploy the app package."
	exeCmd "rm -rf ${PACKAGE_DEPLOY_PATH}${APP_NAME}*"
	
	echo "deploying the package."
	sshpass -p 'manager-ma' scp ${TARGET_PATH} manager-ma@${SEVER_IP}:${PACKAGE_DEPLOY_PATH}
	
	echo "restart the web server"
	exeCmd "${SERVER_START_CMD}"
	
	echo "deploy successfully!"
}

main


