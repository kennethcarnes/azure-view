targetScope = 'resourceGroup'

module frontend './frontend.bicep' = {
  name: 'frontendDeployment'
}

module backend './backend.bicep' = {
  name: 'backendDeployment'
}
