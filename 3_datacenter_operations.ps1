#DATACENTER OPERATIONS:

#Import-Module -Name Vmware.PowerCLI

#Connecting to vCenter
Connect-VIServer -Server 192.168.17.155 -User administrator@vsphere.local -password Password@123

#List of Commands: [Datacenter]
#Get-Command -Noun datacenter ---> Displays operations that can be performed on the Datacenter (Get, Move, New, Remove, Set)
#Get-Command -Noun folder     ---> Displays operations that can be performed on the Folder     (Get, Move, New, Remove, Set)
#Get-Datacenter               ---> Displays list of Datacenters
#Get-Folder                   ---> Displays list of Folders


#CREATE DATACENTER:
# New-Datacenter -Name Datacenter_1 -Location datacenters [NOTE: The folder name is datacenters by default]
#     - LOCATION: Folder Name
#     - NAME:     Datacenter Name
#[NOTE: Check for folder name first, then create the datacenter. Depending on the number of Datacenters created, we can observe that the Folder list increases]


#MOVE DATACENTER:
# Move-Datacenter -Datacenter datacenter_1 -Destination FD1
#     - DESTINATION: Folder Name


#REMOVE DATACENTER: [Can remove single or multiple Datacenters]
# Remove-Datancenter -Datacenter Datacenter_1, Datacenter_2
