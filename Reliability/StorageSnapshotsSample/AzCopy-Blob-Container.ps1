param ($ResourceGroupName)

# This command line uses azcopy to copy files between Storage Accounts.
# See https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview for more info on SAS tokens

# Acquire a read-only SAS token for the source account
$SourceAccountName = "storageacctres1"
$SourceAccountKey = (Get-AzStorageAccountKey -Name $SourceAccountName -ResourceGroupName $ResourceGroupName)[0].Value
$SourceAzContext = New-AzureStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey
$SourceSASToken = New-AzureStorageContainerSASToken -Name container1 -Context $SourceAzContext -Permission rl

# Acquire a write-only SAS token for the target account
$TargetAccountName = "storageacctres1target"
$TargetAccountKey = (Get-AzStorageAccountKey -Name $TargetAccountName -ResourceGroupName $ResourceGroupName)[0].Value
$TargetAzContext = New-AzureStorageContext -StorageAccountName $TargetAccountName -StorageAccountKey $TargetAccountKey
$TargetSASToken = New-AzureStorageContainerSASToken -Name container1 -Context $TargetAzContext -Permission w

# Perform a recursive copy from the source account container to the target account container
# Note: There will be a warning about not creating the container since we are using constrained SAS tokens for the containers
# Note: We are using a write-only key for the target container, so --check-length=false is used to supress a warning
azcopy copy "https://storageacctres1.blob.core.windows.net/container1/$SourceSASToken" "https://storageacctres1target.blob.core.windows.net/container1/$TargetSASToken" --recursive --check-length=false