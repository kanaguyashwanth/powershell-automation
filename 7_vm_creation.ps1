# VM CREATION

# VM SPEC:
$VMname = Read-Host "Enter VM Name"
$IP  = "192.168.17.145"
$SNM = "255.255.255.0"
$GW  = "192.168.17.2"
$DNS1= "192.168.17.2"
$CPU = "2"
$MemoryMB = "200"

# GET CREDENTIALS
$GC   = Get-Credential -Message "Please specify the credential to Access Guest Windows VM" -User Administrator
$VCC  = Get-Credential -Message "Please specify the credential to Access vCenter" -User administrator@vsphere.local

# CONNECT TO VCENTER
Get-VIServer 192.168.17.155 -Credential $VCC

# CREATING VM
New-VM -Name $VMname -Template Win2016 -OSCustomizationSpec Windows -Datastore 'Cluster_1' -DiskStorageFormat Thin -ResourcePool ($DC)
Set-VM -VM $VMname -NumCpu $CPU -MemoryMB $MemoryMB -Confirm:$false | Out-Null
Start-VM -VM $VMname


#Only show time in your script
function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)    
}

#We are waiting here to complete Customization on VM
while($true){
    Start-Sleep -Seconds 60
    write-output "$(Get-TimeStamp) Waiting for Customization to be completed"
    $CustomizeSuccess = Get-VIEvent -Entity $VMname | Where-Object {$_.FullFormattedMessage -Match "Customization of VM $VMname succeeded"}
    $CustomizeFail= Get-VIEvent -Entity $VMname | Where-Object {$_.FullFormattedMessage -match "Customization of VM $VMname Failed"}

    If ($CustomizeSuccess){
         Write-host "OS Customization has completed on $VMname"
         #Here we are setting IP address on the VM by using guest credential
            $IPADD = "c:\windows\system32\netsh.exe interface ip set address ""Ethernet0"" static $IP $SNM $GW 1"
            $DNSE1 = "c:\windows\system32\netsh.exe interface ipv4 add dnsserver ""Ethernet0"" address=$DNS1 index=1" 
            $DNSE2 = "c:\windows\system32\netsh.exe interface ipv4 add dnsserver ""Ethernet0"" address=$DNS2 index=2"
         Write-Host "Setting IP address for $VMname..."
         $IPConf = Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $IPADD
         If ($IPConf) {Write-host "IP address configured in System"} else {Write-host "IP Address assignmenet failed."
         Pause
         Exit}
         $DNS1Conf = Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $DNSE1
         If ($DNS1Conf) {Write-host "Primary DNS Assigned"} else {Write-host "Primary DNS assignment failed."
         Pause
         Exit}
         $DNS2Conf = Invoke-VMScript -VM $VMname -GuestCredential $GC -ScriptType bat -ScriptText $DNSE2
         If ($DNS2Conf) {Write-host "Secondary DNS configured in System"} else {Write-host "Secondary DNS assignment failed."
         Pause
         Exit}
         Write-Host "System Build is done, Please verify the VM."
         break
        }
    If ($CustomizeFail){

         Write-host  "OS Customization failed on $VMname , Press any Key to Exit the Script"
         Pause
         Exit
         }
   }
