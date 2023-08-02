#IMPORT_MODULES
#Import-Module -Name Vmware.PowerCLI

#Connecting to vCenter
Connect-VIServer -Server 192.168.17.155 -User administrator@vsphere.local -password Password@123

#VARIABLES
$ESXiHosts = Get-VMHost         #OR  $ESXiHosts=Get-VMHost | Select Name
$ESXiLocation = "NestedESXi"

#Removing Multiple Hosts from a Location
Get-VMHost -Location $ESXiLocation | Remove-VMHost
