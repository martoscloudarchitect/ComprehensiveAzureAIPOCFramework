/// Deploys a virtual machine in the existing resource group defined in the deployment powershell script
/// The VM is deployed in the SpokeSubnet1vm subnet created in the 02_vnet_snet.bicep file
/// The VM is created with a public IP address and a network interface for test 1
/// The VM is created with a private IP address only for test 2

/// VM is deployed as a B2 series VM with 2 vCPUs and 4GB RAM and windows server 2025 image from the market place


@description('The name of the Virtual Machine')
param vmName string = 'vm-${take(uniqueString(resourceGroup().id), 8)}'

@description('The size of the Virtual Machine')
@allowed([
  'Standard_B2s'
  'Standard_B4ms'
  'Standard_DS1_v2'
])
param vmSize string = 'Standard_DS1_v2' 

@description('The admin username for the Virtual Machine')
param adminName string = 'vmSuperAdmin'

@description('The admin password for the Virtual Machine')
@secure()
param adminPassword string = 'H@shT@agSup3Adm!n'

@description('The name of the Network Interface')
param nicName string = 'nic-vm-${toLower(resourceGroup().name)}'

@description('The name of the Public IP Address')
param pipName string = 'pip-vm-${toLower(resourceGroup().name)}'

@description('The name of the OS Disk')
param osDiskName string = 'osdisk-vm-${toLower(resourceGroup().name)}'

@description('The name of the Virtual Network')
param vnetName string = 'vnet-${toLower(resourceGroup().name)}' /// Must match the vnetName in 02_vnet_snet.bicep

@description('The name of the Subnet for the VM')
param subnetName string = 'spokeSubnet1vm-${toLower(resourceGroup().name)}' /// Must match the spokeSubnet1

@description('The address prefix for the Subnet for the VM')
param subnetAddressPrefix string = '10.2.1.0/24' /// Must match the spokeSubnet1vmAddressPrefix in 02_vnet_snet.bicep

// NEW: Private DNS Zone name to match 03_privatedns.bicep
@description('The name of the Private DNS Zone')
param privateDnsZoneName string = 'privatedns-${toLower(resourceGroup().name)}.local'

@description('Deploy VM with Public IP (true) or Private IP only (false)')
param deployWithPublicIP bool = true

var location = resourceGroup().location


/* Deploys the virtual machine and related resources.
It Includes both public IP address for test 1 and private IP address for test 2 from the 02_vnet_snet.bicep file
It connects the VM to Private DNS zone for the VNet from the 03_privatedns.bicep file
*/

// Reference to the existing private DNS zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

// Reference to the existing virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

// Reference to the existing subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: subnetName
  parent: vnet
}

/// Creates a public IP Address if deployWithPublicIP is true
resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (deployWithPublicIP) {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-dns')
    }
  }
}

/// Creates a network interface for the VM with proper DNS configuration
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          publicIPAddress: deployWithPublicIP ? {
            id: pip.id
          } : null
        }
      }
    ]
    // IMPORTANT: Configure DNS servers to use Azure-provided DNS
    dnsSettings: {
      dnsServers: [] // Empty array means use Azure-provided DNS which resolves private DNS zones
    }
  }
}

/// Creates the virtual machine and associates the network interface
resource virtualmachine 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminName
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2025-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

/*
For test 2: 
Creates a virtual machine extension to join the VM to the private DNS zone
This requires the VM to have access to the private DNS zone via the VNet and subnet
It also requires the VM to use Azure-provided DNS servers, which is configured in the NIC above 
The extension uses the CustomScript extension to run a PowerShell script that adds the VM to the private DNS zone
*/


// Create a DNS A record in the private DNS zone for the VM
resource vmDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: vmName
  parent: privateDnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: nic.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
  }
  dependsOn: [
    virtualmachine
  ]
}
