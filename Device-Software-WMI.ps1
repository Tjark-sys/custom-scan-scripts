﻿#default header ----------------------------------------------------------------------
param (
    [string]$parameter = ""
)

. (Join-Path -Path $PSScriptRoot -ChildPath "include\common.ps1")

$scope = Init -encodedParams $parameter
#end of default header ----------------------------------------------------------------------

$filePath = "$($scope.DataDir)\wmisoft$($scope.TimeStamp).inv"

function Get-SoftwareInfo {
    param (
        [string]$computerName,
        [System.Management.Automation.PSCredential]$credential
    )

    if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
        try {
            Notify -name "WMI" -itemName "Getting Software" -message "Device: $computerName" -category "Info"  -state "None"    

            if ($credential) {
                $software = Get-WmiObject -Class Win32_Product -ComputerName $computerName -Credential $credential
            }
            else {
                $software = Get-WmiObject -Class Win32_Product -ComputerName $computerName
            }            
            $i = 0
            foreach ($item in $software) {                
                $i++                
                AddPropertyValue -name "SoftwarePackage.Name" -value $($item.Name)
                AddPropertyValue -name "SoftwarePackage.Version" -value $($item.Version)
                #Notify -name "Package $($item.Name)" -itemName "- $($item.Name)" -message "- $($item.Name)" -category "Info"  -state "None"    
            }

            Notify -name "WMI" -itemName "Getting Software done ..." -message "Device: $computerName" -category "Info"  -state "Finished"    
            Notify -name $computerName -itemName "Packages found:" -message $i -category "Info" -state "None"
            return $d
        }
        catch {
            Notify -name "Exception $computerName" -itemName "Error" -message $_ -category "Error"  -state "Faulty"
        }
    }
    else {
        Notify -name "WMI" -itemName "Host unreachable!" -message "Device: $computerName" -category "Info"  -state "Finished"    
    }
}

$computers = @($env:COMPUTERNAME, "device2") #some source for computer names, eg AD or a file

foreach ($computerName in $computers) {        
    try {
        Write-Host "Getting Software for $computerName"
        NewEntity -name "Device"
        AddPropertyValue -name "Name" -value "$computerName $date"
        Get-SoftwareInfo -computerName $computerName  
    }
    catch {
        Notify -name "Error $computerName" -itemName $computerName -message "$_ - $($_.InvocationInfo.ScriptLineNumber)" -category "Error"  -state "Faulty"
    }     
}

Notify -name "WMI" -itemName "Writing Data $($elements.Count) Elements" -message $filePath -category "Info" -state "None"
WriteInv -filePath $filePath -version $scope.Version
Notify -name "WMI-" -itemName "Writing Data Done" -message $filePath -category "Info" -state "Finished"