# Import Azure PowerShell Module if not already imported
Import-Module Az -ErrorAction SilentlyContinue

# Input parameters
param(
    [string] $resourceGroupName,
    [string] $functionAppName,
    [string] $keyVaultName,
    [string] $cosmosDbAccountName,
    [string] $cosmosDbDatabaseName,
    [string] $cosmosDbContainerName
)

# Fetch the Managed Identity Object ID for the Function App
$functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
$objectId = $functionApp.Identity.PrincipalId

# Set Key Vault permissions for this identity
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $objectId -PermissionsToSecrets get,list,set

# Output the Object ID for verification
Write-Host "Granted access to Object ID: $objectId"

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
