# Input parameters
param(
    [string] $resourceGroupName,
    [string] $functionAppName,
    [string] $cosmosDbAccountName,
    [string] $cosmosDbDatabaseName,
    [string] $cosmosDbContainerName
)

try {
    # Fetch the Managed Identity Object ID for the Function App
    $functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
    $objectId = $functionApp.Identity.PrincipalId

    # Validate that the Object ID is not null
    if ($null -eq $objectId) {
        throw "Managed Identity Object ID is null."
    }

    # Output the Object ID for verification
    Write-Host "Managed Identity Object ID: $objectId"

    # Define Cosmos DB actions for read and write
    $cosmosDbActions = @( 
        'Microsoft.DocumentDB/databaseAccounts/readMetadata',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
    )

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
    Write-Host "Caught an exception:"
    Write-Host $_.Exception.Message
    Write-Host "StackTrace:"
    Write-Host $_.Exception.StackTrace
    Write-Host "Script failed. Exiting with error code 1."
    exit 1
}
