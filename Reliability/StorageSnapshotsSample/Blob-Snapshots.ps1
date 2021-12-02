param ($ResourceGroupName)

# Create variables and setup storage account context

$AccountName = "storageacctres1"
$AccountKey = (Get-AzStorageAccountKey -Name $AccountName -ResourceGroupName $ResourceGroupName)[0].Value
$azcontext = New-AzureStorageContext -StorageAccountName $AccountName -StorageAccountKey $AccountKey
$localFile=".\ContentFiles\SampleBlobImage.png"
$blobName="sampleBlob"
$containerName = "container1"


# Upload a local file

Set-AzureStorageBlobContent -File $localFile -Container $containerName -Blob $blobName -Context $azcontext

# Get a reference to the blob

$Blob = Get-AzureStorageBlob -Context $azcontext -Container $ContainerName -Blob $BlobName

$CloudBlockBlob = $Blob.ICloudBlob

# Take a snapshot

$CloudBlockBlob.Metadata["filename"] = $localFile

$CloudBlockBlob.SetMetadata()

$CloudBlockBlob.CreateSnapshot()

