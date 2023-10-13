// Parameters for the Bicep template
param swaName string          // Name of the Static Web App
param location string         // Azure region for deployment
param swaSkuName string       // SKU name for the Static Web App
param swaSkuTier string       // SKU tier for the Static Web App
param repositoryUrl string    // Repository URL for the source code of the web app
param branch string           // Branch to use from the repository
param apimName string         // Name of the Azure API Management service
@secure()
param repositoryToken string  // Secure token for accessing the repository

// Outputs after the template is deployed
output swaName string = swa.name
output swaUrl string = swa.properties.defaultHostname
output apimName string = apim.name
output apimUrl string = apim.properties.gatewayUrl

// Resource definition for Static Web App
resource swa 'Microsoft.Web/staticSites@2022-03-01' = {
  name: swaName
  location: location
  sku: {
    name: swaSkuName
    tier: swaSkuTier
  }
  properties: {
    repositoryUrl: repositoryUrl 
    branch: branch
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: 'app'                  // Location of the web app
      apiLocation: 'api'                  // API location
      appArtifactLocation: ''             // Location for build artifacts (empty here)
    }
  }
}

// Resource definition for Azure API Management service
resource apim 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: apimName
  location: location
  sku: {
    capacity: 0 
    name: 'Consumption'
  }
  properties: {
    publisherName: 'Kenneth Carnes'
    publisherEmail: 'kc@kennethcarnes.com'
  }
  identity: {
    type: 'SystemAssigned'
  }  
}

// Resource definition for API within Azure API Management
resource api 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  parent: apim
  name: 'api'
  properties: {
    displayName: 'API'
    path: 'api'
    protocols: [
      'https'
    ]
  }
}

// Resource definition for an "ingest" operation within the API
resource apiIngestOperation 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  parent: api
  name: 'ingest'
  properties: {
    displayName: 'Ingest Data'
    method: 'GET'
    urlTemplate: '/ingest'
    request: {
      description: 'Request to ingest data'
      queryParameters: [
        {
          name: 'filter'
          type: 'string'
          required: false
        }
      ]
      headers: [
        {
          name: 'x-api-key'
          type: 'string'
          required: true
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Successfully retrieved results'
      }
    ]
  }
}

// Resource definition for a "retrieve" operation within the API
resource apiRetrieveOperation 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  parent: api
  name: 'retrieve'
  properties: {
    displayName: 'Retrieve Data'
    method: 'GET'
    urlTemplate: '/retrieve'
    request: {
      description: 'Request to retrieve data'
      queryParameters: [
        {
          name: 'filter'
          type: 'string'
          required: false
        }
      ]
      headers: [
        {
          name: 'x-api-key'
          type: 'string'
          required: true
        }
      ]
    }
  }
}

// // Resource definition for a policy for the API
// resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
//   parent: api
//   name: 'policy'
//   properties: {
//     format: 'rawxml'
//     value: '''<policies>
//               <inbound>
//                 <cors>
//                   <allowed-origins>
//                     <origin>https://${swa.properties.defaultHostname}</origin>
//                   </allowed-origins>
//                   <allowed-methods>
//                     <method>GET</method>
//                   </allowed-methods>
//                 </cors>
//               </inbound>
//             </policies>'''
//   }
// }
