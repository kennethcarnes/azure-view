# This script grants both the "User Access Administrator" and the "App Configuration Data Owner" roles 
# to a specified Service Principal for a specific Azure App Configuration.

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $appConfigName,

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
    Write-Host "Retrieving subscription ID and constructing App Configuration resource ID..."
    $subscriptionId = (Get-AzContext).Subscription.Id
    if (-not $subscriptionId) { ExitWithError "Failed to retrieve Subscription ID" 2 }

    $appConfigResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.AppConfiguration/configurationStores/$appConfigName"
    Write-Host "App Configuration Resource ID: $appConfigResourceId"

    Write-Host "Validating existence of App Configuration..."
    $appConfig = Get-AzResource -ResourceId $appConfigResourceId
    if (-not $appConfig) { ExitWithError "App Configuration '$appConfigName' does not exist in resource group '$resourceGroupName'." 3 }
    Write-Host "Validated: App Configuration exists."

    Write-Host "Retrieving Object ID of the Service Principal using its Client ID..."
    $sp = Get-AzADServicePrincipal -ApplicationId $servicePrincipalClientId
    if (-not $sp) { ExitWithError "Failed to retrieve Service Principal by its Application ID: $servicePrincipalClientId" 4 }
    $spObjectId = $sp.Id

    # Assign 'User Access Administrator' role
    $roleName = "User Access Administrator"
    AssignRoleToServicePrincipal -spObjectId $spObjectId -roleName $roleName

    # Assign 'App Configuration Data Owner' role
    $roleName = "App Configuration Data Owner"
    AssignRoleToServicePrincipal -spObjectId $spObjectId -roleName $roleName

} catch { 
    ExitWithError "Caught an exception: $($_)" 1
}

function AssignRoleToServicePrincipal {
    param (
        [string] $spObjectId,
        [string] $roleName
    )
    Write-Host "Checking if role assignment exists for Service Principal for role '$roleName'..."
    $existingAssignment = Get-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName $roleName -Scope $appConfigResourceId -ErrorAction SilentlyContinue
    if ($null -eq $existingAssignment) {
        Write-Host "No existing role assignment found for role '$roleName'. Assigning now..."
        New-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName $roleName -Scope $appConfigResourceId
    } else {
        Write-Host "Role '$roleName' is already assigned to the Service Principal at App Configuration scope. No action needed."
    }
}
