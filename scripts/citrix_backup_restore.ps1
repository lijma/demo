<#
.SYNOPSIS
    This file is used backup and restore citrix data 
           
.DESCRIPTION
    action backup|restore [mandatory]
           backup: export Citrix data from local.
           restore: import Citrix data from local.
    filePath [optional]
           the file path for backup or restore. 
           default is "D:\var\nokia\oss\nms\global\citrix\"   
.PARAMETER action  
    [mandatory] backup|restore
        backup: export Citrix data from local.
        restore: import Citrix data from local.        
.PARAMETER filePath  
    [optional]
       the file path for backup or restore. 
       default value: D:\var\nokia\oss\nms\global\citrix\      
         
.EXAMPLE
    citrix_backup_restore.ps1 -action backup

.EXAMPLE   
    citrix_backup_restore.ps1 -action restore
    
.EXAMPLE   
    citrix_backup_restore.ps1 -action backup -filePath D:\tmp\  

#>
param(
    [string]$action,
    [String]$filePath
)

$LOG_PATH = "C:\Apps\Oss\log\nms\"
$LOG_FILE = "Citrix.log"
$SELF_SCRIPT = $MyInvocation.MyCommand.Definition
$REGISTRY_PATH = "HKLM:\Software\OSS\NMS_SPF\"
$DEFAULT_FILE_PATH = "D:\var\nokia\oss\nms\global\citrix\"
$PATH = $null
$FILE_CITRIXLOGGING = "nms-CitrixLogging.bak"
$FILE_CITRIXMONITOR = "nms-CitrixMonitor.bak"
$FILE_CITRIXDEFAULTSITE = "nms-CitrixDefaultSite.bak"
$BACKUP_FOR_RESTORE_PATH = "D:\var\nokia\oss\nms\local\citrix\"

Trap [Exception] {
    log "ERROR" $_.Exception
    EXIT 1
}

function paraArgs{
    if ($action -eq $null -or ($action -ne "backup" -and $action -ne "restore")){
        throw "Wrong paramters!, use 'get-help $SELF_SCRIPT' for more information."
    }

    if (($filePath -ne $null) -and ($filePath.Trim() -ne "") ){
        if ( -not (Test-Path $filePath) ){
          throw "Wrong paramters!,file path '$filePath' no exists."  
        }
        $script:PATH = $filePath
    }else{
        if ( -not (Test-Path $DEFAULT_FILE_PATH) ){
          md $DEFAULT_FILE_PATH | Out-Null
        }
        $script:PATH = $DEFAULT_FILE_PATH
    }
    
}

function log{
   Param(
        [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
        [String]
        $Level = "INFO",
        [Parameter(Mandatory=$True)]
        [string]
        $Message
   ) 
   Process{
       if ( -not (Test-Path $LOG_PATH) ){
          md $LOG_PATH | Out-Null
       }
       $curreTime = get-date
       
       # append log to console | file
       add-Content "$LOG_PATH$LOG_FILE" "[$curreTime][$Level]$Message" 
       Write-output "[$Level]$Message"
       return
   }
}

function checkIfPrimaryNode{
    try{
        $map = get-itemproperty $REGISTRY_PATH -erroraction stop
        $isPramaryNode = $map.PrimarySQLServer
        
        if($isPramaryNode -eq "Yes"){
            return $true
        }
        return $false
    }Catch [System.Management.Automation.ItemNotFoundException] {
        log "ERROR" $_.Exception
        exit 1
    }
}


function backUp{
   Param(
        [Parameter(Mandatory=$True)]
        [string]
        $backupPath
   ) 
   Process{
        log "INFO" "Backup citrix data for database CitrixLogging..."
        invoke-sqlcmd -query "backup database CitrixLogging to disk = '$backupPath$FILE_CITRIXLOGGING'" -erroraction stop
        
        log "INFO" "Backup citrix data for database CitrixMonitor..."
        invoke-sqlcmd -query "backup database CitrixMonitor to disk = '$backupPath$FILE_CITRIXMONITOR'" -erroraction stop
        
        log "INFO" "Backup citrix data for database CitrixDefaultSite..."
        invoke-sqlcmd -query "backup database CitrixDefaultSite to disk = '$backupPath$FILE_CITRIXDEFAULTSITE'" -erroraction stop
        return
   }
}

function restore{

    if ( -not (Test-Path $BACKUP_FOR_RESTORE_PATH) ){
          md $BACKUP_FOR_RESTORE_PATH | Out-Null
    }

    log "INFO" "Backup citrix data for database CitrixLogging,CitrixMonitor,CitrixDefaultSite to local..."	
    backup $BACKUP_FOR_RESTORE_PATH
    log "INFO" "Remove citrix data for database CitrixLogging,CitrixMonitor,CitrixDefaultSite..."
    invoke-sqlcmd -query "USE master IF EXISTS(select * from sys.databases where name='CitrixLogging') BEGIN ALTER DATABASE CitrixLogging SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE CitrixLogging END" -erroraction stop
    invoke-sqlcmd -query "USE master IF EXISTS(select * from sys.databases where name='CitrixMonitor') BEGIN ALTER DATABASE CitrixMonitor SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE CitrixMonitor END" -erroraction stop
    invoke-sqlcmd -query "USE master IF EXISTS(select * from sys.databases where name='CitrixDefaultSite') BEGIN ALTER DATABASE CitrixDefaultSite SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE CitrixDefaultSite END" -erroraction stop
      
    log "INFO" "Restore citrix data for database CitrixLogging..."
    invoke-sqlcmd -query "restore database CitrixLogging from disk = '$DEFAULT_FILE_PATH$FILE_CITRIXLOGGING'" -erroraction stop
    log "INFO" "Restore citrix data for database CitrixMonitor..."
    invoke-sqlcmd -query "restore database CitrixMonitor from disk = '$DEFAULT_FILE_PATH$FILE_CITRIXMONITOR'" -erroraction stop
    log "INFO" "Restore citrix data for database CitrixDefaultSite..."
    invoke-sqlcmd -query "restore database CitrixDefaultSite from disk = '$DEFAULT_FILE_PATH$FILE_CITRIXDEFAULTSITE'" -erroraction stop
 
}

function main{
   
   paraArgs
   
   log "INFO" "Run '$SELF_SCRIPT -action $action -filePath $script:PATH$FILE' started."
   
   $isPramarynode = checkIfPrimaryNode
   if (-not $isPramarynode){
      throw "$SELF_SCRIPT must be executed on sqlserver primary node"
   }
   
   if ($action -eq "backup"){
        log "INFO" "Backup citrix data for database CitrixLogging,CitrixMonitor,CitrixDefaultSite to global..."
        backup $PATH
   }elseif($action -eq "restore"){
        restore
   }
   
   log "INFO" "Run '$SELF_SCRIPT -action $action -filePath $script:PATH' successfully."  
}  

main


