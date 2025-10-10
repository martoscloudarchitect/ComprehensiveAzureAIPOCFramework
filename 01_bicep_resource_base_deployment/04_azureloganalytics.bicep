/// Deploys an Azure Log Analytics Workspace
@description('Name of the Log Analytics Workspace')
param workspaceName string = 'mylgawkspace-${toLower(resourceGroup().name)}'
@description('Location for all resources')
param location string = resourceGroup().location
@description('The retention period for the workspace data in days')
param retentionInDays int = 30 /// Retention period for data in days impacts cost
@description('The pricing tier for the workspace')
param sku string = 'PerGB2018' // Other options: Free, Standalone, CapacityReservation, PerNode, PerVolume, CommitmentTier1, CommitmentTier2, CommitmentTier3     
@description('The workspace daily quota in GB per day')
param dailyQuotaGb int = 1 // Daily data ingestion limit in GB impacts cost (minimum 0.023 GB)

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}
