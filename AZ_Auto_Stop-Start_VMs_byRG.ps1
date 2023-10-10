Param (

    # Azure Subscription Id
    [Parameter(Mandatory=$False)][ValidateNotNullOrEmpty()] 
    [String] 
    $AzureSubscriptionId="<< INSERT CLIENT AZ Subscription ID >>",

    # Identify all VMs by their name
    # String Format expected "vm01, vm02, vm03"
    [Parameter (Mandatory = $False)]
    [String] 
    $AzureVMList="All",
    

    # Choose an action to perform
    [Parameter (Mandatory = $false)]
    [ValidateSet ("Start", "Stop", "Restart")]
    [String]
    $Action,

    # Ressource Group 
    [Parameter(Mandatory=$False)][ValidateNotNullOrEmpty()] 
    [String] 
    $RG = "prod-automation-rg"
)


Connect-AzAccount -Identity -SubscriptionId $AzureSubscriptionId

## Perform choosed action to all VMs in list
if($AzureVMList -ne 'All') { 

Write-Output "Azures VM Before  [$AzureVMs]"
        $AzureVMs = $AzureVMList.Split(",") 
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
Write-Output "Azures VM After [$AzureVMs]"
        
        # Check if VM exists
        $ValidAzureVMsToHandle=@()
    foreach($VMName in $AzureVMsToHandle) 
            { 

                Write-Output " ============ Checking if VMName named [$VMName] exists "
                $CheckVM = Get-AzVM | Where-Object { $_.Name -eq $VMName }
                Write-Output " ============ Checked: [$($CheckVM.Name)] "
                
                if(!(Get-AzVM | Where-Object {$_.Name -like $VMName })) { 
                    Write-Warning  "============ AzureVM : [$VMName] - Does not exist! - Check your inputs " 
                } else {   
                    $ValidAzureVMsToHandle += $VMName 
					Write-Output " ============ Added VM [$VMName] to valid Azure VMs to handle: [$ValidAzureVMsToHandle] "
                    }
            }

    Write-Output " ";Write-Output " "
    Write-Output " ============ Validated VMs: [$ValidAzureVMsToHandle]"

    } else {

        if (($null -eq $RG) -or ($RG -eq "")) { 
            throw " Ressource Group not defined - Check your inputs " 
        } else {
            # Retrieve all VMs in the specified RG
            $ValidAzureVMsToHandle = (Get-AzVM -ResourceGroupName $RG).Name 
        }
} 

Write-Output " ";Write-Output " "
# Perform action on each VM
ForEach ($VMName in $ValidAzureVMsToHandle) {
    Write-Output " ";Write-Output " "
Write-Output " ============ Perform action on VM [$VMName]"
    ## Getting name of the resource group which contains VM
    $RG = (Get-AzVM | Where-Object {$_.Name -like $VMName }).ResourceGroupName
Write-Output " ============ Ressource Group found is [$RG]"
    ## Perform action
    Switch ($Action) {
        "Start"   { Write-Output "Performing $Action action on $VMName"; Start-AzVM   -Name $VMName -ResourceGroupName $RG 
        }
        "Stop"    { Write-Output "Performing $Action action on $VMName" ; Stop-AzVM    -Name $VMName -ResourceGroupName $RG -Force 
        }
        "Restart" { Write-Output "Performing $Action action on $VMName" ; Restart-AzVM -Name $VMName -ResourceGroupName $RG 
        }
    }
}
