# Function to log messages
# Control the verbosity of logs by updating the DEBUG environment variable in the Function App settings
function Write-Log([string]$message, [string]$level = 'info') {
    if ($level -eq 'debug' -and $env:DEBUG -ne "true") {
        return
    }
    Write-Host "{$level}: $message"
}

# Import or Install Azure PowerShell Module if not already imported
Install-Module -Name Az -AllowClobber -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction SilentlyContinue
Import-Module Az -ErrorAction SilentlyContinue

# Function to get Azure Management Token
function Get-AzureManagementToken {
    param ([string]$resourceUrl)
    $accessToken = Get-AzAccessToken -ResourceUrl $resourceUrl
    return $accessToken
}

# Parameter block to accept inputs
param(
    [string]$keyVaultName,
    [string]$appConfigName,
    [string]$azureManagementApiUrl,
    [string]$cosmosDbAccountName,
    [string]$cosmosDbDatabase,
    [string]$cosmosDbCollection,
    [string]$documentId
)

# Main script execution starts here
try {
    Write-Log "Starting script execution."

    $azureManagementResourceUrl = 'https://management.azure.com/'

    # Fetch Azure Management Token
    Write-Log "Attempting to fetch Azure Management Token."
    $AzureMgmtToken = Get-AzureManagementToken -resourceUrl $azureManagementResourceUrl
    if ($null -eq $AzureMgmtToken) {
        Write-Log "Failed to fetch Azure Management Token." 'error'
        exit 1
    }
    Write-Log "Fetched Azure Management Token successfully."

    # Store Azure Management Token in Key Vault
    Write-Log "Attempting to store Azure Management Token in Key Vault."
    $secureAzureMgmtToken = ConvertTo-SecureString $AzureMgmtToken -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'AzureManagementToken' -SecretValue $secureAzureMgmtToken
    Write-Log "Stored Azure Management Token in Key Vault successfully."

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

    # Store Cosmos DB Token in Key Vault
    Write-Log "Attempting to store Cosmos DB Token in Key Vault."
    $secureCosmosDbToken = ConvertTo-SecureString $CosmosDbToken -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'CosmosDbToken' -SecretValue $secureCosmosDbToken
    Write-Log "Stored Cosmos DB Token in Key Vault successfully."

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
