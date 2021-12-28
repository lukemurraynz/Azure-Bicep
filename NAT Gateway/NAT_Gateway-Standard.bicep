//Target Scope is: Resource Group

targetScope = 'resourceGroup'

//Set Variables and Parameters

@allowed([
  'Prod'
  'Dev'
])
param environment string = 'Prod'
param location string = resourceGroup().location

param dateTime string = utcNow('d')
param resourceTags object = {
  Application: 'Azure NAT Gateway/Azure Network Management'
  CostCenter: 'Operational'
  CreationDate: dateTime
  Environment: environment
}

//// Resource Creation

/// Create - NAT Gateway

resource NATGW 'Microsoft.Network/natGateways@2021-03-01' = {
  name: 'aznatgw'
  tags: resourceTags

  location: location
  sku: {
    name: 'Standard'
  }

  properties: {
    idleTimeoutInMinutes: 4
  }
}
