param connectionName string = 'hub-to-mock-prem'
param gatewayIpAddress string
param azureCloudVnetPrefix string
param azureNetworkGatewayName string
param localNetworkGatewayName string = 'local-gateway-azure-network'
param location string  = resourceGroup().location

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: localNetworkGatewayName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        azureCloudVnetPrefix
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
      id: resourceId('Microsoft.Network/virtualNetworkGateways', azureNetworkGatewayName)
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
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
