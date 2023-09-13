# Import Azure PowerShell Module if not already imported
Import-Module Az -ErrorAction SilentlyContinue

# Function to get Azure API Token
function Get-AzureApiToken ([string]$resource) {
    try {
        $response = Invoke-RestMethod -Method GET -Headers @{'Metadata'='true'} `
            -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$resource"
        return $response.access_token
    } catch {
        Write-Host "Error in fetching Azure API token: $_"
        throw $_
    }
}

# Function to get Secret from Azure Key Vault
function Get-SecretFromKeyVault([string]$vaultName, [string]$secretName) {
    $secret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName
    return $secret.SecretValueText
}

# Function to log messages
# Control the verbosity of your logs by updating the DEBUG environment
# variable in the Function App settings. Set it to "true" only when you
# need verbose logging for debugging, and switch it back to "false" to
# reduce log volume and associated costs.
function Write-Log([string]$message) {
    if ($env:DEBUG -eq "true") {
        Write-Host $message
    }
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
    # Fetch Azure Management Token
    Write-Log "Fetching Azure Management Token."
    $AzureMgmtToken = Get-AzureApiToken -resource 'https://management.azure.com/'
    if ($null -eq $AzureMgmtToken) {
        Write-Log "Failed to obtain Azure Management Token."
        exit 1
    }

    # Store this token in Azure Key Vault
    Write-Log "Storing Azure Management Token in Key Vault."
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'AzureManagementToken' -SecretValue (ConvertTo-SecureString $AzureMgmtToken -AsPlainText -Force)

    # Fetch data from Azure API
    Write-Log "Fetching data from Azure API."
    $apiResponse = Invoke-RestMethod -Method GET -Headers @{
        'Authorization' = "Bearer $AzureMgmtToken"
    } -Uri $azureManagementApiUrl

    # Fetch CosmosDB Token
    Write-Log "Fetching Cosmos DB Token."
    $CosmosDbToken = Get-AzureApiToken -resource "https://$cosmosDbAccountName.documents.azure.com/"

    # Prepare data for Cosmos DB
    Write-Log "Preparing data for Cosmos DB."
    $document = @{
        "id" = $documentId
        "apiData" = $apiResponse
    } | ConvertTo-Json

    # Write data into Cosmos DB
    Write-Log "Writing data into Cosmos DB."
    $cosmosDbEndpoint = "https://$cosmosDbAccountName.documents.azure.com:443/"
    $response = Invoke-RestMethod -Method POST -Uri "$cosmosDbEndpoint/dbs/$cosmosDbDatabase/colls/$cosmosDbCollection/docs" `
        -Headers @{
            'Authorization' = "Bearer $CosmosDbToken"
            'x-ms-version' = '2020-06-30'
            'Accept' = 'application/json'
        } `
        -Body $document

    Write-Log "Data successfully written to Cosmos DB."

} catch {
    Write-Log "An error occurred: $_"
    throw $_
}
