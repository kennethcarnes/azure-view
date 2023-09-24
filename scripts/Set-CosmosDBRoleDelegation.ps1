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

try {
    # 1. Get the Cosmos DB resource ID
    $subscriptionId = (Get-AzContext).Subscription.Id
    $cosmosDbResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DocumentDB/databaseAccounts/$cosmosDbAccountName"

    # Validate Cosmos DB Account exists
    $cosmosDbAccount = Get-AzResource -ResourceId $cosmosDbResourceId
    if (-not $cosmosDbAccount) {
        throw "Cosmos DB Account '$cosmosDbAccountName' does not exist in resource group '$resourceGroupName'."
    }

    # 2. Update the custom role with the Cosmos DB scope
    $customRoleProperties = @{
        Name             = "Custom Role Assignment Delegate"
        Description      = "Allows for role assignment within a specified scope."
        Actions          = @("Microsoft.Authorization/roleAssignments/write", "Microsoft.Authorization/roleAssignments/delete", "Microsoft.Authorization/roleAssignments/read")
        AssignableScopes = @($cosmosDbResourceId)
    }

    # Check if the role definition exists
    $existingRole = Get-AzRoleDefinition -Name "Custom Role Assignment Delegate" -ErrorAction SilentlyContinue

    if ($null -eq $existingRole) {
        throw "Role 'Custom Role Assignment Delegate' does not exist."
    }

    # Update the role definition
$existingRole.Actions = $customRoleProperties.Actions
$existingRole.AssignableScopes = $customRoleProperties.AssignableScopes
$existingRole | Set-AzRoleDefinition

# Get the ObjectId of the Service Principal using the passed ClientId
$sp = Get-AzADServicePrincipal -ApplicationId $servicePrincipalClientId
$spObjectId = $sp.Id

# Check if the role assignment already exists for the given Service Principal
$existingAssignment = Get-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName "Custom Role Assignment Delegate" -Scope $cosmosDbResourceId -ErrorAction SilentlyContinue

    if ($null -eq $existingAssignment) {
        New-AzRoleAssignment `
            -ObjectId $spObjectId `
            -RoleDefinitionName "Custom Role Assignment Delegate" `
            -Scope $cosmosDbResourceId
        Write-Host "Role 'Custom Role Assignment Delegate' assigned to the Service Principal at Cosmos DB scope."
    } else {
        Write-Host "Role 'Custom Role Assignment Delegate' is already assigned to the Service Principal at Cosmos DB scope. No action needed."
    }

    }
    catch {
        Write-Error "Caught an exception: $($_.Exception.Message)"
        Write-Error "StackTrace: $($_.Exception.StackTrace)"
        Write-Error "Script failed. Exiting with error code 1."
        exit 1
    }
