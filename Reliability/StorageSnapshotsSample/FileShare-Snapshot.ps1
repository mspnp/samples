param ($ResourceGroupName)

# Create variables and setup storage account context

$AccountName = "streliability001"
$AccountKey = (Get-AzStorageAccountKey -Name $AccountName -ResourceGroupName $ResourceGroupName)[0].Value
$azcontext = New-AzureStorageContext -StorageAccountName $AccountName -StorageAccountKey $AccountKey
$fileShareName = "fileshare1"
$fileName=".\ContentFiles\SampleFile.txt"
$folderPath="/"

# Upload a local file

Set-AzureStorageFileContent -ShareName $fileShareName -Source $fileName -Path $folderPath -Context $azcontext

# Get the file share

$fileShare=Get-AzureStorageShare -Context $azcontext -Name $fileShareName

# Take Snapshot

$fileShare.CloudFileShare.Snapshot()

