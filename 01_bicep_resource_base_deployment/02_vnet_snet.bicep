/// Deploys a VNET with the Subnets in the target resoruce group defined in the deployment powershell 


/// Part 1 - Defines the names for the VNET
@description('The name of the Virtual Network, unique resource name using the first 3 letters of the resource group ID')
param vnetName string = 'vnet-${toLower(resourceGroup().name)}' /// 'myBicepVnet'

@description('The name of the Spoke Subnet 1 for VMs, unique resource name using the first 3 letters of the resource group ID')
param spokeSubnet1vmName string = 'spokeSubnet1vm-${toLower(resourceGroup().name)}' /// 'SpokeSubnet1vm'

@description('The name of the Spoke Subnet 2 for App Services, unique resource name using the first 3 letters of the resource group ID')
param spokeSubnet2appName string = 'spokeSubnet2app-${toLower(resourceGroup().name)}' /// 'SpokeSubnet2app'

@description('The name of the Spoke Subnet 3 for Private Endpoints, unique resource name using the first 3 letters of the resource group ID')
param spokeSubnet3privateEndpointName string = 'spokeSubnet3privateEndpoint-${toLower(resourceGroup().name)}' /// 'SpokeSubnet3privateEndpoint'

/// Part 2 - Address spaces and prefixes for Subnets associated with the VNET above
@description('The address space for the Virtual Network')
param vnetAddressSpace string = '10.2.0.0/16'

@description('The address prefix for the Gateway Subnet where the VPN Gateway will be deployed')
param gatewaySubnetAddressPrefix string = '10.2.0.0/24'

@description('The address prefix for the Spoke Subnet 1 for VMs')
param spokeSubnet1vmAddressPrefix string = '10.2.10.0/24'

@description('The address prefix for the Spoke Subnet 2 for App Services')
param spokeSubnet2appAddressPrefix string = '10.2.20.0/24'

@description('The address prefix for the Spoke Subnet 3 for Private Endpoints')
param spokeSubnet3privateEndpointAddressPrefix string = '10.2.30.0/24'

//// Part 3 - Creates the VNET 
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
  }
}

//// Part 4 - Creates the Subnets within the VNET
resource GatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'GatewaySubnet'
  parent: vnet
  properties: {
    addressPrefix: gatewaySubnetAddressPrefix
  }
}

resource spokeSubnet1vm 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: spokeSubnet1vmName
  parent: vnet
  properties: {
    addressPrefix: spokeSubnet1vmAddressPrefix  
  }
  dependsOn: [
    GatewaySubnet
  ]
} 

resource spokeSubnet2app 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: spokeSubnet2appName
  parent: vnet
  properties: {
    addressPrefix: spokeSubnet2appAddressPrefix
  }
  dependsOn: [
    spokeSubnet1vm
  ]
}

resource spokeSubnet3privateEndpoint 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: spokeSubnet3privateEndpointName
  parent: vnet
  properties: {
    addressPrefix: spokeSubnet3privateEndpointAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'  // This is required for Private Endpoints
  }
  dependsOn: [
    spokeSubnet2app
  ]
}

