#CLUSTER OPERATIONS:

#Import-Module -Name Vmware.PowerCLI

#Connecting to vCenter
Connect-VIServer -Server 192.168.17.155 -User administrator@vsphere.local -password Password@123

#List of Commands: [Cluster]
#Get-Command -Noun cluster                 ---> Displays operations that can be performed on the Cluster (Get, Move, New, Remove, Set)
#Get-Cluster                               ---> Displays the clusters present in all the Datacenters
#Get-Datacenter Datacenter_1 | Get-Cluster ---> Displays the Clusters of the specified Datacenter

#CREATE NEW CLUSTER:
# New-Cluster -Name "Cluster_1" -Location Datancenter_1

#CLUSTER PRESENT IN A PARTICULAR DATACENTER:
# Get-Datacenter Datacenter_1 | Get-Cluster
