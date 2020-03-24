
# Create variables and setup storage account context, replace the account key with your value

$AccountName = "storageacctres1"
$AccountKey = "zwQcPc1tWLctk1VRk61hiQvTIsSuWWv3rwnnn7Ao8K3lKeyyjM8hicZwoCJBkM9vm7btJGnIeCtaOrj7Kh74EA=="
$azcontext = New-AzureStorageContext -StorageAccountName $AccountName -StorageAccountKey $AccountKey
$localFile=".\sampleBlobImage.png"
$blobName="sampleBlob"
$containerName = "container1"

# Upload a local file

Set-AzureStorageBlobContent -File $localFile -Container $containerName -Blob $blobName -Context $azcontext

# Get a reference to the blob

$Blob = Get-AzureStorageBlob -Context $azcontext -Container $ContainerName -Blob $BlobName

$CloudBlockBlob = [Microsoft.WindowsAzure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob

# Take a snapshot

$CloudBlockBlob.Metadata["filename"] = $localFile

$CloudBlockBlob.SetMetadata()

$CloudBlockBlob.CreateSnapshot()

