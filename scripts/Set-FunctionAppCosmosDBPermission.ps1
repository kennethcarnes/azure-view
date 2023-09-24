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

    # Check if the role already exists
    $existingRole = Get-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName -ResourceGroupName $resourceGroupName -RoleName $customRoleName -ErrorAction SilentlyContinue

    if ($null -eq $existingRole) {
        New-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName `
            -ResourceGroupName $resourceGroupName `
            -Type CustomRole -RoleName $customRoleName `
            -DataAction $customRoleActions `
            -AssignableScope "/" 
        Write-Host "Created custom role '$customRoleName' in Cosmos DB account '$cosmosDbAccountName'"
    } else {
        Write-Host "Custom role '$customRoleName' already exists in Cosmos DB account '$cosmosDbAccountName'. No action needed."
    }

    # Validation for role creation
    $createdRole = Get-AzCosmosDBSqlRoleDefinition -AccountName $cosmosDbAccountName -ResourceGroupName $resourceGroupName -RoleName $customRoleName
    if (-not $createdRole) {
        throw "Failed to retrieve the custom role '$customRoleName' in Cosmos DB account '$cosmosDbAccountName'"
    }

    # Retry logic for assigning the custom role
    $maxRetries = 5
    $retryCount = 0
    $roleAssigned = $false

    do {
        try {
            # Check if the role assignment already exists
            $existingRoleAssignment = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $customRoleName -Scope $cosmosDbAccount.Id -ErrorAction SilentlyContinue

            if ($null -eq $existingRoleAssignment) {
                New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $customRoleName -Scope $cosmosDbAccount.Id
                Write-Host "Assigned custom role '$customRoleName' to the managed identity of Function App '$functionAppName'"
                $roleAssigned = $true
            } else {
                Write-Host "The custom role '$customRoleName' is already assigned to the managed identity of Function App '$functionAppName'. No action needed."
                $roleAssigned = $true
            }
        } catch {
            $retryCount++
            if ($retryCount -ge $maxRetries) {
                throw "Failed to assign the custom role after $maxRetries attempts. Exiting."
            }
            Write-Host "Attempt $retryCount to assign the role failed. Retrying in 30 seconds..."
            Start-Sleep -Seconds 30
        }
    } while (-not $roleAssigned)

}
catch {
    Write-Error "Caught an exception: $($_.Exception.Message)"
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
    Write-Error "Script failed. Exiting with error code 1."
    exit 1
}
