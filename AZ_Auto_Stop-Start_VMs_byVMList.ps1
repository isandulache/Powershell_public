Param (

    # Azure Subscription Id
    [Parameter(Mandatory=$False)][ValidateNotNullOrEmpty()] 
    [String] 
    $AzureSubscriptionId="<< INSERT CLIENT AZ Subscription ID >>",

    # Identify all VMs by it name
    # Use Json format string : ["vm01", "vm02", "vm03"]
    [Parameter (Mandatory = $True)]
    [String]
    $ListVMs,

    # Choose an action to perform
    [Parameter (Mandatory = $True)]
    [ValidateSet ("Start", "Stop", "Restart")]
    [String]
    $Action
)

Connect-AzAccount -Identity  -SubscriptionId $AzureSubscriptionId

$AzureVMs = $ListVMs.Split(",") 
[System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
Write-Output "Azures VM After [$AzureVMs]"
        
# Check if VM exists
$ValidAzureVMsToHandle=@()
foreach($VMName in $AzureVMsToHandle) 
{ 

    Write-Output " ============ Checking if VMName named [$($VMName.Trim())] exists "
    $CheckVM = Get-AzVM | Where-Object { $_.Name -eq $($VMName.Trim()) }
    Write-Output " ============ Checked: [$($CheckVM.Name)] "
    
    if(!(Get-AzVM | Where-Object {$_.Name -like $($VMName.Trim()) })) { 
        Write-Warning  "============ AzureVM : [$($VMName.Trim())] - Does not exist! - Check your inputs " 
    } else {   
        $ValidAzureVMsToHandle += $($VMName.Trim())
        Write-Output " ============ Added VM [$($VMName.Trim())] to valid Azure VMs to handle: [$ValidAzureVMsToHandle] "
        }
}

Write-Output " ";Write-Output " "
Write-Output " ============ Validated VMs: [$ValidAzureVMsToHandle]"

## Perform choosed action to all VMs in list
ForEach ($VMName in $ValidAzureVMsToHandle) {
    ## Getting name of the resource group which contains VM
    $RG = (Get-AzVM | Where-Object {$_.Name -like $VMName }).ResourceGroupName

    ## Perform action
    Switch ($Action) {
        "Start"   { Write-Output "Performing $Action action on $VMName from ressource group $RG"; Start-AzVM   -Name $VMName -ResourceGroupName $RG 
        }
        "Stop"    { Write-Output "Performing $Action action on $VMName from ressource group $RG" ; Stop-AzVM    -Name $VMName -ResourceGroupName $RG -Force 
        }
        "Restart" { Write-Output "Performing $Action action on $VMName from ressource group $RG" ; Restart-AzVM -Name $VMName -ResourceGroupName $RG 
        }
    }
}
