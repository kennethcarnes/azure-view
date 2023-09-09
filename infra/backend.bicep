param location string
param functionAppName string
param functionAppKind string
param storageAccountName string
param storageAccountSkuName string
param storageAccountKind string
param appServicePlanName string
param cosmosDbAccountName string
param cosmosDbAccountKind string
param cosmosDbName string
param cosmosDbContainerName string
param cosmosDbThroughput int

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: { name: storageAccountSkuName }
  kind: storageAccountKind
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: functionAppKind
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
    siteConfig: {
      appSettings: [
        { name: 'AzureWebJobsStorage', value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'PowerShell' }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: cosmosDbAccountName
  location: location
  kind: cosmosDbAccountKind
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [{
      locationName: location
      failoverPriority: 0
      isZoneRedundant: false
    }]
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosDbAccount
  name: cosmosDbName
  properties: {
    resource: {
      id: cosmosDbName
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: cosmosDbContainerName
  parent: cosmosDb
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [ '/resourceType' ]
      }
    }
    options: { throughput: cosmosDbThroughput }
  }
}
