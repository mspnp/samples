param connectionName string = 'mock-prem-to-hub'
param azureCloudVnetPrefix string
param spokeNetworkAddressPrefix string
param gatewayIpAddress string
param mocOnpremGatewayName string
param localNetworkGateway string = 'local-gateway-moc-prem'
param location string  = resourceGroup().location

resource localNetworkGateway_resource 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: localNetworkGateway
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        azureCloudVnetPrefix
        spokeNetworkAddressPrefix
      ]
    }
    gatewayIpAddress: gatewayIpAddress
    bgpSettings: {
      asn: 40000
      bgpPeeringAddress: gatewayIpAddress
    }
  } 
}

resource connection 'Microsoft.Network/connections@2023-04-01' = {
  name: connectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: resourceId('Microsoft.Network/virtualNetworkGateways', mocOnpremGatewayName)
    }
    localNetworkGateway2: {
      id: localNetworkGateway_resource.id
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 100
    sharedKey: '123secret'
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    expressRouteGatewayBypass: false
    dpdTimeoutSeconds: 0
  }
}
