targetScope = 'subscription'

param networkGroupId string

@description('This is a Policy definition for dyanamic group membership')
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: uniqueString(networkGroupId)
  properties: {
    description: 'AVNM quickstart dynamic group membership Policy'
    displayName: 'AVNM quickstart dynamic group membership Policy'
    mode: 'Microsoft.Network.Data'
    policyRule: {
      if: {
        allof: [
          {
            field: 'type'
            equals: 'Microsoft.Network/virtualNetworks'
          }
          {
            field: 'tags[_avnm_quickstart_deployment]'
            equals: 'spoke'
          }
        ]
      }
      then: {
        effect: 'addToNetworkGroup'
        details: {
          networkGroupId: networkGroupId
        }
      }
    }
  }
}

@description('Assigns above policy for dynamic group membership')
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: uniqueString(networkGroupId)
  properties: {
    description: 'AVNM quickstart dynamic group membership Policy'
    displayName: 'AVNM quickstart dynamic group membership Policy'
    enforcementMode: 'Default'
    policyDefinitionId: policyDefinition.id
  }
}
