targetScope = 'subscription'
param mocOnPremResourceGroup string = 'site-to-site-mock-prem'
param azureNetworkResourceGroup string = 'site-to-site-azure-network'

@description('The admin user name for both the Windows and Linux virtual machines.')
param adminUserName string

@description('The admin password for both the Windows and Linux virtual machines.')
@secure()
param adminPassword string
param resourceGrouplocation string = 'eastus'

resource mocOnPremResourceGroup_resource 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: mocOnPremResourceGroup
  location: resourceGrouplocation
}

resource azureNetworkResourceGroup_resource 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: azureNetworkResourceGroup
  location: resourceGrouplocation
}

module onPremMock 'nestedtemplates/mock-onprem-azuredeploy.bicep' = {
  name: 'onPremMock'
  scope: mocOnPremResourceGroup_resource
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: resourceGrouplocation
  }
}

module azureNetwork 'nestedtemplates/azure-network-azuredeploy.bicep' = {
  name: 'azureNetwork'
  scope: azureNetworkResourceGroup_resource
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: resourceGrouplocation
  }
}

module mockOnPremLocalGateway 'nestedtemplates/mock-onprem-local-gateway.bicep' = {
  name: 'mockOnPremLocalGateway'
  scope: mocOnPremResourceGroup_resource
  params: {
    gatewayIpAddress: azureNetwork.outputs.vpnIp
    azureCloudVnetPrefix: azureNetwork.outputs.mocOnpremNetwork
    spokeNetworkAddressPrefix: azureNetwork.outputs.spokeNetworkAddressPrefix
    mocOnpremGatewayName: onPremMock.outputs.mocOnpremGatewayName
    location: resourceGrouplocation
  }
}

module azureNetworkLocalGateway 'nestedtemplates/azure-network-local-gateway.bicep' = {
  name: 'azureNetworkLocalGateway'
  scope: azureNetworkResourceGroup_resource
  params: {
    azureCloudVnetPrefix: onPremMock.outputs.mocOnpremNetworkPrefix
    gatewayIpAddress: onPremMock.outputs.vpnIp
    azureNetworkGatewayName: azureNetwork.outputs.azureGatewayName
    location: resourceGrouplocation
  }
}
