/// Deploys the Azure Foundry environment in the target resource group defined in the deployment powershell

@description('The name of the azure foundry deployment')
param aiFoundryName string = 'myAzFoundry-${toLower(resourceGroup().name)}' // must be globally unique, between 3 and 24 characters, alphanumeric only

@description('The location for all resources in the deployment')
param location string = resourceGroup().location


@description('The name of the AI Foundry project')
param aiFoundryProjectName string = '${aiFoundryName}-proj'


/*
  An AI Foundry resources is a variant of a CognitiveServices/account resource type
*/ 
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    // required to work in AI Foundry
    allowProjectManagement: true 

    // Defines developer API endpoint subdomain
    customSubDomainName: aiFoundryName

    disableLocalAuth: false // disable local auth, enforce AAD only
  }
}

/*
  Developer APIs are exposed via a project, which groups in- and outputs that relate to one use case, including files.
  Its advisable to create one project right away, so development teams can directly get started.
  Projects may be granted individual RBAC permissions and identities on top of what account provides.
*/ 

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  name: aiFoundryProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
  dependsOn: [
    aiFoundry
  ]
}

/*
  Optionally deploy a model to use in playground, agents and other tools.


resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01'= {
  parent: aiFoundry
  name: 'gpt-4o'
  sku : {
    capacity: 1
    name: 'GlobalStandard'
  }
  properties: {
    model:{
      name: 'gpt-4o'
      format: 'OpenAI'
    }
  }
  dependsOn: [
    aiProject
  ]
}

*/
