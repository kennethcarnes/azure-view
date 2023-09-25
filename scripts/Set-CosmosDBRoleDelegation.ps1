param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $cosmosDbAccountName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $servicePrincipalClientId
)

function ExitWithError {
    param (
        [string] $message,
        [int] $exitCode
    )
    Write-Error $message
    if ($_.Exception.InnerException) {
        Write-Error "Inner Exception: $($_.Exception.InnerException)"
    }
    Write-Error "Full Exception: $_"
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
    exit $exitCode
}

try {

    Write-Host "Retrieving subscription ID and constructing Cosmos DB resource ID..."
    $subscriptionId = (Get-AzContext).Subscription.Id
    if (-not $subscriptionId) { ExitWithError "Failed to retrieve Subscription ID" 2 }

    $cosmosDbResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DocumentDB/databaseAccounts/$cosmosDbAccountName"
    Write-Host "Cosmos DB Resource ID: $cosmosDbResourceId"

    Write-Host "Validating existence of Cosmos DB Account..."
    $cosmosDbAccount = Get-AzResource -ResourceId $cosmosDbResourceId
    if (-not $cosmosDbAccount) { ExitWithError "Cosmos DB Account '$cosmosDbAccountName' does not exist in resource group '$resourceGroupName'." 3 }

    Write-Host "Validated: Cosmos DB Account exists."

    Write-Host "Setting up custom role properties..."
    $customRoleProperties = @{
        Name             = "Custom Role Assignment Delegate"
        Description      = "Allows for role assignment within a specified scope."
        Actions          = @("Microsoft.Authorization/roleAssignments/write", "Microsoft.Authorization/roleAssignments/delete", "Microsoft.Authorization/roleAssignments/read")
        AssignableScopes = @($cosmosDbResourceId)
    }

    Write-Host "Checking if custom role exists..."
    $existingRole = Get-AzRoleDefinition -Name "Custom Role Assignment Delegate" -ErrorAction SilentlyContinue
    if ($null -eq $existingRole) {
        Write-Host "Role 'Custom Role Assignment Delegate' does not exist. Creating it now."
        New-AzRoleDefinition @customRoleProperties
    } else {
        Write-Host "Role exists. Updating its properties..."
        $existingRole.Actions = $customRoleProperties.Actions
        $existingRole.AssignableScopes = $customRoleProperties.AssignableScopes
        $existingRole | Set-AzRoleDefinition
    }

    Write-Host "Retrieving Object ID of the Service Principal using its Client ID..."
    $sp = Get-AzADServicePrincipal -ApplicationId $servicePrincipalClientId
    if (-not $sp) { ExitWithError "Failed to retrieve Service Principal by its Application ID: $servicePrincipalClientId" 4 }

    $spObjectId = $sp.Id

    Write-Host "Checking if role assignment exists for Service Principal..."
    $existingAssignment = Get-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName "Custom Role Assignment Delegate" -Scope $cosmosDbResourceId -ErrorAction SilentlyContinue
    if ($null -eq $existingAssignment) {
        Write-Host "No existing role assignment found. Assigning now..."
        New-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName "Custom Role Assignment Delegate" -Scope $cosmosDbResourceId
    } else {
        Write-Host "Role 'Custom Role Assignment Delegate' is already assigned to the Service Principal at Cosmos DB scope. No action needed."
    }

} catch { 
    ExitWithError "Caught an exception: $($_.Exception.Message)" 1
}