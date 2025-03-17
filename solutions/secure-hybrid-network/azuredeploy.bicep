targetScope = 'subscription'
param mocOnPremResourceGroup string
param azureNetworkResourceGroup string

@description('The admin user name for both the Windows and Linux virtual machines.')
param adminUserName string

@description('The admin password for both the Windows and Linux virtual machines.')
@secure()
param adminPassword string
param location string = deployment().location

resource mocOnPremResourceGroup_resource 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: mocOnPremResourceGroup
  location: location
}

resource azureNetworkResourceGroup_resource 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: azureNetworkResourceGroup
  location: location
}

module onPremMock 'nestedtemplates/mock-onprem-azuredeploy.bicep' = {
  name: 'onPremMock'
  scope: mocOnPremResourceGroup_resource
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: location
  }
}

module azureNetwork 'nestedtemplates/azure-network-azuredeploy.bicep' = {
  name: 'azureNetwork'
  scope: azureNetworkResourceGroup_resource
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: location
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
    location: location
  }
}

module azureNetworkLocalGateway 'nestedtemplates/azure-network-local-gateway.bicep' = {
  name: 'azureNetworkLocalGateway'
  scope: azureNetworkResourceGroup_resource
  params: {
    azureCloudVnetPrefix: onPremMock.outputs.mocOnpremNetworkPrefix
    gatewayIpAddress: onPremMock.outputs.vpnIp
    azureNetworkGatewayName: azureNetwork.outputs.azureGatewayName
    location: location
  }
}
