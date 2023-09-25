# This script sets key-value pairs on an Azure App Configuration.

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$appConfigName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$swaName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$keyVaultName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$cosmosDbAccountName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$cosmosDbDatabaseName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$cosmosDbContainerName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$cosmosDbContainerPartitionKey
)

function ExitWithError {
    param (
        [string] $message
    )
    Write-Error $message
    exit 1
}

function Test-Parameters {
    param (
        [array] $parameters
    )

    foreach ($param in $parameters) {
        if (-not $param) {
            ExitWithError "One or more parameters are null or empty."
        }
    }
}

# Validate input parameters
Test-Parameters -parameters @($appConfigName, $swaName, $keyVaultName, $cosmosDbAccountName, 
                             $cosmosDbDatabaseName, $cosmosDbContainerName, $cosmosDbContainerPartitionKey)

$endpoint = "https://$appConfigName.azconfig.io"

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
    $label = $key 

    try {
        # Check if the key exists
        $existingKey = Get-AzAppConfigurationKeyValue -Endpoint $endpoint -Key $key -Label $label -ErrorAction SilentlyContinue

        if ($existingKey) {
            # If key exists, update it
            Set-AzAppConfigurationKeyValue -Endpoint $endpoint -Key $key -Label $label -Value $value
        } else {
            # If key doesn't exist, create it
            Add-AzAppConfigurationKeyValue -Endpoint $endpoint -Key $key -Label $label -Value $value
        }
    } catch {
        ExitWithError "Error while setting key-value for ${key}: $($_.Exception.Message)"
    }
}

Write-Output "All key-value pairs set successfully."
