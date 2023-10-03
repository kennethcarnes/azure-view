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
  apimName: 'apim-azure-view-test-001'
} : {
  swaName: 'swa-azure-view-prod-001'
  swaSkuName: 'Standard'
  swaSkuTier: 'Standard'
  repositoryUrl: 'https://github.com/kennethcarnes/azure-view'
  repositoryToken: repositoryToken
  apimName: 'apim-azure-view-prod-001'
}

// Choose backend parameters based on environment type
var selectedBackendParams = environmentType == 'Test' ? {
  functionAppName: 'funcapp-azure-view-test-001'
  storageAccountName: 'stazureviewtest001'
  appServicePlanName: 'asp-azure-view-test-001'
  logAnalyticsWorkspaceName: 'law-azure-view-test-001'
  keyvaultName: 'kv-azure-view-test-001'
  appConfigName: 'appcs-azure-view-test-001'
  appInsightsName: 'appi-azure-view-test-001'
  cosmosDbAccountName: 'costab-azure-view-test-001'
  cosmosDbDatabaseName: 'cosdb-azure-view-test-001'
  cosmosDbContainerName: 'coscont-azure-view-test-001'
} : {
  functionAppName: 'funcapp-azure-view-prod-001'
  storageAccountName: 'stazureviewprod001'
  appServicePlanName: 'asp-azure-view-prod-001'
  logAnalyticsWorkspaceName: 'law-azure-view-prod-001'
  keyvaultName: 'kv-azure-view-prod-001'
  appConfigName: 'appcs-azure-view-prod-001'
  appInsightsName: 'appi-azure-view-prod-001'
  cosmosDbAccountName: 'costab-azure-view-prod-001'
  cosmosDbDatabaseName: 'cosdb-azure-view-prod-001'
  cosmosDbContainerName: 'coscont-azure-view-prod-001'
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
    apimName: selectedFrontendParams.apimName
  }
  dependsOn: [
    backend
  ]
}

// Deploy backend module
module backend './backend.bicep' = {
  name: 'backendDeployment'
  params: {
    location: location
    tenantId: tenantId
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
output swaName string = frontend.outputs.swaName
output swaUrl string = frontend.outputs.swaUrl
output apimName string = frontend.outputs.apimName
output apimUrl string = frontend.outputs.apimUrl
output functionAppName string = backend.outputs.functionAppName
output keyVaultName string = backend.outputs.keyVaultName
output appConfigName string = backend.outputs.appConfigName
output cosmosDbAccountName string = backend.outputs.cosmosDbAccountName
output cosmosDbDatabaseName string = backend.outputs.cosmosDbDatabaseName
output cosmosDbContainerName string = backend.outputs.cosmosDbContainerName
output cosmosDbContainerPartitionKey string = backend.outputs.cosmosDbContainerPartitionKey
