// Set the target scope for the ARM template
targetScope = 'resourceGroup'

// Shared parameters for both frontend and backend
param location string = 'westus2' // Azure location for deployment
param environmentType string = 'Test'
param branch string = 'main'
param repositoryToken string

// Choose frontend parameters based on environment type
var selectedFrontendParams = environmentType == 'Test' ? {
  swaName: 'swa-azure-view-test-001'
  swaSkuName: 'Free'
  swaSkuTier: 'Free'
  repositoryUrl: 'https://github.com/kennethcarnes/azure-view'
  repositoryToken: repositoryToken
} : {
  swaName: 'swa-azure-view-prod-001'
  swaSkuName: 'Basic'
  swaSkuTier: 'Basic'
  repositoryUrl: 'https://github.com/kennethcarnes/azure-view'
  repositoryToken: repositoryToken
}

// Choose backend parameters based on environment type
var selectedBackendParams = environmentType == 'Test' ? {
  functionAppName: 'func-azure-view-test-001'
  functionAppKind: 'functionapp'
  storageAccountName: 'stazureviewtest001'
  storageAccountSkuName: 'Standard_LRS'
  storageAccountKind: 'StorageV2'
  hostingPlanName: 'hostplan-azure-view-test-001'
  cosmosDbAccountName: 'costab-azure-view-test-001'
  cosmosDbAccountKind: 'GlobalDocumentDB'
  cosmosDbName: 'cosdb-azure-view-test-001'
  cosmosDbContainerName: 'coscont-azure-view-test-001'
  cosmosDbThroughput: 400
} : {
  functionAppName: 'func-azure-view-prod-001'
  functionAppKind: 'functionapp'
  storageAccountName: 'stazureviewprod001'
  storageAccountSkuName: 'Standard_LRS'
  storageAccountKind: 'Standard_LRS'
  hostingPlanName: 'hostplan-azure-view-prod-001'
  cosmosDbAccountName: 'costab-azure-view-prod-001'
  cosmosDbAccountKind: 'GlobalDocumentDB'
  cosmosDbName: 'cosdb-azure-view-prod-001'
  cosmosDbContainerName: 'coscont-azure-view-prod-001'
  cosmosDbThroughput: 400
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
    functionAppName: selectedBackendParams.functionAppName
    functionAppKind: selectedBackendParams.functionAppKind
    storageAccountName: selectedBackendParams.storageAccountName
    storageAccountSkuName: selectedBackendParams.storageAccountSkuName
    storageAccountKind: selectedBackendParams.storageAccountKind
    hostingPlanName: selectedBackendParams.hostingPlanName
    cosmosDbAccountName: selectedBackendParams.cosmosDbAccountName
    cosmosDbAccountKind: selectedBackendParams.cosmosDbAccountKind
    cosmosDbName: selectedBackendParams.cosmosDbName
    cosmosDbContainerName: selectedBackendParams.cosmosDbContainerName
    cosmosDbThroughput: selectedBackendParams.cosmosDbThroughput
  }
}
