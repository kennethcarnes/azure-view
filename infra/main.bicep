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
  functionAppKind: 'functionapp'
  storageAccountName: 'stazureviewtest001'
  appServicePlanName: 'asp-azure-view-test-001'
  logAnalyticsWorkspaceId: 'law-azure-view-test-001'
  cosmosDbAccountName: 'costab-azure-view-test-001'
  cosmosDbName: 'cosdb-azure-view-test-001'
  cosmosDbContainerName: 'coscont-azure-view-test-001'
} : {
  functionAppName: 'func-azure-view-prod-001'
  functionAppKind: 'functionapp'
  storageAccountName: 'stazureviewprod001'
  appServicePlanName: 'asp-azure-view-prod-001'
  logAnalyticsWorkspaceId: 'law-azure-view-prod-001'
  cosmosDbAccountName: 'costab-azure-view-prod-001'
  cosmosDbName: 'cosdb-azure-view-prod-001'
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
  }
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
    appConfigName: selectedBackendParams.functionAppName
    keyVaultName: selectedBackendParams.functionAppName
    logAnalyticsWorkspaceId: selectedBackendParams.functionAppName
    cosmosDbAccountName: selectedBackendParams.cosmosDbAccountName
    cosmosDbName: selectedBackendParams.cosmosDbName
    cosmosDbContainerName: selectedBackendParams.cosmosDbContainerName
  }
}
