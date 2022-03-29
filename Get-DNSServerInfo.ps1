function Get-DNSServerInfo {
<#

.SYNOPSIS
Get-DNSServerInfo gets the IP configuration of all domain joined Windows servers.
 
 .DESCRIPTION
 Uses Test-Connection to check if the server is powered on and reachable.
 
 .EXAMPLE
 Get-DNSServerInfo | Format-Table -AutoSize
 
 .NOTES
Author: SANDULACHE Julien
        jsa@openhost.io
        

	VERSION HISTORY
	1.0 | 2022.01.04 | SANDULACHE Julien
		Initial version
		Adding some more Error Handling
		Fix some typo
    .link
        https://github.com/isandulache/Powershell 
#>
    [CmdletBinding()]
        PARAM (
        [parameter(Mandatory = $False)]
        [String]$NameFilter=$null
    )
 
$ADFilter=$null
Write-Verbose $NameFilter
if (!([string]::IsNullOrEmpty($NameFilter))) { 
    [string]$ADFilter = "name -like ""*$($NameFilter)*"" -and operatingsystem -like ""*server*"" -and enabled -eq ""true"""
    Write-Verbose "the filter is : $ADFilter"
} else {  
    [string]$ADFilter= "operatingsystem -like ""*server*"" -and enabled -eq ""true"""
    Write-Verbose "the filter is : $ADFilter"
}#else

try {  
    $getc=(Get-ADComputer -Filter $ADFilter).Name 
    } catch { write-error "Error while getting AD computer accounts"
                if($_.ErrorDetails.Message) {
                    Write-Verbose "ErrorDetails.Message exists."
                    Write-Verbose "ErrorDetails.Message: $($_.ErrorDetails.Message) "
                    Write-Verbose "Exception.Message: $($_.Exception.Message) "
                    Write-Verbose "Exception.Message splited: $(($_.ErrorDetails.Message -split '\n')[0]) "
                } else {
                    Write-Verbose "ErrorDetails.Message is null or does not exists. See the error bellow"
                    #UsualException
                    $err = $_
                    Write-Verbose $err
                    #Write-Verbose $err.Exception
                    $_.Exception.ItemName
                    $PSItem.InvocationInfo.PositionMessage
                    $PSItem.InvocationInfo.Line
                    $PSItem.ScriptStackTrace
                    $PSItem.Exception.InnerExceptionMessage
                    $_.Exception.Message
                    $_.Exception.ItemName
                }
}


    $test=Test-Connection -Destination $getc -Count 1 -ErrorAction SilentlyContinue
    $reach=$test | Select-Object -ExpandProperty Address
    $result=@()
    
    foreach ($c in $reach) {
        $i=Invoke-Command -ComputerName $c -ScriptBlock {
        
            #Get-NetIPConfiguration | Select-Object -Property InterfaceAlias,Ipv4Address,DNSServer
            #Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -ExpandProperty NextHop
            Get-DnsClientServerAddress -AddressFamily IPv4  | Select-Object -ExpandProperty ServerAddresses -Unique
        }

        $Hashtable =  New-Object System.Collections.Specialized.OrderedDictionary
        $Hashtable.Add("Server",[string]$c)
        $Hashtable.Add("DNSServer",[string]($i -join ','))
        $Hashtable.Add("Warning","")
        if (($i -join ',') -match "127.0.0.1") { $Hashtable["Warning"]="X"; Write-Host "$c has itself ($c) as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 
        if (($i -join ',') -match "10.13.0.1") { $Hashtable["Warning"]="X"; Write-Host "$c has DC13-01 as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 
        if (($i -join ',') -match "10.13.0.2") { $Hashtable["Warning"]="X"; Write-Host "$c has DC13-02 as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 
        if (($i -join ',') -match "10.13.0.3") { $Hashtable["Warning"]="X"; Write-Host "$c has DC13-03 as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 
        if (($i -join ',') -match "10.16.1.1") { $Hashtable["Warning"]="X"; Write-Host "$c has DC16-01 as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 
        if (($i -join ',') -match "10.13.1.2") { $Hashtable["Warning"]="X"; Write-Host "$c has DC16-02 as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 
        if (($i -join ',') -match "10.13.1.9") { $Hashtable["Warning"]="X"; Write-Host "$c has DC16-05 as DNS Server" -BackgroundColor Magenta -ForegroundColor Yellow } 

        $result +=New-Object -TypeName PSCustomObject -Property ($Hashtable)
        $check = $false; 
    }
$result | Sort-Object -Property Server 
}
