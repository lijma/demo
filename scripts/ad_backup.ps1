<#
.SYNOPSIS
    This file is used backup active directory data 
           
.DESCRIPTION
    filePath [optional]
           the file path for backup
           default value: D:\var\nokia\oss\nms\global\ad\
    
.PARAMETER filePath  
    [optional]
       the file path for backup 
       default value: D:\var\nokia\oss\nms\global\ad\      
        
.EXAMPLE   
    ad_backup.ps1 -filePath D:\tmp\  
#>
param(
    [String]$filePath
)

$LOG_PATH = "C:\Apps\Oss\log\nms\"
$LOG_FILE = "ad.log"
$SELF_SCRIPT = $MyInvocation.MyCommand.Definition
$REGISTRY_PATH = "HKLM:\Software\OSS\NMS_SPF\"

$DEFAULT_FILE_PATH = "D:\var\nokia\oss\nms\global\ad\"
$PATH = $null


Trap [Exception] {
    log "ERROR" $_.Exception
    EXIT 1
}

function paraArgs{

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
    
    $selfFQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain.Trim()
    $list =  (netdom query fsmo)[2].split(" ")
    $value = $list[$list.count-1]
       
    log "DEBUG" "checking primary node for key pdc: $value"
    if ($value -eq $selfFQDN){ 
        return $true
    }
   
    return $false
}

function ConvertTo-UnixTimestamp {
	$epoch = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0	
 	$input | % {		
		$milliSeconds = [math]::truncate($_.ToUniversalTime().Subtract($epoch).TotalMilliSeconds)
		Write-Output $milliSeconds
	}	
}

function backUp{  
    $tmpName = "nmsad-tmp.ldf"
    $baseDn = (get-adobject -filter {(name -eq "Users") -and (Objectclass -eq "container")}).DistinguishedName.Trim()
    
    if (($baseDn -eq $null) -or ($baseDn.Trim() -eq "") ){
        throw "no User info in active direcotory"
    }  
    
    ldifde -d $baseDn -f $PATH$tmpName
    
    $timeString = Get-Date | ConvertTo-UnixTimestamp
    $finalFileName = "nmsad-$timeString.ldf"
    log "INFO" "Formating $PATH$tmpName into $finalFileName"
    get-content $PATH$tmpName | where-object { $_ -notmatch 'changetype:' } | set-content $PATH$finalFileName
    
    del $PATH$tmpName -force
    log "INFO" "Backup done..."
}


function main{
   
   paraArgs
   
   log "INFO" "Run '$SELF_SCRIPT -filePath $script:PATH' started."
   
   $isPramarynode = checkIfPrimaryNode
   if (-not $isPramarynode){
      throw "$SELF_SCRIPT must be executed on primary node"
   }
   
   backUp
   
   log "INFO" "Run '$SELF_SCRIPT -filePath $script:PATH' successfully."  
}  

main
