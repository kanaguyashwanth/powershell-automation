#IMPORT MODULE
#Import-Module -Name Vmware.PowerCLI

#TIMESTAMP
#filter timestamp {"$(Get-Date -Format G): $_"}
# Get-VM |timestamp

# INFRASTRUCTURE SETTINGS FOR SCRIPTS
$VCUserName = 'administrator@vsphere.local'
$ESXiUserName = 'root'
$Password = 'Password@123'
###$VCUserName = Read-Host "Enter vCenter Username"
###$ESXiUserName = Read-Host "Enter Host Username"
###$Password = Read-Host "Enter Password"


$VCNode = Get-VIServer 192.168.17.155 -User $VCUserName -password $Password

# $host01 = Get-VMHost 192.168.17.141
# $host02 = Get-VMHost 192.168.17.142
# $host03 = Get-VMHost 192.168.17.143

$DCName_1 = 'Datacenter_1'
$CLName_1 = "Cluster_1"
$CLName_2 = "Cluster_2"

# CONNECT TO VCENTER
Connect-VIServer -Server 192.168.17.155 -User $VCUserName -password $Password

# CREATE DATACENTER
$DC = New-Datacenter -Name $DCName_1 -Location (Get-Folder Datacenters)

# CREATE CLUSTER [2 Clusters - Cluster_1 & Cluster_2]
$CL_1 = New-Cluster -Name $CLName_1 -Location ($DC)
$CL_2 = New-Cluster -Name $CLName_2 -Location ($DC)


# ADD / REMOVE ESXi HOSTS TO CLUSTER [Cluster_1: Host01, Host02 & Cluster_2: Host_03]
Add-VMHost -Server $VCNode -Name 192.168.17.141 -Location $CL_1 -User $ESXiUserName -password $Password
Add-VMHost -Server $VCNode -Name 192.168.17.142 -Location $CL_2 -User $ESXiUserName -password $Password -Force # To ignore SSL Certificate error
###Add-VMHost -Server $VCNode -Name 192.168.17.143 -Location $CL_2 -User $ESXiUserName -password $Password


# POWER ON/OFF VMs (not vCLS):
# Start-VM -VM VM_1, VM_2 -Confirm:$false # Host01
# Start-VM -VM vm-1, vm-2 -Confirm:$false # Host02
# Start-VM -VM MV-1, MV-2 -Confirm:$false # Host03
#----------------------------- TO POWER UP/DOWN SELECTIVE VMS --------------------------------------------------
$allvms = Get-VM
$selectivevms = $allvms | Where-Object {$_.Name -notlike '*vCLS*'}
$selectivevms
# ### Start-VM $selectivevms -Confirm:$false #Powering on only the VMs which contain VM or MV, excludes vCLS VMs
# ### Stop-VM $selectivevms -Confirm:$false
#----------------------------- TO POWER UP/DOWN SELECTIVE VMS --------------------------------------------------



# !!!!!!!!!!!!!  NOTE: VCLS VMs MEMORY CONSUMPTION CAN INCREASE WITH TIME !!!!!!!!!!!!!!!!!
#----------------------------- POWER OFF ALL vCLS ---------------------------------------------------------------
# $allvms = Get-VM
# $allvcls = $allvms | Where-Object {$_.Name -like '*vCLS*'}
# Shutdown-VMGuest | Where-Object {$_.Name -like '*vCLS*'}
#----------------------------- POWER OFF ALL vCLS ---------------------------------------------------------------
# !!!!!!!!!!!!!  NOTE: VCLS VMs MEMORY CONSUMPTION CAN INCREASE WITH TIME !!!!!!!!!!!!!!!!!




#----------------------------- POWER ON ONLY VM-1s --------------------------------------------------------------
$allvms = Get-VM
$selectivevms = $allvms | Where-Object {$_.Name -notlike '*vCLS*'}
$allvm_ending_with_1 = $selectivevms | Where-Object { ($_.Name -like '*-1*') -OR (($_.Name -like '*_1*')) }
Start-VM $allvm_ending_with_1 -Confirm:$false
#----------------------------- POWER ON ONLY VM-1s --------------------------------------------------------------

#----------------------------- POWER ON ONLY VM-2s --------------------------------------------------------------
$allvms = Get-VM
$selectivevms = $allvms | Where-Object {$_.Name -notlike '*vCLS*'}
$allvm_ending_with_2 = $selectivevms | Where-Object { ($_.Name -like '*-2*') -OR (($_.Name -like '*_2*')) }
####Start-VM $allvm_ending_with_2 -Confirm:$false
#----------------------------- POWER ON ONLY VM-2s ---------------------------------------------------------------



#------------------------------------ CONVERSION OF VM TO TEMPLATE -----------------------------------------------
# CONVERTING VM TO TEMPLATE
# Get-VM -Name VM_1 | Set-VM -ToTemplate -Confirm:$false

# CONVERTING TEMPLATE TO VM
# Set-Template -Template VM_1 -ToVM
#------------------------------------ CONVERSION OF VM TO TEMPLATE ------------------------------------------------


#------------------------------------ CLONING VM TO TEMPLATE ------------------------------------------------------
# CREATING A TEMPLATE FROM A VM AND STORE IN DATASTORE
New-Template -VM 'VM_1' -Name "TinyCore_Template_1" -Datastore 'Datastore_1' -Location $DC
# New-Template -VM 'VM_2' -Name "FossaPup_Template_1" -Datastore 'Datastore_1' -Location $DC
#------------------------------------ CLONING VM TO TEMPLATE ------------------------------------------------------





# DEPLOY VM FROM TEMPLATE
Get-OSCustomizationSpec TinyCore_Linux-GOCS
Get-OSCustomizationSpec TinyCore_Linux-GOCS | Set-OSCustomizationSpec -NamingPrefix "TinyCore-Linux" -NamingScheme fixed
Get-OSCustomizationNicMapping -OSCustomizationSpec TinyCore_Linux-GOCS | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress 192.168.17.160 -SubnetMask 255.255.255.0 -DefaultGateway 192.168.17.2
(Get-OSCustomizationSpec TinyCore_Linux-GOCS).NamingPrefix; (Get-OSCustomizationNicMapping -OSCustomizationSpec TinyCore_Linux-GOCS).IPAddress
    # Procedure:
        # Select the Host at which you want to deploy the VM
        # Enter the name of the VM which you are going to deploy
        # Specify the datastore where you want to deploy the VM
        # Specify the VM Template to be used
        # Specify the Guest OS Customization Spec (GOCS)
        # Create a new VM based on the set Template and GOCS
        # Power up the VM

# DEPLOY FROM TEMPLATE AND GOCS
# SELECT DESTINATION:
    # HOST01 DETAILS - Cluster_1, Datastore_1, 192.168.17.141
    # HOST02 DETAILS - Cluster_2, Datastore_2, 192.168.17.142

# SET RESOURCE POOL
$ResourcePool = Get-Cluster -Name 'Cluster_1'

# SET VM NAME
$VMName = "TinyCore Linux Server"

# SPECIFY DATASTORE WHERE VM NEEDS TO DEPLOYED
 $DS = Get-Datastore -Name "Datastore_1"

# SPECIFY THE TEMPLATE FOLDER
 $Location = Get-Folder "TinyCore Linux Template Example"

# SELECTING HOST
 $VMHost = Get-VMHost -Name 192.168.17.141

# SELECTING VM TEMPLATE FILE
 $TinyCoreTemp = Get-Template -Name TinyCore_Template_1

# SELECTING GOSC
 $TinyCoreSpec = Get-OSCustomizationSpec -name TinyCore_Linux-GOCS

# CREATE NEW VM USING TEMPLATE AND GOSC
 New-VM -Name $VMName -Template $TinyCoreTemp -OSCustomizationSpec $TinyCoreSpec -Location $Location -VMHost $VMHost -Datastore $DS

# POWER ON/OFF VM
 Start-VM -VM $VMName
 #Stop-VM -VM $VMName



 # MOVING CREATED VM FROM TEMPLATE TO ANOTHER HOST
 Stop-VM -VM $VMName
