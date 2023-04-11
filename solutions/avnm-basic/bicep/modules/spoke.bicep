param location string
param spokeName string 
param spokeVnetPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-${spokeName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetPrefix
      ]
    }
    subnets: []
  }
}

output vnetId string = vnet.id
