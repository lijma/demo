#!/usr/bin/env perl
#===============================================================================
#    DESCRIPTION:  This file is used migrate FM/PM/CM
#    CREATED:      2014/11/14
#===============================================================================

use strict;
use utf8;
use English;
use Getopt::Long;
use drCom;
use drConfMgr;
use Cwd 'abs_path';

my $DEBUG = 0;
my $NO_EXECUTE;

my @SUPPORT_ACTIONS = ("prepare", "updatetime", "import", "export", "sync", "schedule","replicate");

my $NO_TIMESTAMP_FILE_MSG = "Timestamps not set, use 'updatetime -set' to set timestamps.\n";
my $SYNC_PATH = "/var/datasync";
my $EXPORT_PATH = "/mnt/datasync";
chomp(my $SCHEDULE_SCRIPT = abs_path($0));
my %PROCEDURES;

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub handleCommandLineArgs {
    use vars qw(
        $help
        $updateTime
        $action
        @migModules
        $modules
        $setTime
        $syncTime
        $showTime
        $paramEnable
        $paramDisable    
        $skip    
    );

    if (not scalar @ARGV) {
        print STDERR "See: $PROGRAM_NAME -help for more information.\n";
        exit 1;
    }

    if (!GetOptions(
            "help"         => \$help,
            "debug=s"      => \$DEBUG,
            "no-execute"   => \$NO_EXECUTE,
            "module=s"     => \$modules,
            "set=s"        => \$setTime,
            "sync"         => \$syncTime,
            "show"         => \$showTime,
            "enable=s"     => \$paramEnable,
            "disable=s"    => \$paramDisable,
            "skip"         => \$skip
        )) {
        print STDERR "See: $PROGRAM_NAME -help for more information.\n";
        showUsageAndExit(1);
    }

    $action = shift @ARGV;
    $action = lc $action;
    my $actionExist = 0;
    for (@SUPPORT_ACTIONS) {
        if ($_ eq $action) {
            $actionExist = 1;
            last; 
        }
    }

    $help and showUsageAndExit(); 

    if (not $actionExist) {
        print STDERR "No action specified.\n\n";
        showUsageAndExit(1);
    }

     $modules = '' if(not defined $modules);
     chomp($modules);

    if ($action eq 'updatetime' && (not length $modules)) {
        $modules = 'all';
    }

    if (not length $modules) {
        print STDERR "No module specified.\n";
        showUsageAndExit(1);
    }

    @migModules = map { trim(uc $_) } split(/,/, $modules);
    # Un recognized module should lead an error.

    if (scalar @migModules == 1 && $migModules[0] =~ /ALL/) {
        @migModules = @SUPPORT_MODULES;
    }
    else {
        my @orderred = ();
        foreach my $m(@SUPPORT_MODULES) {
            foreach my $i (0 .. $#migModules) {
                if ($m eq $migModules[$i]) {
                    push @orderred, $migModules[$i];
                    splice @migModules, $i, 1;
                    last;
                }
            }
        }
        if (scalar @migModules) {
            print STDERR "Unrecognized module(s): @migModules.\n";
            showUsageAndExit(1);
        }
        @migModules = @orderred;
    }

    chomp($paramEnable) if $paramEnable;
    chomp($paramDisable) if $paramDisable;
    if ($paramEnable && $paramDisable) {
        print STDERR "Unable to proceed with both -enable and -disable specified.\n";
        showUsageAndExit(1);
    }
    my $enOrDisParam = $paramEnable;
    $enOrDisParam = $paramEnable ? $paramEnable : $paramDisable;
    if ($enOrDisParam) {
        if(('import' ne lc $enOrDisParam) && () && ()) {
            print STDERR "Unknown enable/disable target: $enOrDisParam.\n";
            showUsageAndExit(1);
        }
    }
}
 
sub showUsageAndExit {
    my $rc = shift;
    $rc = 0 if (not defined $rc);
    # TODO: consider move action specific parameters description under each action description
    print STDERR << "END_USAGE";
Usage:
    $PROGRAM_NAME <ACTION> -module <MODULES> [OPTIONS...]
    Execute actions specified by ACTION for modules specified by MODULES.

ACTIONS
    prepare:      Prepare envrionment, this action is needed once before export or
                  import data.
    updatetime:   Update the timestamp used for export data.
                  -set TIME          Time for export data from, time should be in any format
                                     date command understand, special time 'now' is valid.
                  -sync              Make timestamps effecitve for export.
                  -show              Show current timestamp(s).
    export:       Export target data to /mnt/datasync/.
    import:       Import target data from /mnt/datasync/.
                  -skip Only valid for CM import. Skip errors while CM object import failed.
    replicate:    Replcate data from source site to target site.
    schedule:     Control the scheduled jobs for import or export, only module fm,pm are supported.
                  -enable import|export|replicate    enable scheduled jobs for import or export.
                  -disable import|export|replicate   disable scheduled jobs for import or export.


MODULES
    pm: Performance management data
    fm: Fault management data
    cm: Configuration management data
    dns: Naming service data
    nasda: NetAct System Data Access
    all: Combination of above

OPTIONS:
    -help | -h    Get the help of usage.
    -debug N      Print debug info.
                  1: Ouput verbose information.
                  2: Ouput more verbose information.
    -no-execute   Print all exectued command without execution.

Examples:
    $PROGRAM_NAME prepare -module FM
    $PROGRAM_NAME updatetime -set "2016-05-21 13:24:56" -sync -module pm
    $PROGRAM_NAME updatetime -set now -module all
    $PROGRAM_NAME updatetime -sync -module pm
    $PROGRAM_NAME updatetime -show
    $PROGRAM_NAME export -module all
    $PROGRAM_NAME import -module fm,pm,cm,dns,nasda -debug 2
    $PROGRAM_NAME replicate -module fm,pm,cm,dns,nasda -debug 2
    $PROGRAM_NAME schedule -enable export -module fm,pm

END_USAGE

    exit $rc;
}

sub debug{
    my $message = shift;
    print("[DEBUG]: $message\n") if $DEBUG > 0;
}

sub logerror{
    my $message = shift;
    drCom::printDrLog($LOG_FILE,$message);    
    print "[error]$message\n" if $DEBUG > 0;
    return 0;
}

sub logInfo{
    my $message = shift;
    drCom::printDrLog($LOG_FILE,$message);    
    print "[INFO]$message\n";
    return 0;
}

sub executeCmd{
    my $cmd = shift;
    my $node = shift;
    
    if ($NO_EXECUTE) {
        return ( "", 0 );
    }
  
    my $isRootAccessChanged = 0;

    #check root access enable on target node or not.
    if(defined $node){
        debug("checking rootacess enabled on node $node");
        chomp($node);
        my $checkcmd = qq{ssh -q dradmin\@$node "sudo cat /etc/ssh/sshd_config | sudo grep 'PermitRootLogin no'"};
        my ($res,$rc) = drCom::execCmd($checkcmd);
        if($rc eq 0){
             debug("root access on node :$node, enabling...");
             my $enableCmd = qq{ssh -q dradmin\@$node $ENABLE_ROOT_ACCESS_CMD};
             my ( $res1, $rc1 ) = drCom::execCmd($enableCmd);   
             if ($rc1){
                logerror("cannot open root access on node :$node, $res1");
                return ($res1, $rc1);
             }
             $isRootAccessChanged = 1;
        }
    }    

    debug("Executing command : $cmd");
    my ($cmdResponse, $errorInfo) = drCom::execCmd($cmd);
    drCom::printDrLog($LOG_FILE,"Executing command: $cmd");

    if ($isRootAccessChanged){
        debug("root access on node :$node, disabling...");
        my $disableCmd = qq{ssh -q $node $DISABLE_ROOT_ACCESS_CMD};
        drCom::execCmd($disableCmd);
        debug("rootacess on node $node disabled");
    }   

    chomp($cmdResponse);
    chomp($errorInfo);

    if ( $errorInfo ) {
       my $errorMsg =  "Error happend when executing command '$cmd' on node '$node', return code $errorInfo, $cmdResponse";
       drCom::printDrLog($LOG_FILE,$errorMsg);
       print STDERR "$errorMsg\n";
    }

    if ( $DEBUG > 1 ) {
        print "[DEBUG][return code]: $errorInfo\n";
        print "[DEBUG][return Info]: $cmdResponse\n";
    }

    return ( $cmdResponse, $errorInfo );
}

sub executeCriticalCmd {
    my $cmd = shift;
    my $node = shift;
    if ($NO_EXECUTE) {
        return ( "", 0 );
    }
    my ($output, $rc) = executeCmd($cmd,$node);
    if($rc){
        print "DR: critical command '$cmd' return with $rc, $output\n";
        exit($rc);
    }
    return 0;
}

$PROCEDURES{'DNS-prepare'} = sub {
    my $dnsMasterNode
        = drConfMgr::getHostnameOnOwnSiteByService("DNS-Master");
    my $dnsSlaveNode
        = drConfMgr::getHostnameOnOwnSiteByService("DNS-Slave");
    
    if( ! $dnsMasterNode || ! $dnsSlaveNode){
        logerror("unable to locate dns master node or dnsSlaveNode from drConfMgr");
        return 1;
    }  

    my $cmd = qq{ssh -q $dnsMasterNode '$DNS_MIGRATE_CMD --action backup --backup_dir $DNS_BACKUP_DIR --master_dns_ip $dnsMasterNode --slave_dns_ip $dnsSlaveNode'};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dnsSlaveNode);
    if($errorInfo){
       logerror("failed to backup DNS data to directory $DNS_BACKUP_DIR/");
       return 1; 
    }

    return 0;
};


$PROCEDURES{'DNS-updatetime'} = sub {
    return 0;
};

$PROCEDURES{'DNS-export'} = sub {
    my $dnsMasterNode
        = drConfMgr::getHostnameOnOwnSiteByService("DNS-Master");
    my $dnsSlaveNode
        = drConfMgr::getHostnameOnOwnSiteByService("DNS-Slave");    

    
    if( ! $dnsMasterNode || ! $dnsSlaveNode){
        logerror("unable to locate dns master node or dnsSlaveNode from drConfMgr");
        return 1;
    }    

    my $cmd
        = qq{ssh -q $dnsMasterNode '[ -d $DNS_EXPORT_DIR ] && \
             rm -rf $DNS_EXPORT_DIR && \
             echo "$DNS_EXPORT_DIR already present. will be overwrited" ; \
             mkdir -p $DNS_EXPORT_DIR/; \
             mkdir -p $DNS_SOURCE_BACKUP_DIR/ && \
             echo "$DNS_EXPORT_DIR created successfully" || \
             { echo "Failed to create $DNS_EXPORT_DIR" ; exit 1 ;}'};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dnsMasterNode);

    if($errorInfo){
       logerror("export dns from master node failed");
       return 1; 
    }

    $cmd = qq{ssh -q $dnsMasterNode 'rsync -avz $DNS_BACKUP_DIR/ $DNS_SOURCE_BACKUP_DIR/'};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dnsSlaveNode);
    if($errorInfo){
       logerror("failed to sync backup $DNS_BACKUP_DIR/ to directory $DNS_SOURCE_BACKUP_DIR/");
       return 1; 
    }

    $cmd = qq{ssh -q $dnsMasterNode '$DNS_MIGRATE_CMD --action backup --backup_dir $DNS_SOURCE_DIR --master_dns_ip $dnsMasterNode --slave_dns_ip $dnsSlaveNode'};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dnsSlaveNode);
    if($errorInfo){
       logerror("failed to export source $DNS_SOURCE_DIR/ to directory $DNS_SOURCE_DIR/");
       return 1; 
    }

    return 0;
};

$PROCEDURES{'DNS-import'} = sub {
    
    my $dnsMasterNode
        = drConfMgr::getHostnameOnOwnSiteByService("DNS-Master");
    my $dnsSlaveNode = drConfMgr::getHostnameOnOwnSiteByService("DNS-Slave");

    if( ! $dnsMasterNode || ! $dnsSlaveNode){
        logerror("unable to locate dns nodes from drConfMgr");
        return 1;
    } 

    my $cmd = qq{ssh -q $dnsMasterNode '$DNS_MIGRATE_CMD --action import --source_dir $DNS_EXPORT_DIR --master_dns_ip $dnsMasterNode --slave_dns_ip $dnsSlaveNode'};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dnsMasterNode);
    return $errorInfo;
};

$PROCEDURES{'DNS-replicate'} = sub {
    my @dnsMasterNode = drConfMgr::getHostnamesByPureService("DNS-Master");

    if( ! @dnsMasterNode){
        logerror("unable to locate dns nodes from drConfMgr");
        return 1;
    } 

    return syncModule("dns",@dnsMasterNode);
};


$PROCEDURES{'PM-updatetime'} = sub {
    my @pmNodeList = drConfMgr::getHostnamesByPureService("etlpsl");

    if( ! @pmNodeList){
        logerror("unable to locate pm nodes from drConfMgr");
        return 1;
    } 

    my @timestamps = readFile($TIMESTAMPS_FILE);
    my $pmFrom;

    foreach (@timestamps) {
        if (/PM:EXPORT:FROM/) {
            my ($name, $time) = split(/=/, $_);
            $pmFrom = $time;
            last;
        }
    }

    print "Unable to find timestamp for PM" unless $pmFrom;
    return 2 unless $pmFrom;

    foreach my $node (@pmNodeList) {
        debug ("Updating PM timestamps on $node");
        my $cmd = qq{ssh -q $node 'touch -d "$pmFrom" /var/tmp/timestamp' 2>&1};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0);
    }
    return 0;
};

$PROCEDURES{'PM-prepare'} = sub {
    my @pmNodeList = drConfMgr::getHostnamesByPureService("etlpsl");

    if( ! @pmNodeList){
        logerror("unable to locate pm nodes from drConfMgr");
        return 1;
    } 

    my $cmd = qq{ssh -q $pmNodeList[0] "$PM_PREPARE_CMD 2>&1"};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$pmNodeList[0]);
    return $errorInfo;
};

$PROCEDURES{'PM-export'} = sub {
    my @pmNodeList = drConfMgr::getHostnamesByPureService("etlpsl");

    if( ! @pmNodeList){
        logerror("unable to locate pm nodes from drConfMgr");    
        return 1;
    } 

    foreach my $pmNode ( @pmNodeList ){
        my  $cmd = qq{ssh -q $pmNode '$PM_EXPORT_CMD 2>&1'};
        my  ($cmdResponse, $rc) = executeCmd($cmd, $pmNode);
        return 1 if ($rc > 0);
    }
    return 0;

};

$PROCEDURES{'PM-import'} = sub {
    my @pmNodeList = drConfMgr::getHostnamesByPureService("nfs");

     if( ! @pmNodeList){
        logerror("unable to locate pm nodes from drConfMgr");    
        return 1;
    } 

    my $cmd = qq{ssh -q $pmNodeList[0] '$PM_IMPORT_CMD 2>&1'};
    my ($cmdResponse, $rc) = executeCmd($cmd,$pmNodeList[0]);         
    return $rc;
};

$PROCEDURES{'PM-replicate'} = sub {
    my @pmNodeList = drConfMgr::getHostnamesByPureService("etlpsl");

    if( ! @pmNodeList){
        logerror("unable to locate pm nodes from drConfMgr");
        return 1;
    } 

    return syncModule("pm",@pmNodeList);
};


$PROCEDURES{'FM-prepare'} = sub {
    my @dbNodes = drConfMgr::getHostnamesByPureService("db");

    # Assert scalar $dbNodes == 1;
     my $dbNode;
    chomp($dbNode = shift @dbNodes);
    if (! $dbNode) {
        logerror("unable to locate db nodes from drConfMgr");
        return 1;
    }

    my $cmd = qq{ssh -q $dbNode $FM_PREPARE_CMD};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dbNode);
    return $errorInfo;
};

$PROCEDURES{'FM-updatetime'} = sub {
    my @nodes = drConfMgr::getHostnamesByPureService("db");
    my $dbNode;
    chomp($dbNode = shift @nodes);
    if (! $dbNode) {
         logerror("unable to locate db nodes from drConfMgr");
        return 1;
    }

    my @timestamps = readFile($TIMESTAMPS_FILE);
    my $fmFrom;

    foreach (@timestamps) {
        if (/FM:EXPORT:FROM/) {
            my ($name, $time) = split(/=/, $_);
            $fmFrom = $time;
            last;
        }
    }  
 
    print "Unable to find timestamp for FM" unless $fmFrom;
    return 2 unless $fmFrom;
  
    chomp($fmFrom = qx{date -d\"$fmFrom\" +\"\%d\/\%m\/\%Y \%H:\%M:\%S\"});

    debug("Updating FM timestamps on $dbNode\n");
    my $cmd = qq{ssh -q $dbNode 'echo "$fmFrom" > /var/opt/oss/log/mtools/temp/refTime.cf' 2>&1};
    my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$dbNode);
    return $errorInfo;
};

$PROCEDURES{'FM-export'} = sub {
    my @nodes = drConfMgr::getHostnamesByPureService("db");
    my $dbNode;
    chomp($dbNode = shift @nodes);

    my ( $ownNode, $errorInfo ) = executeCmd(qq{hostname});
    chomp($ownNode);

    debug("db node is:  $dbNode, ownnode is $ownNode\n");
    if (! $dbNode || ! $ownNode || $dbNode ne $ownNode) {
        logerror("current node is not the db node");
        return 1;
    }

    my $cmd = qq{ssh -q $dbNode '$FM_EXPORT_CMD 2>&1'};
    my ($cmdResponse, $rc) = executeCmd($cmd,$dbNode);
    return $rc;
};

$PROCEDURES{'FM-import'} = sub  {
    my @nodes = drConfMgr::getHostnamesByPureService("db");
    my $dbNode;
    chomp($dbNode = shift @nodes);

    my ( $ownNode, $errorInfo ) = executeCmd(qq{hostname});
    chomp($ownNode);

    debug("db node is:  $dbNode, ownnode is $ownNode\n");
    if (! $dbNode || ! $ownNode || $dbNode ne $ownNode) {
        logerror("current node is not the db node");
        return 1;
    }

    my $cmd = qq{ssh -q $dbNode '$FM_IMPORT_CMD 2>&1'};
    my ($cmdResponse, $rc) = executeCmd($cmd,$dbNode);
    return $rc;
};

$PROCEDURES{'FM-replicate'} = sub {
    my @dbnodes = drConfMgr::getHostnamesByPureService("db");
    my @dmgrnodes = drConfMgr::getHostnamesByPureService("dmgr");

    if (! @dbnodes || !@dmgrnodes) {
         logerror("unable to locate dmgr or db nodes from drConfMgr");
        return 1;
    }

    my @fmNodes;
    push(@fmNodes,@dbnodes);
    push(@fmNodes,@dmgrnodes);

    return syncModule("fm",@fmNodes);
};


$PROCEDURES{'CM-prepare'} = sub {
    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    #remove execution status before
    foreach my $node (@drmgrNodeList) {
        my $cmd = qq{ssh -q $node 'rm -rf /opt/oss/mtools/nzdt-data-sync/status/*.CM*'};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0);
    }
    return 0;
};

$PROCEDURES{'CM-updatetime'} = sub {

    my @cmNodeList = drConfMgr::getHostnamesByPureService("dmgr");

    if (!@cmNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    my @timestamps = readFile($TIMESTAMPS_FILE);
    my $cmFrom;

    foreach (@timestamps) {
        if (/CM:EXPORT:FROM/) {
            my ($name, $time) = split(/=/, $_);
            $cmFrom = $time;
            last;
        }
    }

    print "Unable to find timestamp for CM" unless $cmFrom;
    return 2 unless $cmFrom;

    chomp($cmFrom = qx{date -d\"$cmFrom\"  +\"\%Y-\%m-\%d \%H:\%M\"});
    foreach my $node (@cmNodeList) {
        debug("updating CM timestamps on $node");
        my $cmd = qq{ssh -q $node "echo -n 'FREEZE_TIME_STAMP=\\\"$cmFrom\\\"' > /mnt/datasync/Freeze_time.conf 2>&1"};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }

    return 0;
};

$PROCEDURES{'CM-export'} = sub {
    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }
    foreach my $node (@drmgrNodeList) {
        my $cmd = qq{ssh -q $node 'rm -rf /opt/oss/mtools/nzdt-data-sync/status/*.CM*'};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
        $cmd = qq{ssh -q $node '$CM_MGR_CMD export CM'};
        ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }

    return 0;
};

$PROCEDURES{'CM-import'} = sub {
    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    my $cmd;
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    foreach my $node (@drmgrNodeList) {

        if (not($skip)) {
            $cmd = qq{ssh -q $node 'rm -rf /opt/oss/mtools/nzdt-data-sync/status/*.CM*'};
            my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
            return 1 if ($errorInfo > 0) ;
        }
        $cmd = qq{ssh -q $node '$CM_MGR_CMD import CM'};
        my ($cmdResponse,$errorInfo) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }
    return 0;
};

$PROCEDURES{'CM-replicate'} = sub {
    my @dmgrNodes = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@dmgrNodes) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }
    return syncModule("cm",@dmgrNodes);
};



$PROCEDURES{'NASDA-prepare'} = sub {
    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    #remove execution status before
    foreach my $node (@drmgrNodeList) {
        my $cmd = qq{ssh -q $node 'rm -rf /opt/oss/mtools/nzdt-data-sync/status/*.NASDA*'};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }
    return 0;
};

$PROCEDURES{'NASDA-updatetime'} = sub {

    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    my @timestamps = readFile($TIMESTAMPS_FILE);
    my $timestamp;

    foreach (@timestamps) {
        if (/NASDA:EXPORT:FROM/) {
            my ($name, $time) = split(/=/, $_);
            $timestamp = $time;
            last;
        }
    }

    print "Unable to find timestamp for CM" unless $timestamp;
    return 2 unless $timestamp;

    chomp($timestamp = qx{date -d\"$timestamp\"  +\"\%Y-\%m-\%d \%H:\%M\"});
    foreach my $node (@drmgrNodeList) {
        debug("Updating NASDA timestamps on $node");
        my $cmd = qq{ssh -q $node "echo -n 'FREEZE_TIME_STAMP=\\\"$timestamp\\\"' > /mnt/datasync/Freeze_time.conf 2>&1"};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }

    return 0;
};

$PROCEDURES{'NASDA-export'} = sub {
    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    foreach my $node (@drmgrNodeList) {
        my $cmd = qq{ssh -q $node 'rm -rf /opt/oss/mtools/nzdt-data-sync/status/*.NASDA*'};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
        $cmd = qq{ssh -q $node '$CM_MGR_CMD export NASDA'};
        ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }
    return 0;
};

$PROCEDURES{'NASDA-import'} = sub {
    my @drmgrNodeList = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@drmgrNodeList) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    foreach my $node (@drmgrNodeList) {
        my $cmd = qq{ssh -q $node 'rm -rf /opt/oss/mtools/nzdt-data-sync/status/*.NASDA*'};
        my ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        $cmd = qq{ssh -q $node '$CM_MGR_CMD import NASDA'};
        ( $cmdResponse, $errorInfo ) = executeCmd($cmd,$node);
        return 1 if ($errorInfo > 0) ;
    }
    return 0;
};

$PROCEDURES{'NASDA-replicate'} = sub {
    my @dmgrNode = drConfMgr::getHostnamesByPureService("dmgr");
    if (!@dmgrNode) {
        logerror("unable to locate dmgr nodes from drConfMgr");
        return 1;
    }

    return syncModule("nasda",@dmgrNode);
};


sub syncModule{

    my $moduleName = shift;
    my $syncFrom = "$SYNC_PATH/$moduleName/";

    my @NodesForSync = shift;
    foreach my $node (@NodesForSync) {
        my $cmd = qq{ssh -q $node "df -Ph |grep $SYNC_PATH |grep $EXPORT_PATH"};
        executeCriticalCmd($cmd,$node);
    }

    my $nfsNode = drConfMgr::getHostnameOnOwnSiteByService("nfs");
    my $cmd = qq{ssh -q $nfsNode "cat /etc/fstab |grep $SYNC_PATH"};
    executeCriticalCmd($cmd,$nfsNode);

    my $nfsNodeOntargetSite = drConfMgr::getDrHostnameOnStandbySiteByService("nfs");
    $cmd = qq{ssh -q $nfsNodeOntargetSite "cat /etc/fstab |grep $SYNC_PATH"};
    executeCriticalCmd($cmd,$nfsNode);

    my $synccmd = qq{ssh -q dradmin\@$nfsNode "sudo rsync -e ssh -av --remove-source-files $syncFrom $nfsNodeOntargetSite:$syncFrom --timeout 1800 >/dev/null"};
    my ( $cmdResponse, $errorInfo ) = executeCmd($synccmd,$nfsNode);
    return $errorInfo; 
}

sub escapeForShell {
   my $par = shift;
   $par =~ s/'/'"'"'/g;
   return "'$par'";
 }
 
sub readFile {
    my $fileName = shift;
    my ($ignoreError) = @_;
    my @lines = ();

    if (open(my $fh, '<:encoding(UTF-8)', $fileName)) {
        while (my $row = <$fh>) {
            chomp($row);
            push @lines, $row if $row;
        }
        close($fh);
    } elsif (not $ignoreError) {
        die "Could not open file '$fileName' $!";
    }

    return @lines;
}

sub writeFile {
    my $fileName = shift;
    my @lines = @_;
    if (open(my $fh, '>:encoding(UTF-8)', $fileName)) {
        foreach ( @lines) {
            print $fh "$_\n";
        }
        close $fh;
    }
    else {
        print "Unable to write timestamp file $fileName\n";
        return 2;
    }

    return 0;
}

sub handleTimestamps {
    if ($showTime) {
        my @ts = readFile($TIMESTAMPS_FILE);
        foreach (@ts) {
            print "$_\n";
        }
        return 0;
    }

    if ($setTime) {
        my $newTimestamp;
        if ('now' eq (lc $setTime)) {
            $newTimestamp = qx{date +"\%Y-\%m-\%d \%H:\%M:\%S\%:z"};
        }
        else {
            my $epoch = qx{date -d"$setTime" +\%s 2>&1 };
            chomp($epoch);
            if ($epoch =~ /invalid/) { 
                print "Unrecognized time format.\n";
                return 1;
            }

            $newTimestamp = qx{date -d"$setTime" +"\%Y-\%m-\%d \%H:\%M:\%S\%:z"};
            chomp($newTimestamp);
            debug("Parsed given $setTime to $newTimestamp");
        }

        if ($newTimestamp =~ /invalid/) { 
            print "Unrecognized time format.\n";
            return 1;
        }

        debug("Update timestamp to $newTimestamp");

        my @timestamps = readFile($TIMESTAMPS_FILE,1);
        foreach my $module (@migModules) {
            my $set = 0;
            foreach (@timestamps) {
                my($name, $time) = split(/=/, $_);
                if ($name eq "$module:EXPORT:FROM") {
                    s/.*/$module:EXPORT:FROM=$newTimestamp/;
                    $set = 1;
                }
            }
            if (not $set) {
                drCom::printDrLog($LOG_FILE,"update timestamp '$newTimestamp' to $TIMESTAMPS_FILE");
                push @timestamps, "$module:EXPORT:FROM=$newTimestamp";
            }
        }

        writeFile($TIMESTAMPS_FILE,@timestamps);
    }

    return 0 unless $syncTime;
    return executeAction();
}

sub handleSchedule {
    if (not scalar @migModules){
        print "Module not specified";
        return 1;
    }

    if(!$paramEnable && !$paramDisable){
        print "enable or disable not specified\n";
        return 1;
    }

    my @schduleModlues = ();
    foreach (@migModules){
        if((lc $_ eq "fm") || (lc $_ eq "pm")) {
            push @schduleModlues, $_;
        } else {
            print ("Unsupported module $_, ignored.\n")
        }
    }

    if ( 0 == scalar @schduleModlues) {
        print "no supported module specified \n";
        return 1;
    }

    my $migAction = $paramEnable ? $paramEnable : $paramDisable;

    foreach my $sm (@schduleModlues){
        $sm = lc $sm;
        my $timestamp = getCronLineByModuleAndAction($sm,$migAction);
        my $line = "$timestamp  root  $SCHEDULE_SCRIPT $migAction -module $sm";

        if ($paramEnable) {
            addCronLine($line);
        }
        else {
            removeCronLine($line);
        }
    }
    return 0;
}

sub getCronLineByModuleAndAction {
    my $module = lc shift;
    my $action = lc shift;

    # TODO read from file

    #return default values if file not exists.
    if (($module eq "fm") && ($action eq "export")){
        return "0 * * * *";
    }
    elsif (($module eq "pm") && ($action eq "export")){
        return "15 * * * *";
    }
    elsif (($module eq "fm") && ($action eq "replicate")){
        return "30 * * * *";
    }
    elsif (($module eq "pm") && ($action eq "replicate")){
        return "30 * * * *";
    }
    elsif (($module eq "fm") && ($action eq "import")){
        return "45 * * * *";
    }
    elsif (($module eq "pm") && ($action eq "import")){
        return "45 * * * *";
    }
    else{
        print "undefined timestamp for module $module and action $action \n";
        return 1;
    }
}
 
sub addCronLine {
    my $line = shift;
    my @lines = readFile($SCHEDULE_CRON_FILE, 1);
    for (@lines) {
        if ($line eq $_) {
            return 0;
        }
    }
    drCom::printDrLog($LOG_FILE,"add cron '$line' to $SCHEDULE_CRON_FILE");
    push @lines, $line;
    writeFile($SCHEDULE_CRON_FILE, @lines);
    return 0;
}


sub removeCronLine {
    my $line = shift;
    my @lines = readFile($SCHEDULE_CRON_FILE);
    foreach my $index (0 .. $#lines) {
         if ($line eq $lines[$index]) {
             delete $lines[$index];
             drCom::printDrLog($LOG_FILE,"remove cron '$lines[$index]' to $SCHEDULE_CRON_FILE");
             writeFile($SCHEDULE_CRON_FILE, @lines);
             return 0;
         }
    }
}

sub executeAction {
    my $rc = 11;
    foreach my $sm (@migModules) {
        my $logic = $PROCEDURES{"$sm-$action"};
        if (not $logic)  {
           logerror "Action $action is not supprted for $sm.\n";
           return 2;
        }
        logInfo("Executing $sm $action...");
        drCom::printDrLog($LOG_FILE,"Executing $sm $action**********************************************");
        $rc = &$logic();
        if ($rc) {
            logInfo "action $action on module $sm failed with error code $rc.\n";
            drCom::printDrLog($LOG_FILE,"Executing $sm $action failed**********************************************");
            last;
        }
        logInfo(" $sm $action succeed.\n");
        drCom::printDrLog($LOG_FILE,"Executing $sm $action succeed**********************************************");
    }
    logerror "No action performed\n" if ($rc == 11);
    return $rc;
}

sub createLogDir{

     my $cmd = qq{ if [ -d  $LOG_FILE_DIR ];  \
           then echo $LOG_FILE_DIR already exists; \
           else mkdir -p $LOG_FILE_DIR 2>&1; chmod 775 $LOG_FILE_DIR 2>&1;echo $LOG_FILE_DIR create successfully ;\
           fi };
     executeCriticalCmd($cmd);
}

sub main {
    handleCommandLineArgs();
    createLogDir();
    return handleTimestamps() if ($action eq 'updatetime');
    return handleSchedule() if ($action eq 'schedule');
    return executeAction();
}

exit main();
