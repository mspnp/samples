# This command line uses azcopy to copy files between Storage Accounts.
# Replace the <SAS-token> placeholder with your Shared Access Signature
# See https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview for more info


azcopy copy "https://storageacctres1.blob.core.windows.net/container1/?<SAS-token>" "https://storageacctres1target.blob.core.windows.net/container1/" --recursive



