using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    Headers = @{
        "Content-Type" = "application/json"
    }
})

# Function to log messages
# Control the verbosity of logs by updating the DEBUG environment variable in the Function App settings
function Write-Log([string]$message, [string]$level = 'info') {
    if ($level -eq 'debug' -and $env:DEBUG -ne "true") {
        return
    }
    Write-Host "{$level}: $message"
}

# Function to get Azure Management Token
function Get-AzureManagementToken {
    param ([string]$resourceUrl)
    $accessToken = (Get-AzAccessToken -ResourceUrl $resourceUrl).Token
    return $accessToken
}

# Main script execution starts here
try {
    Write-Log "Starting script execution."

    # Fetch CosmosDB details from Azure App Configuration
    $appConfigStoreName = $env:AppConfigStoreName
    $cosmosDbAccountName = (Get-AzAppConfigurationKey -Name $appConfigStoreName -Key 'CosmosDb:AccountName').Value
    $cosmosDbDatabase = (Get-AzAppConfigurationKey -Name $appConfigStoreName -Key 'CosmosDb:Database').Value
    $cosmosDbCollection = (Get-AzAppConfigurationKey -Name $appConfigStoreName -Key 'CosmosDb:Collection').Value

    # Fetch Azure Management Token
    Write-Log "Attempting to fetch Azure Management Token."
    $azureManagementResourceUrl = 'https://management.azure.com/'
    $AzureMgmtToken = Get-AzureManagementToken -resourceUrl $azureManagementResourceUrl
    if ($null -eq $AzureMgmtToken) {
        Write-Log "Failed to fetch Azure Management Token." 'error'
        exit 1
    }
    Write-Log "Fetched Azure Management Token successfully."

    # Fetch data from Azure API
    Write-Log "Attempting to fetch data from Azure API."
    $apiVersion = "2021-04-01"
    $uri = "$azureManagementResourceUrl/providers?api-version=$apiVersion"
    $response = Invoke-RestMethod -Method GET -Headers @{
        'Authorization' = "Bearer $AzureMgmtToken"
    } -Uri $uri
    $AzureMgmtApiResponse = $response | ConvertTo-Json -Depth 100
    Write-Log "Fetched data from Azure API successfully."

    # Fetch Cosmos DB Token
    Write-Log "Attempting to fetch Cosmos DB Token."
    $CosmosDbToken = Get-AzureManagementToken -resource "https://$cosmosDbAccountName.documents.azure.com/"
    if ($null -eq $CosmosDbToken) {
        Write-Log "Failed to fetch Cosmos DB Token." 'error'
        exit 1
    }
    Write-Log "Fetched Cosmos DB Token successfully."

    # Prepare and write data into Cosmos DB
    Write-Log "Preparing data for Cosmos DB."
    # If documentId is not passed, generate a GUID.
    if ($null -eq $documentId) {
        $documentId = [guid]::NewGuid().ToString()
    }
    $document = @{
        "id"      = $documentId
        "apiData" = $AzureMgmtApiResponse
    } | ConvertTo-Json
    Write-Log "Data prepared for Cosmos DB."

    Write-Log "Attempting to write data into Cosmos DB."
    $cosmosDbEndpoint = "https://$cosmosDbAccountName.documents.azure.com:443/"
    $response = Invoke-RestMethod -Method POST -Uri "$cosmosDbEndpoint/dbs/$cosmosDbDatabase/colls/$cosmosDbCollection/docs" `
        -Headers @{
        'Authorization' = "Bearer $CosmosDbToken"
        'x-ms-version'  = '2020-06-30'
        'Accept'        = 'application/json'
    } `
        -Body $document
    Write-Log "Data written into Cosmos DB successfully."
}
catch {
    Write-Log "An error occurred: $($_.InvocationInfo.MyCommand)" 'error'
    Write-Log "Error details: $($_.Exception.Message)" 'error'
    Write-Log "Exiting with failure status." 'error'
    exit 1
}
