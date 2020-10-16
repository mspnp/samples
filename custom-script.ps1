$script = "https://raw.githubusercontent.com/neilpeterson/talk-ignite-tour/master/ignite-tour-hyb30/support-scripts/w3svc-service.ps1"

Set-AzVMCustomScriptExtension -ResourceGroupName AZUREMONITORNINER001 -Name config -VMName windows-vm -Location eastus -FileUri $script -ForceRerun ferfe

# Set-AzVMCustomScriptExtension -ResourceGroupName "ResourceGroup11" -Location "Central US" -VMName "VirtualMachine07" -Name "ContosoTest" -TypeHandlerVersion "1.1" -StorageAccountName "Contoso" -StorageAccountKey  -FileName "ContosoScript.exe" -ContainerName "Scripts"