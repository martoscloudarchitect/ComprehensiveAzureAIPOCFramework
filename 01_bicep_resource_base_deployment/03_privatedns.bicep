/*
This script creates a private DNS Zone and links it the existing virtual network.
*/

@description('The name of the Private DNS Zone')
param privateDnsZoneName string = 'privatedns-${toLower(resourceGroup().name)}.local' /// 'privatelink.bicepdeploydemo.com'

@description('The name of the Virtual Network to link to the Private DNS Zone') /// Must match the vnetName in 02_vnet_snet.bicep
param vnetName string = 'vnet-${toLower(resourceGroup().name)}' /// 'myBicepVnet'

@description('The location for the Private DNS Zone')
param location string = 'global' /// private DNS is a global respource

/// Create the Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: location
  properties: {}
}

 
/// Link the Private DNS Zone to the existing Virtual Network
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}-vnetLink'
  parent: privateDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: true
  }
/*  dependsOn: [
    privateDnsZone
  ] */
}


