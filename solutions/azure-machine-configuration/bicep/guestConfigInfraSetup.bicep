targetScope = 'resourceGroup'

@minLength(5)
@description('Location of the resources. Defaults to resource group location.')
param location string = resourceGroup().location

@minLength(36)
@description('The guid of the principal running the valet key generation code. In Azure this would be replaced with the managed identity of the Azure Function, when running locally it will be your user.')
param principalId string

@minLength(5)
@description('The globally unique name for the storage account.')
param storageAccountName string

/*** EXISTING RESOURCES ***/

@description('Built-in Azure RBAC role that is applied to a Storage account to grant "Storage Blob Data Contributor" privileges. ')
resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  scope: subscription()
}

@description('Built-in Azure RBAC role that is applied to a Storage account to grant "Storage Blob Data Reader" privileges.')
resource storageBlobDataReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  scope: subscription()
}

@description('Built-in Azure RBAC role that is applied to a resource group to grant "Contributor" privileges. ')
resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  scope: subscription()
}

@description('Built-in Azure RBAC role that is applied to a Storage account to grant "Storage Blob Data Contributor" privileges. Used by the managed identity of the valet key Azure Function as for being able to delegate permissions to create blobs.')
resource guestConfigurationResourceContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '088ab73d-1256-47ae-bea9-9de8e7131f31'
  scope: subscription()
}
/*** NEW RESOURCES ***/

@description('The Azure Storage account which will be where authorized clients upload large blobs to. The Azure Function will hand out scoped, time-limited SaS tokens for this blobs in this account.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false // Only managed identity allowed, we needed to change the way to generate SAS token using UserDelegationKey
    isLocalUserEnabled: false
    isHnsEnabled: false
    isNfsV3Enabled: false
    isSftpEnabled: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled' // In a valet key scenario, typically clients are not hosted in your virtual network. However if they were, then you could disable this. In this sample, you'll be accessing this from your workstation.
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    allowedCopyScope: 'PrivateLink'
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '00.00:10:00' // Log the creation of SaS tokens over 10 minutes long
    }
    keyPolicy: {
      keyExpirationPeriodInDays: 10 // Storage account key isn't used, require agressive rotation
    }
    networkAcls: {
      defaultAction: 'Allow' // For this sample, public Internet access is expected
      bypass: 'None'
      virtualNetworkRules: []
      ipRules: []
    }
  }

  resource blobContainers 'blobServices' = {
    name: 'default'

    @description('The blob container that SaS tokens will be generated for.')
    resource uploadsContainer 'containers' = {
      name: 'windowsmachineconfiguration'
    }
  }
}

@description('Allows the principal to upload blobs to the storage account.')
resource blobContributorUploadStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount::blobContainers::uploadsContainer.id, storageBlobDataContributorRole.id, principalId)
  scope: storageAccount::blobContainers::uploadsContainer
  properties: {
    principalId: principalId
    roleDefinitionId: storageBlobDataContributorRole.id
    principalType: 'User' // 'ServicePrincipal' if this was a managed identity
    description: 'Allows this Microsoft Entra principal to manage blobs in this storage container.'
  }
}

resource policyAssigmentUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'id-policy-assigment-${location}'
  location: location
}

resource policyDownloadUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'id-policy-download-${location}'
  location: location
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(policyAssigmentUserAssignedIdentity.id, 'contributor-role')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRole.id
    principalId: policyAssigmentUserAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource guestConfigRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(policyAssigmentUserAssignedIdentity.id, 'guest-config-role')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: guestConfigurationResourceContributorRole.id
    principalId: policyAssigmentUserAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageBlobDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(policyDownloadUserAssignedIdentity.id, 'storageBlobDataReaderRole')
  scope: storageAccount::blobContainers::uploadsContainer
  properties: {
    roleDefinitionId: storageBlobDataReaderRole.id
    principalId: policyDownloadUserAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountName string = storageAccount.name
output containerName string = 'windowsmachineconfiguration'
output policyAssigmentUserAssignedIdentityId string = policyAssigmentUserAssignedIdentity.id
output policyDownloadUserAssignedIdentityId string = policyDownloadUserAssignedIdentity.id
