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
    [string] $cosmosDbPartitionKey
)

# Fetch the Managed Identity Object ID for the Function App
$functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
$objectId = $functionApp.Identity.PrincipalId

# Set Key Vault permissions for this identity
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $objectId -PermissionsToSecrets get,list,set

# Output the Object ID for verification
Write-Host "Granted access to Object ID: $objectId"

# Update CosmosDB role (this assumes that role with name 'MyReadWriteRole' doesn't exist; otherwise, you might want to update it)
New-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName `
          -ResourceGroupName $resourceGroupName `
          -Type CustomRole -RoleName MyReadWriteRole `
          -DataAction @( `
            'Microsoft.DocumentDB/databaseAccounts/readMetadata',
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*', `
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/' + $cosmosDbContainerName) `
          -AssignableScope "/" 
