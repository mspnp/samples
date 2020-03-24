# Create variables and setup storage account context, replace the account key with your value

$AccountName = "storageacctres1"
$AccountKey = "zwQcPc1tWLctk1VRk61hiQvTIsSuWWv3rwnnn7Ao8K3lKeyyjM8hicZwoCJBkM9vm7btJGnIeCtaOrj7Kh74EA=="
$azcontext = New-AzureStorageContext -StorageAccountName $AccountName -StorageAccountKey $AccountKey
$fileShareName = "fileshare1"
$fileName="sampleFile.txt"
$folderPath="/"

# Upload a local file

Set-AzureStorageFileContent -ShareName $fileShareName -Source $fileName -Path $folderPath -Context $azcontext

# Get the file share

$fileShare=Get-AzureStorageShare -Context $azcontext -Name $fileShareName

# Take Snapshot

$snapshot = $fileShare.Snapshot()