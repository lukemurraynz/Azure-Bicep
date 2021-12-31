param AppServiceName string = 'WebAppName'
param AppServicePlanName string = 'ASP-WebApp'
var location = resourceGroup().location
resource AppServicePlanName_resource 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: AppServicePlanName
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  kind: 'app'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource AppServiceName_resource 'Microsoft.Web/sites@2021-02-01' = {
  name: AppServiceName

  location: location
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: 'webappnametest.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'webappnametest.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: AppServicePlanName_resource.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: true
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource AppServiceName_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2021-02-01' = {
  parent: AppServiceName
_resource
  name: 'ftp'
  location: location
  properties: {
    allow: true
  }
}

resource AppServiceName_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2021-02-01' = {
  parent: AppServiceName
_resource
  name: 'scm'
  location: location
  properties: {
    allow: true
  }
}

resource AppServiceName_web 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: AppServiceName
_resource
  name: 'web'
  location: location
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v6.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$WebAppNametest'
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: true
    autoHealRules: {
      triggers: {
        privateBytesInKB: 0
        statusCodes: [
          {
            status: 500
            subStatus: 0
            win32Status: 0
            count: 70
            timeInterval: '00:01:00'
          }
        ]
        slowRequestsWithPath: []
        statusCodesRange: []
      }
      actions: {
        actionType: 'Recycle'
        minProcessExecutionTime: '01:00:00'
      }
    }
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.0'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    websiteTimeZone: 'New Zealand Standard Time'
    minimumElasticInstanceCount: 1
    azureStorageAccounts: {}
  }
}

resource AppServiceName_AppServiceName_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2021-02-01' = {
  name: '${AppServiceName}.azurewebsites.net'
  location: location
  properties: {
    siteName: 'WebAppNametest'
    hostNameType: 'Verified'
  }
}


output url string = AppServiceName_AppServiceName_azurewebsites_net.name
