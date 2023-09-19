# Import Azure PowerShell Module if not already imported
Import-Module Az -ErrorAction SilentlyContinue

# Input parameters
param(
    [string] $resourceGroupName,
    [string] $functionAppName,
    [string] $keyVaultName,
    [string] $cosmosDbAccountName,
    [string] $cosmosDbDatabaseName,
    [string] $cosmosDbContainerName,
    [string] $cosmosDbContainerPartitionKey,
    [string] $cosmosDbPermissionType  # Add a parameter for permission type (e.g., "read" or "write")
)

# Fetch the Managed Identity Object ID for the Function App
$functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
$objectId = $functionApp.Identity.PrincipalId

# Set Key Vault permissions for this identity
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $objectId -PermissionsToSecrets get,list,set

# Output the Object ID for verification
Write-Host "Granted access to Object ID: $objectId"

# Define Cosmos DB actions based on permission type
$cosmosDbActions = @()

if ($cosmosDbPermissionType -eq "read") {
    # Define read actions
    $cosmosDbActions = @( `
        'Microsoft.DocumentDB/databaseAccounts/readMetadata',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/' + $cosmosDbContainerName + '/read'
    )
}
elseif ($cosmosDbPermissionType -eq "write") {
    # Define write actions
    $cosmosDbActions = @( `
        'Microsoft.DocumentDB/databaseAccounts/readMetadata',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/' + $cosmosDbContainerName + '/*'
    )
}

# Create custom roles based on permission type
if ($cosmosDbPermissionType -eq "read") {
    $roleName = "CosmosDbReadRole"
}
elseif ($cosmosDbPermissionType -eq "write") {
    $roleName = "CosmosDbWriteRole"
}

# Update CosmosDB role (this assumes that the role doesn't exist; otherwise, you might want to update it)
New-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName `
    -ResourceGroupName $resourceGroupName `
    -Type CustomRole -RoleName $roleName
    -DataAction $cosmosDbActions `
    -AssignableScope "/" 
