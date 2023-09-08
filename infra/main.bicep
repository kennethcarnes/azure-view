@description('The URL to the product review API.')
param reviewApiUrl string

@secure()
@description('The API key to use when accessing the product review API.')
param reviewApiKey string

targetScope = 'resourceGroup'f

module frontend './frontend.bicep' = {
  name: 'frontendDeployment'
}

module backend './backend.bicep' = {
  name: 'backendDeployment'
}
