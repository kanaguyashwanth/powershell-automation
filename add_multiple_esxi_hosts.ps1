#IMPORT_MODULES
#Import-Module -Name Vmware.PowerCLI

#Connecting to vCenter
Connect-VIServer -Server 192.168.17.155 -User administrator@vsphere.local -password Password@123

#VARIABLES
$ESXiHosts = "192.168.17.141", "192.168.17.142", "192.168.17.143"   #OR  $ESXiHosts=Get-VMHost | Select Name 
$ESXiLocation = "NestedESXi"

#Prompt
$Credentials = Get-Credential -UserName root -Message "Enter ESXi root password"

#Adding Multiple Hosts to vCenter
Foreach ($ESXiHosts in $ESXiHosts) {
Add-VMHost -Name $ESXiHosts -Location $ESXiLocation -User $credentials.UserName -Password $credentials.GetNetworkCredential().Password -RunAsync -force
Write-Host -ForegroundColor GREEN "Adding ESXi host $ESXiHosts to vCenter"
}
