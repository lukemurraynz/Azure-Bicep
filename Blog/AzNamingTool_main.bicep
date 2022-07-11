///Parameter Setting
param location string = resourceGroup().location

//Adjust Parameter values to match your naming conventions

param serverfarms_AzNamingTool_ASP_Prod_name string = 'AzNamingTool-ASP-Prod'
param storageAccounts_aznamingstgacc_name string = 'aznaming'

// The following Parameters are used add Tags to your deployed resources. Adjust for your own needs.

param dateTime string = utcNow('d')
param resourceTags object = {
  Application: 'Azure Naming Tool'
  Version: 'v2.0'
  CostCenter: 'Operational'
  CreationDate: dateTime
  Createdby: 'Luke Murray (luke.geek.nz)'
}

/// Deploys Resources

//Deploys Azure Storage Account for Azure File Share for AzNamingtool persistant data

resource storageAccounts_aznamingstgacc_name_resource 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${storageAccounts_aznamingstgacc_name}${uniqueString(resourceGroup().id)}'
  location: location
  tags: resourceTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
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
// Deploys Azure File Share from the Storage Account above.

resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_aznamingstgacc_name_default 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  parent: storageAccounts_aznamingstgacc_name_resource
  name: 'default'

  properties: {

    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource storageAccounts_aznamingstgacc_name_default_aznamingtool 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  parent: Microsoft_Storage_storageAccounts_fileServices_storageAccounts_aznamingstgacc_name_default
  name: 'aznamingtool'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 500
    enabledProtocols: 'SMB'
  }
}

//Deploys the App Service PLan for AzNamingTool

resource serverfarms_AzNamingTool_ASP_Prod_name_resource 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: serverfarms_AzNamingTool_ASP_Prod_name
  tags: resourceTags
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    freeOfferExpirationTime: '2022-08-09T06:05:57.0366667'
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}
