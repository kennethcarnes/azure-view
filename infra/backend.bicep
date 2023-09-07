param location string
param runtime string
param functionAppName string
param functionAppKind string
param storageAccountName string
param storageAccountSkuName string
param storageAccountKind string
param appServicePlanName string
param storageAccountConnectionString string
param databaseAccountName string
param databaseAccountKind string
param databaseName string
param containerName string
param throughput int = 400

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
        { name: 'AzureWebJobsStorage', value: storageAccountConnectionString }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: runtime }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: databaseAccountName
  location: location
  kind: databaseAccountKind
  properties: {
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [{ locationName: location, failoverPriority: 0, isZoneRedundant: false }]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: databaseAccount
  name: databaseName
  properties: { resource: { id: databaseName } }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: containerName
  parent: database
  properties: {
    resource: {
      id: containerName
      partitionKey: { paths: ['/myPartitionKey'], kind: 'Hash' }
    }
    options: { throughput: throughput }
  }
}
