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
function Write-Log([string]$message, [string]$level = 'info') {
    if ($level -eq 'debug' -and $env:DEBUG -ne "true") {
        return
    }
    Write-Host "{$level}: $message"
}

# Parameter block to accept inputs
param(
    [string]$cosmosDbAccountName,
    [string]$cosmosDbKey,  # Primary or secondary key for Cosmos DB
    [string]$cosmosDbDatabase,
    [string]$cosmosDbCollection
)

# Main script execution starts here
try {
    Write-Log "Starting function execution."

    # Prepare the query to fetch latest data
    $query = @{
        "query" = "SELECT * FROM c ORDER BY c.timestamp DESC OFFSET 0 LIMIT 1"
    } | ConvertTo-Json

    # Create a hashed authorization token
    $verb = "POST"
    $resourceType = "docs"
    $resourceLink = "dbs/$cosmosDbDatabase/colls/$cosmosDbCollection/docs"
    $date = $(Get-Date).ToUniversalTime().ToString('R')
    $masterKey = [System.Convert]::FromBase64String($cosmosDbKey)
    $hashPayload = "$verb`n$resourceType`n$resourceLink`n$date`n`n"
    $hash = New-Object System.Security.Cryptography.HMACSHA256
    $hash.Key = $masterKey
    $signature = $hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($hashPayload))
    $signature = [System.Convert]::ToBase64String($signature)
    $authHeader = "type=master&ver=1.0&sig=$signature"

    # Execute the query
    $cosmosDbEndpoint = "https://$cosmosDbAccountName.documents.azure.com:443/"
    $uri = "$cosmosDbEndpoint/dbs/$cosmosDbDatabase/colls/$cosmosDbCollection/docs"
    $response = Invoke-RestMethod -Method POST -Uri $uri `
        -Headers @{
        'Authorization' = $authHeader
        'x-ms-date' = $date
        'x-ms-version' = '2020-06-30'
    } `
        -Body $query

    # Extract the result and log
    $result = $response | ConvertTo-Json -Depth 100
    Write-Log "Fetched latest data from Cosmos DB: $result"
}
catch {
    Write-Log "An error occurred: $($_.InvocationInfo.MyCommand)" 'error'
    Write-Log "Error details: $($_.Exception.Message)" 'error'
    Write-Log "Exiting with failure status." 'error'
    exit 1
}
