// Set the target scope for the ARM template
targetScope = 'resourceGroup'

// Shared parameters for both frontend and backend
param location string = 'centralus' // Azure location for deployment
param environmentType string = 'Test'
param branch string = 'main'
param repositoryToken string
param tenantId string

// Choose frontend parameters based on environment type
var selectedFrontendParams = environmentType == 'Test' ? {
  swaName: 'swa-azure-view-test-001'
  swaSkuName: 'Free'
  swaSkuTier: 'Free'
  repositoryUrl: 'https://github.com/kennethcarnes/azure-view'
  repositoryToken: repositoryToken
} : {
  swaName: 'swa-azure-view-prod-001'
  swaSkuName: 'Standard'
  swaSkuTier: 'Standard'
  repositoryUrl: 'https://github.com/kennethcarnes/azure-view'
  repositoryToken: repositoryToken
}

// Choose backend parameters based on environment type
var selectedBackendParams = environmentType == 'Test' ? {
  functionAppName: 'func-azure-view-test-001'
  storageAccountName: 'stazureviewtest001'
  appServicePlanName: 'asp-azure-view-test-001'
  logAnalyticsWorkspaceName: 'law-azure-view-test-001'
  keyvaultName: 'kv-azure-view-test-001'
  appConfigName: 'appcs-azure-view-test-001'
  appInsightsName: 'appi-azure-view-test-001'
  cosmosDbAccountName: 'costab-azure-view-test-001'
  cosmosDbDatabaseName: 'cosdb-azure-view-test-001'
  cosmosDbContainerName: 'coscont-azure-view-test-001'
  cosmosDbContainerPartitionKey: '/resourceType'
} : {
  functionAppName: 'func-azure-view-prod-001'
  storageAccountName: 'stazureviewprod001'
  appServicePlanName: 'asp-azure-view-prod-001'
  logAnalyticsWorkspaceName: 'law-azure-view-prod-001'
  keyvaultName: 'kv-azure-view-prod-001'
  appConfigName: 'appcs-azure-view-prod-001'
  appInsightsName: 'appi-azure-view-prod-001'
  cosmosDbAccountName: 'costab-azure-view-prod-001'
  cosmosDbDatabaseName: 'cosdb-azure-view-prod-001'
  cosmosDbContainerName: 'coscont-azure-view-prod-001'
  cosmosDbContainerPartitionKey: '/resourceType'
}

// Deploy frontend module
module frontend './frontend.bicep' = {
  name: 'frontendDeployment'
  params: {
    location: location
    branch: branch
    swaName: selectedFrontendParams.swaName
    swaSkuName: selectedFrontendParams.swaSkuName
    swaSkuTier: selectedFrontendParams.swaSkuTier
    repositoryUrl: selectedFrontendParams.repositoryUrl
    repositoryToken: selectedFrontendParams.repositoryToken
  }
}

// Deploy backend module
module backend './backend.bicep' = {
  name: 'backendDeployment'
  params: {
    location: location
    tenantId: tenantId
    cosmosDbContainerPartitionKey: selectedBackendParams.cosmosDbContainerPartitionKey
    functionAppName: selectedBackendParams.functionAppName
    storageAccountName: selectedBackendParams.storageAccountName
    appServicePlanName: selectedBackendParams.appServicePlanName
    appConfigName: selectedBackendParams.appConfigName
    keyVaultName: selectedBackendParams.keyVaultName
    logAnalyticsWorkspaceName: selectedBackendParams.logAnalyticsWorkspaceName
    appInsightsName: selectedBackendParams.appInsightsName
    cosmosDbAccountName: selectedBackendParams.cosmosDbAccountName
    cosmosDbDatabaseName: selectedBackendParams.cosmosDbDatabaseName
    cosmosDbContainerName: selectedBackendParams.cosmosDbContainerName
  }
}

// Outputs
output swaNameOutput string = frontend.outputs.swaName
output functionAppNameOutput string = backend.outputs.functionAppName
output cosmosDbAccountNameOutput string = backend.outputs.cosmosDbAccountName
output cosmosDbDatabaseNameOutput string = backend.outputs.cosmosDbDatabaseName
output cosmosDbContainerNameOutput string = backend.outputs.cosmosDbContainerName
output cosmosDbContainerPartitionKeyOutput string = backend.outputs.cosmosDbContainerPartitionKey
