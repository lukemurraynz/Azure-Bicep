@maxLength(24)
@description('Optional. Name of the Storage Account.')
param name string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned,UserAssigned'
  'UserAssigned'
])
@description('Optional. Type of managed service identity.')
param managedServiceIdentity string = 'None'

@description('Optional. Mandatory \'managedServiceIdentity\' contains UserAssigned. The identy to assign to the resource.')
param userAssignedIdentities object = {}

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create.')
param storageAccountKind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param storageAccountSku string = 'Standard_GRS'

@allowed([
  'Hot'
  'Cool'
])
@description('Optional. Storage Account Access Tier.')
param storageAccountAccessTier string = 'Hot'

@description('Optional. Provides the identity based authentication settings for Azure Files.')
param azureFilesIdentityBasedAuthentication object = {}

@description('Optional. Virtual Network Identifier used to create a service endpoint.')
param vNetId string = ''

@description('Optional. Indicates whether public access is enabled for all blobs or containers in the storage account.')
param allowBlobPublicAccess bool = true

@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
@description('Optional. Set the minimum TLS version on request to storage.')
param minimumTlsVersion string = 'TLS1_2'

@description('Optional. If true, enables move to archive tier and auto-delete')
param enableArchiveAndDelete bool = false

@description('Optional. If true, enables Hierarchical Namespace for the storage account')
param enableHierarchicalNamespace bool = false

@description('Optional. Set up the amount of days after which the blobs will be moved to archive tier')
param moveToArchiveAfter int = 30

@description('Optional. Set up the amount of days after which the blobs will be deleted')
param deleteBlobsAfter int = 1096

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Tags of the resource.')
param tags object = {}


@description('Generated. Do not provide a value! This date value is used to generate a SAS token to access the modules.')
param basetime string = utcNow('u')

var maxNameLength = 24
var uniqueStoragenameUntrim = '${uniqueString('Storage Account${basetime}')}'
var uniqueStoragename = length(uniqueStoragenameUntrim) > maxNameLength ? substring(uniqueStoragenameUntrim, 0, maxNameLength) : uniqueStoragenameUntrim
var storageAccountName_var = empty(name) ? uniqueStoragename : name


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName_var
  location: location
  kind: storageAccountKind
  sku: {
    name: storageAccountSku
  }

  tags: tags
 

  // lifecycle policy
  resource storageAccount_managementPolicies 'managementPolicies@2019-06-01' = if (enableArchiveAndDelete) {
    name: 'default'
    properties: {
      policy: {
        rules: [
          {
            enabled: true
            name: 'retention-policy'
            type: 'Lifecycle'
            definition: {
              actions: {
                baseBlob: {
                  tierToArchive: {
                    daysAfterModificationGreaterThan: moveToArchiveAfter
                  }
                  delete: {
                    daysAfterModificationGreaterThan: deleteBlobsAfter
                  }
                }
                snapshot: {
                  delete: {
                    daysAfterCreationGreaterThan: deleteBlobsAfter
                  }
                }
              }
              filters: {
                blobTypes: [
                  'blockBlob'
                ]
              }
            }
          }
        ]
      }
    }
  }
}

resource storageAccount_lock 'Microsoft.Authorization/locks@2016-09-01' = if (lock != 'NotSpecified') {
  name: '${storageAccount.name}-${lock}-lock'
  properties: {
    level: lock
    notes: (lock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: storageAccount
}




output storageAccountResourceId string = storageAccount.id


output storageAccountName string = storageAccount.name


output storageAccountResourceGroup string = resourceGroup().name
