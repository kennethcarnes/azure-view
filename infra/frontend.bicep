param swaName string
param location string
param swaSkuName string
param swaSkuTier string
param repositoryUrl string
param branch string
param apimName string
param apimSkuName string = 'Consumption' 
@secure()
param repositoryToken string

// Outputs
output swaName string = swa.name
output swaUrl string = swa.properties.defaultHostname
output apimName string = apim.name
output apimUrl string = apim.properties.gatewayRegionalUrl

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
      appLocation: 'app'
      apiLocation: 'api'
      appArtifactLocation: ''
    }
  }
}

resource apim 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apimName
  location: location
  sku: {
    capacity: 0 
    name: apimSkuName
  }
  properties: {
    publisherName: 'Kenneth Carnes'
    publisherEmail: 'kc@kennethcarnes.com'
  }
  identity: {
    type: 'SystemAssigned'
  }  
}

resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  parent: apim
  name: 'api-azure-view'
  properties: {
    path: 'api'
    protocols: [
      'https'
    ]
  }
}

resource apiIngestOperation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: api
  name: 'ingest'
  properties: {
    displayName: 'ingest'
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

resource apiRetrieveOperation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: api
  name: 'retrieve'
  properties: {
    displayName: 'retrieve'
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


resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-04-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '''<policies>
              <inbound>
                <cors>
                  <allowed-origins>
                    <origin>https://${swa.properties.defaultHostname}</origin>
                  </allowed-origins>
                  <allowed-methods>
                    <method>GET</method>
                    <method>POST</method>
                  </allowed-methods>
                </cors>
              </inbound>
            </policies>'''
  }
}
