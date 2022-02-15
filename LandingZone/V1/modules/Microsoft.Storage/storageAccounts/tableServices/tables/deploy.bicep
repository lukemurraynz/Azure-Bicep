@maxLength(24)
@description('Required. Name of the Storage Account.')
param storageAccountName string

@description('Required. Name of the table.')
param name string

@description('Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered')
param cuaId string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-06-01' = {
  name: '${storageAccountName}/default/${name}'
}


output tableName string = table.name

output tableResourceId string = table.id

output tableResourceGroup string = resourceGroup().name
