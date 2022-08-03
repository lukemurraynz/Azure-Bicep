targetScope = 'subscription'

// If an environment is set up (dev, test, prod...), it is used in the application name
param environment string = 'dev'
param applicationName string = 'demo-3463-9669'
param location string = 'australiaeast'
var instanceNumber = '001'

var defaultTags = {
  'environment': environment
  'application': applicationName
  'nubesgen-version': '0.13.0'
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${applicationName}-${instanceNumber}'
  location: location
  tags: defaultTags
}

module instrumentation 'modules/application-insights/app-insights.bicep' = {
  name: 'instrumentation'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    instanceNumber: instanceNumber
    resourceTags: defaultTags
  }
}

module blobStorage 'modules/storage-blob/storage.bicep' = {
  name: 'storage'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    resourceTags: defaultTags
    instanceNumber: instanceNumber
  }
}

module mongoDb 'modules/cosmosdb-mongodb/cosmosdb-mongodb.bicep' = {
  name: 'mongoDb'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    instanceNumber: instanceNumber
    tags: defaultTags
  }
}

module database 'modules/sql-server/sql-azure.bicep' = {
  name: 'sqlDb'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    tags: defaultTags
    instanceNumber: instanceNumber
  }
}

module redis 'modules/redis/redis.bicep' = {
  name: 'redis'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    resourceTags: defaultTags
    instanceNumber: instanceNumber
  }
}

var applicationEnvironmentVariables = [
// You can add your custom environment variables here
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: instrumentation.outputs.appInsightsInstrumentationKey
      }
      {
        name: 'azure_storage_account_name'
        value: blobStorage.outputs.storageAccountName
      }
      {
        name: 'azure_storage_account_key'
        value: blobStorage.outputs.storageKey
      }
      {
        name: 'azure_storage_connectionstring'
        value: 'DefaultEndpointsProtocol=https;AccountName=${blobStorage.outputs.storageAccountName};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${blobStorage.outputs.storageKey}'
      }
      {
        name: 'SPRING_DATASOURCE_URL'
        value: 'jdbc:sqlserver://${database.outputs.db_url}'
      }
    {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: database.outputs.db_username
    }
    {
        name: 'SPRING_DATASOURCE_PASSWORD'
        value: database.outputs.db_password
    }
  {
    name: 'SPRING_DATA_MONGODB_URI'
    value: mongoDb.outputs.azure_cosmosdb_mongodb_uri
  }
  {
    name: 'SPRING_DATA_MONGODB_DATABASE'
    value: mongoDb.outputs.azure_cosmosdb_mongodb_database
  }
      {
        name: 'SPRING_REDIS_HOST'
        value: redis.outputs.redis_host
      }
      {
        name: 'SPRING_REDIS_PASSWORD'
        value: redis.outputs.redis_key
      }
      {
        name: 'SPRING_REDIS_PORT'
        value: '6380'
      }
      {
        name: 'SPRING_REDIS_SSL'
        value: 'true'
      }
]

module function 'modules/function/function.bicep' = {
  name: 'function'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    resourceTags: defaultTags
    instanceNumber: instanceNumber
    environmentVariables: applicationEnvironmentVariables
  }
}
