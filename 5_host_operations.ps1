#HOST OPERATIONS:

#Import-Module -Name Vmware.PowerCLI

#Connecting to vCenter
Connect-VIServer -Server 192.168.17.155 -User administrator@vsphere.local -password Password@123

#List of Commands:
# Get-VMHost                       ---> Displays all the Hosts/VMs connected to VC
# Get-VMHost -Name 192.168.17.141  ---> Displays a particular VM/Host connected to VC
# Get-VMHost -Name 192.168.17.141 | Set-VMHost -State Connected
#    STATE: Connected    - Exit maintenance mode / Connect to VC
#           Maintenance  - Enter maintenance mode
#           Disccnnected - Disconnect from VC


#ADDING HOST TO VC/DC:
# Add-VMHost -Server 192.168.17.155 -Name 192.168.17.142 -Location Datacenter_1 -User root -password Password@123


#REMOVE FROM VC/DC HOST:
# Get-VMHost -Name 192.168.17.141 -Location Datacenter_1 | Remove-VMHost -Confirm:$false
# Get-VMHost -Name 192.168.17.142 -Location Datacenter_1 | Remove-VMHost -Confirm:$false
# Get-VMHost -Name 192.168.17.143 -Location Datacenter_1 | Remove-VMHost -Confirm:$false

#EXIT / ENTER / CONNECT/DISCONNECT FROM VC:
# Get-VMHost -Name 192.168.17.142 | Set-VMHost -State Connected
#     STATE: CONNECTED      - Exit Maintenance Mode / Connect to VC
#            DISCONNECTED   - Disconnect Host from VC
#            MAINTENANCE    - To put the Host into Maintenance Mode
#            NOT RESPONDING - 


#RESTART HOST: [Has to be in Maintenance Mode]
# Restart-VMHost 192.168.17.141
