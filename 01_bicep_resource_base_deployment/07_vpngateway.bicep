param vpnGatewayName string = 'vpngateway-${toLower(resourceGroup().name)}'
param location string = resourceGroup().location

@allowed([
  'Vpn'
  'ExpressRoute'
])
param gatewayType string = 'Vpn'

@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'

@description('The virtual network gateway ASN.VpnGw1 - Generation 1, supports active directory authentication and costs about 140 USD per month. VpnGw2 Generation 1 supports IKEv2 and OpenVPN protocols and costs about 280 USD per month.')
@allowed([ 
  'VpnGw1'
  'VpnGw2'
])
param skuName string = 'VpnGw1'

@allowed([
  'Generation1'
  'Generation2'
])
param vpnGatewayGeneration string = 'Generation1'

param subnetId string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/vnet-${toLower(resourceGroup().name)}/subnets/GatewaySubnet'
param publicIpAddressName string = 'pip-vpngw-${toLower(resourceGroup().name)}'

resource vpnGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vpngatewayipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: vpnGatewayPublicIp.id
          }
        }
      }
    ]
    gatewayType: gatewayType
    vpnType: vpnType
    enableBgp: false
    activeActive: false
    sku: {
      name: skuName
      tier: skuName
 
    }
  }
  dependsOn: [
    vpnGatewayPublicIp
  ]
}
