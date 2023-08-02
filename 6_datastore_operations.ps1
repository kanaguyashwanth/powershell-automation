#DATASTORE OPERATIONS:


#Things to know before creating VMFS Datastore:
# - HBA Adapter model on ESXi (check which is available) - USE COMMAND: Get-VMHostHba
# - Datastore  - COMMAND: Get-Datastore
# - ScsiLUN    - COMMAND: Get-ScsiLun

# FINAL COMMAND:
# New-Datastore -VMHost $esxiHost.Name -Name '5gb_local_datastore' -Path $addedNewLun.CanonicalName -Vmfs -FileSystemVersion 6

# 1. CREATING VMFS DATASTORE:
# NOTE: [Get these Details First!]
# $esxiHost = Get-VMHost 192.168.17.141
# $hostHBA = $esxiHost | Get-VMHostHba | Where-Object {$_.Model -eq $hbaModel}
# $lunList = $hostHBA | Get-ScsiLun
# $addedNewLun = $lunList | Where-Object {$_.CanonicalName -eq 'mpx.vmhba0:C0:T2:L0'}
# FINAL: New-Datastore -VMHost $esxiHost.Name -Name '5gb_local_datastore' -Path $addedNewLun.CanonicalName -Vmfs -FileSystemVersion 6


# 2. REMOVING DATASTORE:
# Remove-Datastore -Datastore 5gb_local_datastore -VMHost 192.168.17.142 -Confirm:$false







#CREATING VMFS DATASTORE:

# 1_Import Module
#Import-Module -Name Vmware.PowerCLI

# 2_Connecting to vCenter   [vCenter Details]
Connect-VIServer -Server 192.168.17.155 -User administrator@vsphere.local -password Password@123

# 3_Define Environement     [ESXI Details]
$esxiHost = Get-VMHost 192.168.17.142
$hbaModel = "PVSCSI SCSI Controller" #Check which model by command: Get-VMHostHba

# 4_ESXi Server Information [Displaying ESXI Details]
$esxiHost

# 5_Getting HBA Storage Adapter Information [HBA Details]
$hostHBA = $esxiHost | Get-VMHostHba | Where-Object {$_.Model -eq $hbaModel}
$hostHBA

# 6_Getting List of Datastores
$datastore = Get-Datastore
$datastore

# 7_Getting Available LUN Storage Devices list
$lunList = $hostHBA | Get-ScsiLun
$lunList | Format-Table -AutoSize

# 8_Getting List of LUN on Datastores
foreach ($lun in $lunList)
{
    $lun | Select-Object CanonicalName, RuntimeName, CapacityGB, @{Label='DatastoreName'; Expression={$datastore | Where-Object {$_.Extensiondata.Info.Vmfs.Extent.DiskName.Contains($lun.CanonicalName)} | Select-Object -ExpandProperty Name}}
}

# 9_Rescan/Refresh ESXI Storage
$esxiHost | Get-VMHostStorage -Refresh -RescanAllHba

# 10_Getting newly dsicovered LUN Storage
$lunList = $hostHBA | Get-ScsiLun
$lunList | Format-Table -Autosize

foreach ($lun in $lunList)
{
    $lun | Select-Object CanonicalName, RuntimeName, CapacityGB, @{Label='DatastoreName'; Expression={$datastore | Where-Object {$_.Extensiondata.Info.Vmfs.Extent.DiskName.Contains($lun.CanonicalName)} | Select-Object -ExpandProperty Name}}
}

#NOTE: Here it is showing suffix mpx as an identifier because we are using Local Disk. 
#      If there were shared SCSi/FCoE disk/LUNs, it would have shown NAA as suffix with followed by GUID from storage server.

# 11_Getting RuntimeName of LUN (LOCAL/REMOTE_SHARED_STORAGE)
$addedNewLun = $lunList | Where-Object {$_.CanonicalName -eq 'mpx.vmhba0:C0:T2:L0'}
$addedNewLun | Format-Table -AutoSize

# 12_Adding new Datastore using RuntimeName of newly Added Lun
$datastoreName = '5gb_local_datastore'
New-Datastore -VMHost $esxi.Name -Name '5gb_local_datastore' -Path $addedNewLun.CanonicalName -Vmfs -FileSystemVersion 6

# 13_Rechecking Datastore List
$datastore = Get-Datastore
$datastore

# 14_Rechecking LUN and Datastore mapping
$lunList = $hostHBA | Get-ScsiLun
foreach ($lun in $lunList)
{
    $lun | Select-Object CanonicalName, RuntimeName, CapacityGB, @{Label='DatastoreName'; Expression={$datastore | Where-Object {$_.Extensiondata.Info.Vmfs.Extent.DiskName.Contains($lun.CanonicalName)} | Select-Object -ExpandProperty Name}}
}




# FINAL COMMAND:
# New-Datastore -VMHost $esxiHost.Name -Name '5gb_local_datastore' -Path $addedNewLun.CanonicalName -Vmfs -FileSystemVersion 6




# New-Datastore -VMHost $esxiHost.Name -Name '5gb_local_datastore' -Path $addedNewLun.CanonicalName -Vmfs -FileSystemVersion 6

#NOTE: [Get these Details First!]
# $esxiHost = Get-VMHost 192.168.17.141
# $hostHBA = $esxiHost | Get-VMHostHba | Where-Object {$_.Model -eq $hbaModel}
# $lunList = $hostHBA | Get-ScsiLun
# $addedNewLun = $lunList | Where-Object {$_.CanonicalName -eq 'mpx.vmhba0:C0:T2:L0'}
# FINAL: New-Datastore -VMHost $esxiHost.Name -Name '5gb_local_datastore' -Path $addedNewLun.CanonicalName -Vmfs -FileSystemVersion 6
