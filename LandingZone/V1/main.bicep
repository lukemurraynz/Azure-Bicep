//Target Scope is: Subscription

targetScope = 'subscription'

//Parameter and Variable Setting
param contactEmail string = 'email@luke.geek.nz'
param contactName string = 'Luke Murray'

@minLength(3)
@maxLength(6)
param sitecode string = 'luke'
@allowed([
  'Prod'
  'Dev'
])
param environment string = 'Prod'
//var environmentLetter = substring(environment,0,1)

@allowed([
  'australiaeast'
  'australiasoutheast'
])
param location string = 'australiaeast'

var locationshort = {
  australiaeast: 'au-e'
  australiasoutheast: 'au-se'
}

param dateTime string = utcNow('d')

param resourceTags object = {
  Application: 'Azure Infrastructure Management'
  CostCenter: 'Operational'
  CreationDate: dateTime
  Environment: environment
  CreatedBy: contactEmail
  Notes: 'Created on behalf of: ${sitecode} for their Azure Landing Zone.'
}

//var environmentLetter = substring(environment,0,1)

//// Resource Creation

/// Create - Management Groups

resource prodManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${sitecode}-prdmgmt-group'
  scope: tenant()
  properties: {
    displayName: 'production'
  }
}

resource testManagementGroup 'Microsoft.Management/managementGroups@2020-02-01' = {
  name: '${sitecode}-tstmgmt-group'
  scope: tenant()
  properties: {
    displayName: 'test'
  }
}

/// Create - Resource Groups

// Creates Network Resource Group
module networkrg './modules/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: '${sitecode}-network-rg-${environment}-${locationshort[location]}'
  params: {
    location: location
    tags: resourceTags
    resourceGroupName: toLower('${sitecode}-network-rg-${environment}-${locationshort[location]}')
  }
}

// Creates Azure Management Resource Group
module azmanagerg './modules/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: '${sitecode}-azmanage-rg-${environment}-${locationshort[location]}'
  params: {
    location: location
    tags: resourceTags
    resourceGroupName: toLower('${sitecode}-azmanage-rg-${environment}-${locationshort[location]}')
  }
}

// Creates Azure Backup Resource Group
module azbackuprg './modules/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: '${sitecode}-backups-rg-${environment}-${locationshort[location]}'
  params: {
    location: location
    tags: resourceTags
    resourceGroupName: toLower('${sitecode}-backups-rg-${environment}-${locationshort[location]}')
  }
}

/// Create - Resources

// Create Azure Virtual Network & base Subnets
module azvirtualnetwork './modules/Microsoft.Network/virtualNetworks/deploy.bicep' = {
  name: '${sitecode}-vnet'
  scope: resourceGroup(networkrg.name)
  params: {
    location: location
    vNetName: toLower('${sitecode}-${environment}-vnet-${location}-001')
    tags: resourceTags

    vNetAddressPrefixes: [
      '192.168.0.0/16'
    ]
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '192.168.1.0/26'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '192.168.1.64/27'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '192.168.1.128/26'
      }
      {
        name: toLower('${sitecode}-${environment}-snet-${location}-001')
        addressPrefix: '192.168.2.0/24'
      }
    ]
  }
}

// Create Azure Network Watcher
module aznetworkwacher './modules/Microsoft.Network/networkWatchers/deploy.bicep' = {
  name: '${sitecode}-network-watcher'
  scope: resourceGroup(networkrg.name)
  params: {
    monitors: []
    location: location
    tags: resourceTags
    networkWatcherName: toLower('${sitecode}-network-watcher-${environment}-${locationshort[location]}')
  }
}

// Create Lock to prevent Network deletion

module azvirtualnetworklock './modules/Custom/ResourceLock.bicep' = {
  name: '${sitecode}-vnet-lock'
  scope: resourceGroup(networkrg.name)
  params: {
    name: toLower('${sitecode}-vnet-lock')
    level: 'CanNotDelete'
  }
}

// Create Log Analytics Workspace 

module loganalytics './modules/Microsoft.OperationalInsights/workspaces/deploy.bicep' = {
  name: '${sitecode}-la-azmanage-${environment}'
  scope: resourceGroup(azmanagerg.name)
  params: {
    logAnalyticsWorkspaceName: toLower('${sitecode}-la-azmanage-${environment}')
    dataRetention: 30
    location: location
    tags: resourceTags
    serviceTier: 'PerGB2018'
  }
}

// Create Azure Automation Account 

module azautomate './modules/Microsoft.Automation/automationAccounts/deploy.bicep' = {
  name: '${sitecode}-azautomate-${environment}'
  scope: resourceGroup(azmanagerg.name)
  params: {
    automationAccountName: toLower('${sitecode}-azautomate-${environment}')
    diagnosticLogsRetentionInDays: 30
    workspaceId: loganalytics.outputs.logAnalyticsResourceId
    skuName: 'Free'
    tags: resourceTags
  }
}

// Create Diagnostics Storage Account 

module azdiagnosticsstorage './modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
  name: '${sitecode}-azdiag-${environment}'
  scope: resourceGroup(azmanagerg.name)
  params: {
    name: toLower('azdiag${uniqueString(azmanagerg.outputs.resourceGroupResourceId)}')
    minimumTlsVersion: 'TLS1_2'
    deleteBlobsAfter: 60
    enableArchiveAndDelete: true
    storageAccountAccessTier: 'Hot'
    storageAccountSku: 'Standard_LRS'
    storageAccountKind: 'StorageV2'
    tags: resourceTags
    moveToArchiveAfter: 30
    allowBlobPublicAccess: false
  }
}

// Create Recovery Services Vault 

module azrecoveryservices './modules/Microsoft.RecoveryServices/vaults/deploy.bicep' = {
  name: 'azrecoveryservices'
  scope: resourceGroup(azbackuprg.name)
  params: {
    recoveryVaultName: toLower('${sitecode}-rsv-${environment}-${locationshort[location]}')
    vaultStorageType: 'GeoRedundant'
    tags: resourceTags

    backupPolicies: [
      {
        Name: 'Dev-VMBackupPolicy'
        properties: {
          backupManagementType: 'AzureIaasVM'
          instantRpRetentionRangeInDays: 2

          schedulePolicy: {
            scheduleRunFrequency: 'Daily'
            scheduleRunTimes: [
              '2021-09-05T21:00:00Z'
            ]
            schedulePolicyType: 'SimpleSchedulePolicy'
          }
          timeZone: 'New Zealand Standard Time'
          retentionPolicy: {
            dailySchedule: {
              retentionTimes: [
                '2021-09-05T21:00:00Z'
              ]
              retentionDuration: {
                count: 7
                durationType: 'Days'
              }
            }
            retentionPolicyType: 'LongTermRetentionPolicy'
          }
          weeklySchedule: {
            daysOfTheWeek: [
              'Sunday'
            ]
            retentionTimes: [
              '11/8/2021 1:30:00 PM'
            ]
            retentionDuration: {
              count: 4
              durationType: 'Weeks'
            }
          }
          monthlySchedule: {
            retentionScheduleFormatType: 'Daily'
            retentionScheduleDaily: {
              daysOfTheMonth: [
                {
                  date: 1
                  isLast: false
                }
              ]
            }
            retentionTimes: [
              '11/8/2021 1:30:00 PM'
            ]
            retentionDuration: {
              count: 12
              durationType: 'Months'
            }
          }
        }
        yearlySchedule: {
          retentionScheduleFormatType: 'Weekly'
          monthsOfYear: [
            'January'
          ]
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '11/8/2021 1:30:00 PM'
          ]
          retentionDuration: {
            count: 2
            durationType: 'Years'
          }
        }
      }
      {
        Name: 'Prod-VMBackupPolicy'
        properties: {
          backupManagementType: 'AzureIaasVM'
          instantRpRetentionRangeInDays: 5

          schedulePolicy: {
            scheduleRunFrequency: 'Daily'
            scheduleRunTimes: [
              '2021-09-05T21:00:00Z'
            ]
            schedulePolicyType: 'SimpleSchedulePolicy'
          }
          timeZone: 'New Zealand Standard Time'
          retentionPolicy: {
            dailySchedule: {
              retentionTimes: [
                '2021-09-05T21:00:00Z'
              ]
              retentionDuration: {
                count: 7
                durationType: 'Days'
              }
            }
            retentionPolicyType: 'LongTermRetentionPolicy'
          }
          weeklySchedule: {
            daysOfTheWeek: [
              'Sunday'
            ]
            retentionTimes: [
              '11/8/2021 1:30:00 PM'
            ]
            retentionDuration: {
              count: 4
              durationType: 'Weeks'
            }
          }
          monthlySchedule: {
            retentionScheduleFormatType: 'Daily'
            retentionScheduleDaily: {
              daysOfTheMonth: [
                {
                  date: 1
                  isLast: false
                }
              ]
            }
            retentionTimes: [
              '11/8/2021 1:30:00 PM'
            ]
            retentionDuration: {
              count: 12
              durationType: 'Months'
            }
          }
        }
        yearlySchedule: {
          retentionScheduleFormatType: 'Weekly'
          monthsOfYear: [
            'January'
          ]
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '11/8/2021 1:30:00 PM'
          ]
          retentionDuration: {
            count: 2
            durationType: 'Years'
          }
        }
      }
    ]
  }
}

//Create Azure Security Center

module azsecuritycenter './modules/Microsoft.Security/azureSecurityCenter/deploy.bicep' = {
  name: 'azsecuritycenter'
  scope: subscription()
  params: {
    workspaceId: loganalytics.outputs.logAnalyticsResourceId
    scope: 'ec66173a-1996-4503-a78c-0a17c567b3b0'
    armPricingTier: 'Free'
    autoProvision: 'On'
    dnsPricingTier: 'Free'
    keyVaultsPricingTier: 'Free'
    containerRegistryPricingTier: 'Free'
    openSourceRelationalDatabasesTier: 'Free'
    virtualMachinesPricingTier: 'Free'
    storageAccountsPricingTier: 'Free'
    sqlServerVirtualMachinesPricingTier: 'Free'
    kubernetesServicePricingTier: 'Free'
    appServicesPricingTier: 'Free'
    sqlServersPricingTier: 'Free'
    securityContactProperties: {
      contactEmail: contactEmail
      contactName: contactName
    }
  }
}
