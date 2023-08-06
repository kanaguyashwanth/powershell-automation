[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

Connect-VIServer 10.55.232.5 -User 'administrator@vsphere.local' -password 'Password@123' -Force

$Datacenter = "Datacenter-1"
$Cluster = "Cluster-1"
$ESXHosts = "10.55.232.76", "10.55.232.80", "10.55.232.84"
$ESXUser = "root"
$ESXPWD = "Password@123"
$VMKNetforVSAN = "Management Network"





# CREATING NEW DATACENTER
If (-Not ($NewDatacenter = Get-Datacenter $Datacenter -ErrorAction SilentlyContinue))
{
    Write-Host "Creating $Datacenter ..." -ForegroundColor Green
    $NewDatacenter = New-Datacenter -Name $Datacenter -Location (Get-Folder Datacenters)
    Get-Datacenter -Name $Datacenter
}



# CREATING NEW CLUSTER
if (-Not ($NewCluster = Get-Cluster $Cluster -ErrorAction SilentlyContinue)) 
{ 
   Write-Host "Creating $Cluster ..." -ForegroundColor Green
   $NewCluster = New-Cluster -Name $Cluster -Location $NewDatacenter
   Get-Cluster -Name $Cluster
}


# ADD/REMOVE HOSTS ON THE CLUSTER
$InputfromUser = Read-Host -Prompt "Do you want to add or remove hosts? (Add/Remove)"
if ($InputfromUser -match "Add")
{

    foreach ($esx in $ESXHosts)
    {
        Write-Host "Adding host $esx to $($NewCluster)" -ForegroundColor Green
   
        # Add hosts to cluster
        Add-VMHost -Name $esx -Location (Get-Datacenter $Datacenter) -User $ESXUser -Password $ESXPWD -Force -RunAsync -Confirm:$false
   
    }
}
ElseIf ($InputfromUser -match "Remove")
{
    foreach ($esx in $ESXHosts)
    {
        Write-Host "Removing host $esx from $($NewCluster)" -ForegroundColor Green
        
        # Remove hosts from cluster
        Remove-VMHost $esx -Confirm:$false
    }
}
Sleep-Progress 15
Start-Sleep -Seconds 15




# NUMBER OF HOSTS CONNECTED
$nConn = 0
foreach ($esx in $ESXHosts)
{
    $ConnState = Get-VMHost | Select-Object ConnectionState
    if ($ConnState -Match "Connected")
    {
    $nConn = $nConn + 1
    }
    elseIf(-not($InputfromUser -match "Remove"))
    {
    Sleep-Progress 15
    Start-Sleep -Seconds 15
    }
}




if($nConn -eq 3)
{
    # ENABLING VSAN SERVICE ON CLUSTER
    Write-Host "Enabling vSAN Cluster Services..." -ForegroundColor Green
    Set-Cluster -Cluster $Cluster -VsanEnabled $true -Confirm:$false


    # CREATING vSWITCH AND ENABLING vSAN KERNEL
    foreach ($esx in $ESXHosts)
    {
        Write-Host "Creating vSWitch on $esx..." -ForegroundColor Green
        $vswitch = New-VirtualSwitch -VMHost $esx -Nic vmnic1, vmnic2 -Name "vSAN" -Mtu 9000
        $adapter = New-VMHostNetworkAdapter -VMHost $esx -VirtualSwitch $vswitch -PortGroup "vSAN" -VsanTrafficEnabled $true -Mtu 9000
    }
    
    
    # WAIT FOR VMK ADAPTERS TO GET DHCP ASSIGNED IPs
    Sleep-Progress 105
    Start-Sleep -Seconds 105
    
    foreach ($esx in $ESXHosts)
    {
        Write-Host "VMKernel Adapters on $esx..." -ForegroundColor Green
        Get-VMHost -Name $esx | Get-VMHostNetwork | Select-Object  -ExpandProperty VirtualNic | Sort-Object Name
    }


    # CREATING DISK GROUPS
    foreach ($esx in $ESXHosts)
    {
        $VSANDisks = Get-VMHost -Name $esx | Get-ScsiLun | Where-Object {$_.VsanStatus -eq "Eligible"}

        #CACHE AND CAPACITY DISKS
        if ($VSANDisks.Count -gt 1)
        {
            $CacheDisks = @()
            $CapacityDisks = @()
            foreach($vsandisk in $VSANDisks)
            {
                if($vsandisk.IsSsd -eq $true -and $vsandisk.CapacityGB -lt "21")
                {
                    $CacheDisks += $vsandisk
                }
                else
                {
                    $CapacityDisks += $vsandisk
                }
            }
        }

foreach ($esx in $ESXHosts)
{

}

    }


}




















# CREATING DISK GROUPS




























#ADDING HOSTS TO THE CLUSTER
$ESXHosts | Foreach {
   Write-Host "Adding $($_) to $($NewCluster)"
   
   # Add them to the cluster
   $AddedHost = Add-VMHost -Name $_ -Location $NewCluster -User $ESXUser -Password $ESXPWD -Force
   
   # Check to see if they have a VSAN enabled VMKernel
#   $VMKernel = $AddedHost | Get-VMHostNetworkAdapter -VMKernel | Where {$_.PortGroupName -eq $VMKNetforVSAN }
#   $IsVSANEnabled = $VMKernel | Where { $_.VsanTrafficEnabled}
   
   # If it isnt Enabled then Enable it
#   If (-not $IsVSANEnabled) {
#      Write-Host "Enabling VSAN Kernel on $VMKernel"
#      $VMKernel | Set-VMHostNetworkAdapter -VsanTrafficEnabled $true -Confirm:$false | Out-Null
#   } Else {
#      Write-Host "VSAN Kernel already enabled on $VmKernel"
#      $IsVSANEnabled | Select VMhost, DeviceName, IP, PortGroupName, VSANTrafficEnabled
#   }
}
