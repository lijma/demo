#!/bin/bash

###############################################################
#Description: auto install test enviroment and invoke dr test 
#Author: lijie.ma@nokia.com
#Version: 1.0
#last updated: 2017/4/10
###############################################################

TEST_TAG="$1";
VIIS_DR_IP="$2";
VIIS_USER_PASS="$3";
SDV_PATH="$4";
TARGET_CASES_PATH="$5";
VIIS_USER="root";

#VIIS_DR_IP="10.91.192.131";
#VIIS_USER_PASS="nasroot";

DEBUG=0;
SELF=$(readlink -f $0)
REAL_PATH=`dirname $SELF`;

DR_VM_USER="root";
NETWORK_PROXY="http://10.144.1.10:8080";
SECURE_NETWORK_PROXY="https://10.144.1.10:8080";
INSTALL_PATH="/root/drtest";
CASE_PATH="$INSTALL_PATH/testcases";
GET_PIP_FILE="get-pip.py";
DEFAULT_TEST_CASES="HelloWorldTest.robot";
RESULT_PATH="robot-log";
TEST_RESULT_PATH="$INSTALL_PATH/$RESULT_PATH";

log(){
	msg=$1;
	t=$(date +'%Y:%m:%d %H:%M:%S')
	echo "[$t]$msg";
}

exeCriticalCmdOnAdminServer(){
	cmd="$1 2>&1";
	tag="$2";
	res=$(sshpass -p $VIIS_USER_PASS ssh -o StrictHostKeyChecking=no -q $VIIS_USER\@$VIIS_DR_IP "$cmd");
	code=$?;
	if [ $DEBUG -gt 0 ]; then
		echo "$VIIS_DR_IP executing: $cmd";
	fi
	if [ $code -ne "0" ]; then
		>&2 echo "Error happened, exit code: $code, see: $res";
		if [ $tag -ne "continue" ]; then
			exit 1;
		else
			echo "Continue to next command";	
		fi	
	fi
	echo "$VIIS_DR_IP: $res";
	return 0;
}

sendFileToAdminServer(){
	target=$1;
	sshpass -p $VIIS_USER_PASS scp -q -o StrictHostKeyChecking=no $target $VIIS_USER\@$VIIS_DR_IP:$INSTALL_PATH 2>&1;
	code=$?;
	if [ $code -ne "0" ]; then
		>&2 echo "Error happened when upload file:  to adminServer, exit code: $code";
	fi
	return 0;
}

downloadTestResults(){
	from=$1;
	to=$2;
	sshpass -p $VIIS_USER_PASS scp -q -r -o StrictHostKeyChecking=no $VIIS_USER\@$VIIS_DR_IP:$from $to 2>&1;
	code=$?;
	if [ $code -ne "0" ]; then
		>&2 echo "Error happened when download file from adminServer, exit code: $code";
	fi
	return 0;
}

installRobotFrameWorkOnAdminServer(){
	log "Installing gcc libffi-devel python-devel openssl-devel";
	exeCriticalCmdOnAdminServer "sudo yum -y install gcc libffi-devel python-devel openssl-devel";

	getPipe=$INSTALL_PATH/$GET_PIP_FILE;
	cmd="chmod -R 775 $getPipe; $getPipe --proxy=$SECURE_NETWORK_PROXY;";
	exeCriticalCmdOnAdminServer "$cmd";
	#robotframework-sshlibrary
	cmd="pip install robotframework selenium PyCrypto Paramiko  --proxy=$NETWORK_PROXY"
	exeCriticalCmdOnAdminServer "$cmd";
}

main(){
	#sudo apt-get install sshpass
	log "Starting to invoke dr test on: $VIIS_DR_IP with test tag: $TEST_TAG, sdv path: $SDV_PATH";

	log "Checking install path: $INSTALL_PATH";
	cmd="if [ -d '$INSTALL_PATH' ]; then echo 'folder $INSTALL_PATH already exist'; rm -rf '$CASE_PATH/*'; else echo 'creating folder $INSTALL_PATH;'; mkdir $INSTALL_PATH; mkdir $CASE_PATH; fi";
	exeCriticalCmdOnAdminServer "$cmd";

	log "Copying get-pip.py to AdminServer under $INSTALL_PATH";
	sendFileToAdminServer "$REAL_PATH/$GET_PIP_FILE";

	log "installing robot framework on AdminServer";
	installRobotFrameWorkOnAdminServer;

	log "Upload SDV_PATH to AdminServer";
	sendFileToAdminServer "$REAL_PATH/$SDV_PATH";

	log "case path = $TARGET_CASES_PATH";
	if [ -f "$TARGET_CASES_PATH" ]; then
		log "Sending test cases to AdminServer";
		sendFileToAdminServer "$TARGET_CASES_PATH";
		packageName=`echo $(basename "$TARGET_CASES_PATH")`;
		log "Unzip case package $packageName to $INSTALL_PATH on AdminServer";
		exeCriticalCmdOnAdminServer "tar -xvf $INSTALL_PATH/$packageName -C $CASE_PATH";
	else
		log "No test cases found;";
	fi

	log "No test cases found; Uploading helloworld test case to AdminServer";
	sendFileToAdminServer "$REAL_PATH/$DEFAULT_TEST_CASES";
	exeCriticalCmdOnAdminServer "cp $INSTALL_PATH/$DEFAULT_TEST_CASES $CASE_PATH/";

	log "Running robot cases on AdminServer";
	cmd="pybot --include $TEST_TAG --outputdir $TEST_RESULT_PATH -V $INSTALL_PATH/$SDV_PATH $CASE_PATH";
	exeCriticalCmdOnAdminServer "$cmd" "continue";

	log "Downloading test results to local workspace.";
	downloadTestResults "$TEST_RESULT_PATH" "$REAL_PATH/";
}

main

