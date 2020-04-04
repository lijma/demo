#author:lijie.ma

#!/bin/bash

#define variables
SHELL_VERSION='1.0'

#TEMP_SORT TEMPFILE PATH , you have sure the TEMPFILE_PATH is right path.
ARCHIVELOG_LOCATION="/d/db-arc/oss"
ARCHIVELOG_LOCATION_FILES="/d/db-arc/oss/*"
TEMPFILE_PATH_SORT='/d/db/oradata/oss/temp_sort01.dbf'
TEMPFILE_PATH='/d/db/oradata/oss/temp01.dbf'
TEMPFILE_MAXSIZE=20G

#BASIC FUNCTIONS
function support(){
echo ""
echo  "###################### YOU ARE USEING RDS.SH ######################################"
echo  "description:  a shell for reducing disk space automatically ! "
echo  "cur-support:  MENUCIUS TEAM"
echo  "cur-version:  $SHELL_VERSION"
echo  "create-time:  1/1 2015" 
}

function close(){
echo  ""
echo  "thanks for using it , we will try to make it better."
echo  "###################### RDS.SH IS ClOSING DOWN #####################################"
echo  ""
exit 0	
}

function printprocess(){
echo ""
echo  "#--------------------------------------------RDS.SH"
echo  "# $1 : $2"
echo  "#--------------------------------------------------"
}

function printstep(){
echo  "[RDS.SH]STEP $1 : $2"
}

#BUSINIESS FUNCTIONS
function gethappentime(){
happentime=$(date "+%Y-%m-%d %H:%M:%S")
printstep "$1 TIME" "$happentime"
}

function showDBStatus(){
startinfo=`
sqlplus omc/omc<<EOF
exit
EOF
`
echo "$startinfo" |grep -q "Connected to"
if [ $? -eq 0 ]
then
    printstep "DB_STATUS" "ON"
else
    printstep "DB_STATUS" "OFF"
fi
}

function showLogSpace(){
spaceinfo=`df -h /d/db-arc/oss`
SPACENUMBER=`echo $spaceinfo | cut -d " " -f 12`
printstep "CURRENT DB SPACE USED%"  "$SPACENUMBER"
}

function process_daloff(){
printprocess "process" "Disabling Archive Logs"
printstep 1 "maintenance db on"
smanager.pl maintenance db on
printstep 2 "Turn off archive logs"
su - oracle <<EOF
/opt/cpf/bin/cpforacle_instance_archivelog_mode.sh  --archMode Off
EOF
printstep 3 "maintenance db off"
smanager.pl maintenance db off
}

function process_dalon(){
printprocess "process" "Enabling Archive Logs"
printstep 1 "maintenance db on"
smanager.pl maintenance db on
printstep 2 "Turn On archive logs"
su - oracle <<EOF
/opt/cpf/bin/cpforacle_instance_archivelog_mode.sh  --archMode ON
EOF
printstep 3 "maintenance db off"
smanager.pl maintenance db off
}

function process_deleteArchiveLogs(){
printprocess "process" "Deleting ArchiveLogs and Disable archivelog  Mode"
printstep 1 "maintenance db on"
smanager.pl maintenance db on
printstep 2 "show and deleting files at $ARCHIVELOG_LOCATION"
filenumber=`ls $ARCHIVELOG_LOCATION|wc -l`
echo "Log file number :  $filenumber"
rm -rf $ARCHIVELOG_LOCATION_FILES
printstep 3 "deleting files related in database"
su - oracle <<EOF
/opt/cpf/bin/cpforacle_instance_archivelog_mode.sh  --archMode ON
cd $ORACLE_HOME/bin ls /
rman target / <<END 
list archivelog all;
crosscheck archivelog all;
delete noprompt expired archivelog all;
END
EOF
printstep 4 "Set AcrhiveLog Mode OFF"
su - oracle <<EOF
/opt/cpf/bin/cpforacle_instance_archivelog_mode.sh  --archMode OFF
EOF
printstep 5 "maintenance db off"
smanager.pl maintenance db off
printstep 6 "delete success"
}

function  process_rnsredlog(){
printprocess "process" "Reducing Number/Size of Redo Logs"
printstep 1 "Connect to database as sysdba "
printstep 2 "Determine redo status and files"
printstep 3 "Drop or re-create inactive redo logs , follow the details."
su - oracle <<EOF
sqlplus / as sysdba
#SELECT G.GROUP#,G.BYTES,G.ARCHIVED,G.STATUS,M.MEMBER FROM V\$LOG G,V\$LOGFILE M WHERE M.GROUP#=G.GROUP# ORDER BY GROUP#,MEMBER;
#ALTER SYSTEM SWITCH LOGFILE;
#ALTER DATABASE DROP LOGFILE GROUP <group-number>;
#ALTER DATABASE ADD LOGFILE GROUP <group-number> '<member-path>' SIZE <file-size>;
exit;
EOF
}

function process_rstempsort(){
printprocess "process" "Reducing Size of TEMP_SORT"
printstep 1 "Connect to database as sysdba "
printstep 2 "Shrink TEMP_SORT table space"
printstep 3 "Check TEMP_SORT usage"
printstep 4 "Set maximum size for TEMP_SORT data file"
su - oracle <<EOF
sqlplus / as sysdba
ALTER TABLESPACE TEMP_SORT SHRINK SPACE;
SELECT TS.NAME,F.NAME,F.BYTES/1024/1024 AS SIZE_MB FROM V\$TABLESPACE TS,V\$TEMPFILE F WHERE F.TS#=TS.TS#;
ALTER DATABASE TEMPFILE '$TEMPFILE_PATH_SORT' AUTOEXTEND ON MAXSIZE $TEMPFILE_MAXSIZE;
--ALTER DATABASE TEMPFILE '$TEMPFILE_PATH' AUTOEXTEND ON MAXSIZE $TEMPFILE_MAXSIZE;
SELECT FILE_NAME,MAXBYTES/1024/1024/1024 from DBA_TEMP_FILES;
exit;
EOF
}

#default runner
function start(){
printprocess "ACTION " "start information"
gethappentime "START"	
showDBStatus
showLogSpace		
}

function end(){
printprocess "ACTION" "end information"
gethappentime "END"	
showDBStatus
showLogSpace
}

function  default(){
support
start
process_deleteArchiveLogs	
#process_rnsredlog
process_rstempsort
end
close
}

#enabling achive log runner
function  eal(){
support	
start
process_dalon
end
close
}
#disabling achive log runner
function  dal(){
support	
start
process_daloff
end
close
}
#disabling achive log runner
function  deleteals(){
support	
start
process_deleteArchiveLogs
end
close
}

#actions below there
if [ $# -gt 1 ] ; then 
echo "USAGE1: $0" 
echo "USAGE2: $0 COMMANDOR " 
exit 1; 
fi 

if [ $# == 0 ] ; then 
default
fi 

if [ $1 == "--achivelogon" ] ; then
     eal
elif [ $1 == "--achivelogoff" ] ; then
    dal
elif [ $1 == "--achivelogdelete" ] ; then
    deleteals
else
    echo "$0: used for deleting archive logs , making the archive mode off , and reducing size of TEMP_SORT"
    echo "$0 --achivelogon : used for Enabling Archive Logs "
    echo "$0 --achivelogoff : used for disabling Archive Logs "
    echo "$0 --achivelogdelete : used for delete Archive Logs files and db records"
fi