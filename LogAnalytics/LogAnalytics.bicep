
@description('Log Analytics Workspace')
resource LAWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  properties: {

    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  location: 'Australia East'
  name: 'LA-DefaultWorkspace'
}
