targetScope = 'subscription'

/*** PARAMETERS ***/
@description('Network group ID to which the policy will be assigned')
param networkGroupId string
@description('Resource group name for filtering the policy assignment')
param resourceGroupName string

/*** RESOURCES ***/

@description('This is a Policy definition for dyanamic group membership')
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' = {
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
            // virtual networks must have -prod in the name
            field: 'name'
            contains: '-prod'
          }
          {
            // virtual network ids must include this sample's resource group ID - limiting the chance that dynamic membership impacts other vnets in your subscriptions
            field: 'id'
            like: '${subscription().id}/resourcegroups/${resourceGroupName}/*'
          }
        ]
      }
      then: {
        // 'addToNetworkGroup' is a special effect used by AVNM network groups
        effect: 'addToNetworkGroup'
        details: {
          networkGroupId: networkGroupId
        }
      }
    }
  }
}

// once assigned, the policy will evaluate as new VNETs are created and on a special evaluation cycle for AVNM, enabling quick dynamic group updates
@description('Assigns above policy for dynamic group membership')
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: uniqueString(networkGroupId)
  properties: {
    description: 'AVNM quickstart dynamic group membership Policy'
    displayName: 'AVNM quickstart dynamic group membership Policy'
    enforcementMode: 'Default'
    policyDefinitionId: policyDefinition.id
  }
}

output policyDefinitionId string = policyDefinition.id
output policyAssignmentId string = policyAssignment.id
