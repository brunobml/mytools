# Function Get-ServerInfo
<# 
.SYNOPSIS
    This Funcion generates a windows server report or multiple servers.
.DESCRIPTION
    
     
.NOTES
     Author    : Bruno Leite - bruno.bezerra@gmail.com

.LINK

.EXAMPLE
Without Passing credentials (Assuming you have an elevated account)

PS C:\> Get-ServerInfo -DeviceName azudb00002

OR
Passing credentials

PS C:\> Get-ServerInfo -DeviceName azudb00002 -Credential (Get-Credential)
  
ComputerName      : azuut00001
OS Installed Date : 2017-11-07 1:40:21 PM
OSName            : Microsoft Windows Server 2016 Datacenter
OSVersion         : 10.0.14393
OSBuild           : 14393
SPack_Version     : 0
OSArchiteture     : 64-bit
Model             : Virtual Machine
Manufacturer      : Microsoft Corporation
RAM               : 8 GB
Processor Model   : Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz
Sockets           : 1
Cores             : 2
SystemType        : x64-based PC
SystemFolder      : C:\Windows
InstallPartition  : \Device\Harddisk0\Partition1
PageFile          : D:\pagefile.sys
CDROM ID          :
C:Drive_TotalSize : 127.00 GB
C:Drive_FreeSpace : 98.60 GB
C:Drive_%Free     : 77.64%
D:Drive_TotalSize : 16.00 GB
D:Drive_FreeSpace : 13.90 GB
D:Drive_%Free     : 86.89%
E:Drive_TotalSize : 1022.87 GB
E:Drive_FreeSpace : 1022.67 GB
E:Drive_%Free     : 99.98%
F:Drive_TotalSize : 99.87 GB
F:Drive_FreeSpace : 99.70 GB
F:Drive_%Free     : 99.82%
PSComputerName    : azuut00001
RunspaceId        : c4ae9bbe-b0b3-47ad-9349-e2d0c94b2590

 
#>

Function Get-ServerInfo { 
	[CmdletBinding()]
	    Param
	    (
			[Parameter(Position=1,ValueFromPipelineByPropertyName=$true,Mandatory=$true,ValueFromPipeline=$true)]
	   		[Alias('ServerName','Server','Name','Computer','ComputerName')]
	   		[Object[]]$DeviceName,

            [ValidateNotNull()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential = [System.Management.Automation.PSCredential]::Empty   
            
		)		
	
	BEGIN {

       $ScriptBlock = {
                          
             $os = Get-WmiObject -Class Win32_OperatingSystem | Select-Object PSComputerName,Name,Version, BuildNumber, ServicePackMajorVersion, OSArchitecture, @{Name="Installed";Expression={$_.ConvertToDateTime($_.InstallDate)}}
             Write-Progress -Activity "Collecting Server Summary of $($os.PSComputerName)"
             $cs = Get-WmiObject -Class Win32_ComputerSystem | Select-Object Model, Manufacturer, TotalPhysicalMemory, NumberOfProcessors, NumberOfLogicalProcessors, SystemType	
             $pf = Get-Wmiobject -Class Win32_PageFileSetting | Select-Object Name, MaximumSize	
             $pc = Get-WmiObject -Class win32_processor | Select-Object Name	
             $cd = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -like '5'} | Select-Object DeviceID, DriveType

             $props = [ordered]@{
		            'ComputerName' = $os.PSComputerName;
		            'OSInstalledDate' = $os.Installed;
		            'OSName' = ($os.Name.split('|')[0]);
		            'OSVersion' = $os.version;
		            'OSBuild' = $os.buildnumber;
		            'OSServicePackVersion' = $os.servicepackmajorversion;
		            'OSArchiteture' = $os.OSArchitecture;
		            'Model' = $cs.model;
		            'Manufacturer' = $cs.manufacturer;
		            'RAM' = '{0} GB' -f $($cs.totalphysicalmemory / 1GB -as [int]);
		            'Processor Model' = $pc.Name;
		            'Sockets' = $cs.numberofprocessors;
		            'Cores' = $cs.numberoflogicalprocessors;
		            'SystemType' = $cs.SystemType;
                    'SystemFolder'= ($os.Name.split('|')[1]);
                    'InstallPartition'= ($os.Name.split('|')[2]);
		            'PageFile' = $pf.Name;
		            'CDROM_ID' = $cd.DeviceID;
	            }

             $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -like '3'} | Select-Object DeviceID, Size, FreeSpace

             foreach ($disk in $disks){
	                if ($disk.Size -gt 0){
			  
                       $props["$($disk.DeviceID)Drive_TotalSize"] = '{0:0.00} GB' -f [math]::Round($disk.Size / 1GB, 2)
		               $props["$($disk.DeviceID)Drive_FreeSpace"] = '{0:0.00} GB' -f [math]::Round($disk.FreeSpace / 1GB, 2)
		               $props["$($disk.DeviceID)Drive_%Free"] = '{0:0.00}%' -f [math]::Round(($disk.FreeSpace/$disk.Size)*100, 2)
		            }
             }

             New-Object -TypeName PSObject -Property $props

       }
    
	
	}
	
	PROCESS {		
        
        if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
           
           $session = New-PSSession -ComputerName $DeviceName -ErrorAction SilentlyContinue -Credential $Credential                     
           Invoke-Command -Session $session -ScriptBlock $ScriptBlock 

        } 
        else {
           $session = New-PSSession -ComputerName $DeviceName -ErrorAction SilentlyContinue           
           Invoke-Command -Session $session -ScriptBlock $ScriptBlock
        }

	#		$assetAllInFo = New-Object -TypeName PSObject -Property $props
	#		return $assetAllInFo
		
	}
	
	END {
	
		Get-PSSession | Remove-PSSession
	}	
	
}