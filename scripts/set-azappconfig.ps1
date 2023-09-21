param(
    [Parameter(Mandatory=$true)]
    [string]$appConfigName,

    [Parameter(Mandatory=$true)]
    [string]$swaName,

    [Parameter(Mandatory=$true)]
    [string]$keyVaultName,

    [Parameter(Mandatory=$true)]
    [string]$cosmosDbAccountName,

    [Parameter(Mandatory=$true)]
    [string]$cosmosDbDatabaseName,

    [Parameter(Mandatory=$true)]
    [string]$cosmosDbContainerName,

    [Parameter(Mandatory=$true)]
    [string]$cosmosDbContainerPartitionKey
)

# Function to Test parameters
function Test-Parameters {
    $params = @($appConfigName, $swaName, $keyVaultName, $cosmosDbAccountName, 
               $cosmosDbDatabaseName, $cosmosDbContainerName, $cosmosDbContainerPartitionKey)
               
    foreach ($param in $params) {
        if (-not $param) {
            Write-Error "One or more parameters are null or empty."
            exit 1
        }
    }
}

# Call the validation function
Test-Parameters

# Proceed with the rest of the script
# Install the necessary module
Install-Module -Name Az.AppConfiguration -Force -Scope CurrentUser -SkipPublisherCheck

$endpoint = "https://$($appConfigName).azconfig.io"

$keyValuePairs = @{
    "swaName"                        = $swaName
    "keyVaultName"                   = $keyVaultName
    "cosmosDbAccountName"            = $cosmosDbAccountName
    "cosmosDbDatabaseName"           = $cosmosDbDatabaseName
    "cosmosDbContainerName"          = $cosmosDbContainerName
    "cosmosDbContainerPartitionKey"  = $cosmosDbContainerPartitionKey
}

foreach ($key in $keyValuePairs.Keys) {
    $value = $keyValuePairs[$key]
    $label = $key  # You can choose either $key or $value depending on your needs
    
    try {
        Set-AzAppConfigurationKeyValue -Endpoint $endpoint -Key $key -Label $label -Value $value
    } catch {
        Write-Error "Error while setting key-value for ${key}: $_"
        exit 1
    }
}

Write-Output "All key-value pairs set successfully."
