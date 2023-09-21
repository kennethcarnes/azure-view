# Input parameters
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $functionAppName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $cosmosDbAccountName
)

try {
    # Validate Function App exists
    $functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
    if (-not $functionApp) {
        throw "Function App '$functionAppName' does not exist in resource group '$resourceGroupName'."
    }

    # Fetch the Managed Identity Object ID for the Function App
    $objectId = $functionApp.Identity.PrincipalId

    # Validate that the Object ID is not null
    if ($null -eq $objectId) {
        throw "Managed Identity Object ID is null for Function App '$functionAppName'."
    }

    # Output the Object ID for verification
    Write-Host "Managed Identity Object ID: $objectId"

    # Define Cosmos DB actions for read and write
    $cosmosDbActions = @( 
        'Microsoft.DocumentDB/databaseAccounts/readMetadata',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
    )

    # Validate Cosmos DB Account exists
    $cosmosDbAccount = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName
    if (-not $cosmosDbAccount) {
        throw "Cosmos DB Account '$cosmosDbAccountName' does not exist in resource group '$resourceGroupName'."
    }

    # Create or update the custom role
    $roleName = "CosmosDbReadWriteRole"

    New-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName `
        -ResourceGroupName $resourceGroupName `
        -Type CustomRole -RoleName $roleName `
        -DataAction $cosmosDbActions `
        -AssignableScope "/" 

    # Output for verification
    Write-Host "Created/Updated role $roleName with ReadWrite permissions"
}
catch {
    Write-Error "Caught an exception: $($_.Exception.Message)"
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
    Write-Error "Script failed. Exiting with error code 1."
    exit 1
}
