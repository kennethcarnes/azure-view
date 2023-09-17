param location string
param functionAppName string
param storageAccountName string
param appServicePlanName string
param keyVaultName string
param appConfigName string
param tenantId string
param cosmosDbAccountName string
param cosmosDbName string
param cosmosDbContainerName string
param logAnalyticsWorkspaceName string

// Outputs
output cosmosDbAccountNameOutput string = cosmosDbAccountName
output cosmosDbNameOutput string = cosmosDbName
output cosmosDbContainerNameOutput string = cosmosDbContainerName




// https://learn.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code?tabs=bicep#deploy-on-consumption-plan
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        { name: 'AzureWebJobsStorage', value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'PowerShell' }
        { name: 'APPINSIGHTS_INSTRUMENTATIONKEY', value: applicationInsights.properties.InstrumentationKey}
        { name: 'DEBUG', value: 'false' }  // Control debug logs
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
  }
}

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: appConfigName
  location: location
  sku: {
    name: 'free'
  }
}

// Azure Monitor resource logs for Azure Storage
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
    retentionInDays: 30  // 30 day retention for cost-efficiency
    workspaceCapping: {
      dailyQuotaGb: json('0.025') // Capped for cost-efficiency
    }
  }
}

resource storageDataPlaneLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-logs'
  scope: blobService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'StorageWrite'
        enabled: false  // Disable by default, enable only if necessary
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// Application Insights with minimal settings for cost-efficiency
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${functionAppName}-appinsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    // Include more properties here as needed
    RetentionInDays: 30  // 30 day retention for cost-efficiency
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Eventual'
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
  }
}
