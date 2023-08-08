[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;



Connect-VIServer 10.55.232.32 -User 'administrator@vsphere.local' -password 'Password@123' -Force



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



# ENABLING VSAN SERVICE ON CLUSTER
Write-Host "Enabling vSAN Cluster Services..." -ForegroundColor Green
Set-Cluster -Cluster $Cluster -VsanEnabled $true -Confirm:$false


# ADD/REMOVE HOSTS ON THE CLUSTER
$InputfromUser = Read-Host -Prompt "Do you want to add or remove hosts? (Add/Remove)"
if ($InputfromUser -match "Add")
{

    foreach ($esx in $ESXHosts)
    {
        Write-Host "Adding host $esx to $($NewCluster)" -ForegroundColor Green
   
        # Add hosts to cluster
        Add-VMHost -Name $esx -Location $Cluster -User $ESXUser -Password $ESXPWD -Force -RunAsync -Confirm:$false
   
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
# Sleep-Progress 15
# Start-Sleep -Seconds 15



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



# CREATING vSWITCH AND ENABLING vSAN KERNEL
foreach ($esx in $ESXHosts)
{
    Write-Host "Creating vSWitch on $esx..." -ForegroundColor Green
    $vswitch = New-VirtualSwitch -VMHost $esx -Nic vmnic1, vmnic2 -Name "vSAN" -Mtu 9000
    $adapter = New-VMHostNetworkAdapter -VMHost $esx -VirtualSwitch $vswitch -PortGroup "vSAN" -VsanTrafficEnabled $true -Mtu 9000
}


    
# WAIT FOR VMK ADAPTERS TO GET DHCP ASSIGNED IPs
# Sleep-Progress 105
# Start-Sleep -Seconds 105  
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
            if($vsandisk.IsSsd -eq $true -and $vsandisk.CapacityGB -lt "35")
            {
                $CacheDisks += $vsandisk
            }
            else
            {
                    $CapacityDisks += $vsandisk
            }
        }
    }
}

       
        
foreach($esx in $ESXHosts)
{
    # MAXIMUM DISK CAPACITY PER DISK GROUP
    # MAX CAP DISK = 1
    if($CacheDisks.Count -eq 1)
    {
        $MaxCapDisks = 7
    }
    elseif ($CacheDisks.Count -gt 1 -and $CacheDisks.Count -lt 6)
    {
        $MaxCapDisks = [math]::floor($CapacityDisks.Count/$CacheDisks.Count)
    }

    # MAX CAP DISK = 2
    $temp = [pscustomobject]@{value = $CapacityDisks.Count}
    $DiskGroups = $CapacityDisks | Group-Object -Property {[math]::Ceiling($temp.value--/$MaxCapDisks)}
    $esx
    $DiskGroups | Format-Table


    # ADDING DISK GROUPS
    $a = 0
    foreach($disks in $CacheDisks)
    {
        Write-Host "Added Disk Group"$a
        New-VsanDiskGroup -VMHost $esx -SsdCanonicalName $disks -DataDiskCanonicalName $DiskGroups[$a].Group
        $a += 1
    }
}



# CREATING FAULT DOMAINS
if($ESXHosts.Count -lt 5)
{
    $n = 1
    foreach($esx in $ESXHosts)
    {
        New-VsanFaultDomain -VMHost $esx -Name "$FD$n"
        $n++
    }
}


