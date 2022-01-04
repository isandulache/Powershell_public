function Add-RemoteIPtoFirewallRule {
    <#
    .SYNOPSIS
        This function adds an IP, range of IPs or IP in CIDR format to a Windows Firewall Rule
    .DESCRIPTION
        This function adds an IP, range of IPs or IP in CIDR format to a Windows Firewall Rule
    .PARAMETER FWRule
        Specify the name of the GPO
    .PARAMETER IPs
        Specify the IP you want to add, oe the IPs separated by comma ("192.168.1.150,192.168.1.151")
    .EXAMPLE
         Add-RemoteIPtoFirewallRule -FWRule "TEST_RemoteList" -IPs "10.1.1.1"
    .EXAMPLE
        Add-RemoteIPtoFirewallRule -FWRule "TEST_RemoteList" -IPs "192.168.1.150,192.168.1.151"
    .EXAMPLE
        Add-RemoteIPtoFirewallRule -FWRule "TEST_RemoteList" -IPs "192.168.1.150/255.255.255.240"
    .NOTES
        SANDULACHE Julien
        jsa@openhost.io
        

        VERSION HISTORY
        1.0 | 2022.01.03 | SANDULACHE Julien
            Initial version
            Adding some more Error Handling
            Fix some typo
    .link
        https://github.com/isandulache/Powershell   
    #>
    #requires -version 3

    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory = $True)]
        [String]$FWRule,
        [parameter(Mandatory = $True)]
        [String]$IPs 
    )

BEGIN {
    #region Output logging
    function WriteInfo($message) {
        Write-Host $message
    }

    function WriteInfoHighlighted($message) {
    Write-Host $message -ForegroundColor Cyan
    }

    function WriteSuccess($message) {
    Write-Host $message -ForegroundColor Green
    }

    function WriteError($message) {
    Write-Host $message -ForegroundColor Red
    }

    function WriteErrorAndExit($message) {
        Write-Host $message -ForegroundColor Red
        Write-Host "Press enter to continue ..."
        Stop-Transcript
        Read-Host | Out-Null
        Exit
    }
    #endregion

    # check if the PS is run as Administrator, if not restart as admin (equivalent "RunAs Administrator")
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    IF (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning -Message "[BEGIN] This PS Function must be executed as Administrator. Your PS session does not comply. Restarting PS Session in 5 seconds."
            Sleep 5
            Start-Process powershell.exe -Verb runAs  
    }

    #initialize counter
    $cnt=0
}#BEGIN
PROCESS {
        WriteInfoHighlighted "Current List of Remote IPs" 
        $ListIPs =(Get-NetFirewallRule -DisplayName $FWRule | Get-NetFirewallAddressFilter).RemoteAddress | Sort-Object
        WriteSuccess $ListIPs

        ForEach ($IP in $IPs.Split(",")) {
            If ( $ListIPs.contains($IP) ) {WriteInfoHighlighted "$IP already in the list"
            }else {
                $ListIPs += @($IP)
                Write-Host "$IP added to the list" -BackgroundColor DarkCyan -ForegroundColor Yellow
                $cnt+=$cnt+1
            }
            
        }

        #$ListIPs += @($IPs.Split(","))
        if ($cnt -gt 0) {
            Set-NetFirewallRule -DisplayName $FWRule -RemoteAddress ($ListIPs| Sort-Object)
            WriteInfoHighlighted "Updated List of Remote IPs"
            (Get-NetFirewallRule -DisplayName $FWRule | Get-NetFirewallAddressFilter).RemoteAddress
        } else {
            $ListIPs =(Get-NetFirewallRule -DisplayName $FWRule | Get-NetFirewallAddressFilter).RemoteAddress | Sort-Object
            WriteSuccess "No new IPs to add to the list."
            WriteInfo "Here is the current RemoteAddress list:"
            $ListIPs
            
        }
        
}#PROCESS
END {

}#END
    
}


