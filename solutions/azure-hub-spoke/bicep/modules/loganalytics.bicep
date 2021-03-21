var logAnalyticsWorkspaceName = uniqueString(subscription().subscriptionId, resourceGroup().id)

resource logAnalyticsWrokspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: 'eastus'
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWrokspace.id