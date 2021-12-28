param storageaccprefix string = ''
var location = resourceGroup().location

resource storageacc 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${storageaccprefix}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
  
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}
