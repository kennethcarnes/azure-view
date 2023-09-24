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

    # Validate Cosmos DB Account exists
    $cosmosDbAccount = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName
    if (-not $cosmosDbAccount) {
        throw "Cosmos DB Account '$cosmosDbAccountName' does not exist in resource group '$resourceGroupName'."
    }

    # Define custom role for Cosmos DB
    $customRoleName = "FunctionAppCosmosDBRole"
    $customRoleActions = @( 
        'Microsoft.DocumentDB/databaseAccounts/readMetadata',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*',
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
    )

    # Create or update the custom role in Cosmos DB
    New-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName `
        -ResourceGroupName $resourceGroupName `
        -Type CustomRole -RoleName $customRoleName `
        -DataAction $customRoleActions `
        -AssignableScope "/" 
    Write-Host "Created/Updated custom role '$customRoleName' in Cosmos DB account '$cosmosDbAccountName'"

    # Assign the custom role to the managed identity of the Function App
    # Check if the role assignment already exists
    $existingRoleAssignment = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $customRoleName -Scope $cosmosDbAccount.Id -ErrorAction SilentlyContinue

    if ($null -eq $existingRoleAssignment) {
        New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $customRoleName -Scope $cosmosDbAccount.Id
        # Output for verification
        Write-Host "Assigned custom role '$customRoleName' to the managed identity of Function App '$functionAppName'"
    } else {
        Write-Host "The custom role '$customRoleName' is already assigned to the managed identity of Function App '$functionAppName'. No action needed."
    }
}
catch {
    Write-Error "Caught an exception: $($_.Exception.Message)"
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
    Write-Error "Script failed. Exiting with error code 1."
    exit 1
}
