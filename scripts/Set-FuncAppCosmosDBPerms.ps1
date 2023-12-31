# This script assigns the "DocumentDB Account Contributor" role to a Function App's Managed Identity for a Cosmos DB account.

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

    # Use the built-in role name "DocumentDB Account Contributor"
    $builtinRoleName = "DocumentDB Account Contributor"

    # Check if the role assignment already exists
    $existingRoleAssignment = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $builtinRoleName -Scope $cosmosDbAccount.Id -ErrorAction SilentlyContinue

    if ($null -eq $existingRoleAssignment) {
        New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $builtinRoleName -Scope $cosmosDbAccount.Id
        Write-Host "Assigned built-in role '$builtinRoleName' to the managed identity of Function App '$functionAppName'"
    } else {
        Write-Host "The built-in role '$builtinRoleName' is already assigned to the managed identity of Function App '$functionAppName'. No action needed."
    }

}
catch {
    Write-Error "Caught an exception: $($_.Exception.Message)"
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
    Write-Error "Script failed. Exiting with error code 1."
    exit 1
}
