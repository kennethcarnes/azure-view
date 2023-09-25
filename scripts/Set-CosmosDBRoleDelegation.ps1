param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $cosmosDbAccountName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $servicePrincipalClientId,

    # New: Add a debug switch to control verbose logging.
    [switch] $debug
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
    if ($debug) {
        $VerbosePreference = 'Continue'
    }

    Write-Verbose "Resource Group Name: $resourceGroupName"
    Write-Verbose "Cosmos DB Account Name: $cosmosDbAccountName"
    Write-Verbose "Service Principal Client ID: $servicePrincipalClientId"

    Write-Host "Retrieving subscription ID and constructing Cosmos DB resource ID..."
    $subscriptionId = (Get-AzContext -Verbose:$debug).Subscription.Id
    if (-not $subscriptionId) { ExitWithError "Failed to retrieve Subscription ID" 2 }

    $cosmosDbResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DocumentDB/databaseAccounts/$cosmosDbAccountName"
    Write-Host "Cosmos DB Resource ID: $cosmosDbResourceId"

    Write-Host "Validating existence of Cosmos DB Account..."
    $cosmosDbAccount = Get-AzResource -ResourceId $cosmosDbResourceId -Verbose:$debug
    if (-not $cosmosDbAccount) { ExitWithError "Cosmos DB Account '$cosmosDbAccountName' does not exist in resource group '$resourceGroupName'." 3 }

    Write-Host "Validated: Cosmos DB Account exists."

    Write-Host "Setting up custom role properties..."
    $customRoleProperties = @{
        Name             = "Custom Role Assignment Delegate"
        Description      = "Allows for role assignment within a specified scope."
        Actions          = @("Microsoft.Authorization/roleAssignments/write", "Microsoft.Authorization/roleAssignments/delete", "Microsoft.Authorization/roleAssignments/read")
        AssignableScopes = @($cosmosDbResourceId)
    }
    Write-Verbose "Custom role properties: $($customRoleProperties | Out-String)"

    Write-Host "Checking if custom role exists..."
    $existingRole = Get-AzRoleDefinition -Name "Custom Role Assignment Delegate" -Verbose:$debug -ErrorAction SilentlyContinue
    if ($null -eq $existingRole) {
        Write-Host "Role 'Custom Role Assignment Delegate' does not exist. Creating it now."
        New-AzRoleDefinition @customRoleProperties -Verbose:$debug
    } else {
        Write-Host "Role exists. Updating its properties..."
        $existingRole.Actions = $customRoleProperties.Actions
        $existingRole.AssignableScopes = $customRoleProperties.AssignableScopes
        $existingRole | Set-AzRoleDefinition -Verbose:$debug
    }

    Write-Host "Retrieving Object ID of the Service Principal using its Client ID..."
    $sp = Get-AzADServicePrincipal -ApplicationId $servicePrincipalClientId -Verbose:$debug
    if (-not $sp) { ExitWithError "Failed to retrieve Service Principal by its Application ID: $servicePrincipalClientId" 4 }

    $spObjectId = $sp.Id
    Write-Verbose "Service Principal Object ID: $spObjectId"

    Write-Host "Checking if role assignment exists for Service Principal..."
    $existingAssignment = Get-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName "Custom Role Assignment Delegate" -Scope $cosmosDbResourceId -Verbose:$debug -ErrorAction SilentlyContinue
    if ($null -eq $existingAssignment) {
        Write-Host "No existing role assignment found. Assigning now..."
        New-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName "Custom Role Assignment Delegate" -Scope $cosmosDbResourceId -Verbose:$debug
    } else {
        Write-Host "Role 'Custom Role Assignment Delegate' is already assigned to the Service Principal at Cosmos DB scope. No action needed."
    }

} catch { 
    ExitWithError "Caught an exception: $($_.Exception.Message)" 1
}
