# This script assigns the "Contributor" role to a Service Principal for a specific Azure Function App.

param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $functionAppName,

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
    # Retrieve subscription ID and construct Function App resource ID
    $subscriptionId = (Get-AzContext).Subscription.Id
    if (-not $subscriptionId) { ExitWithError "Failed to retrieve Subscription ID" 2 }

    $functionAppResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$functionAppName"
    
    # Validate existence of Function App
    $funcApp = Get-AzResource -ResourceId $functionAppResourceId
    if (-not $funcApp) { ExitWithError "Function App '$functionAppName' does not exist in resource group '$resourceGroupName'." 3 }

    # Get the Object ID of the Service Principal using its Client ID
    $sp = Get-AzADServicePrincipal -ApplicationId $servicePrincipalClientId
    if (-not $sp) { ExitWithError "Failed to retrieve Service Principal by its Application ID: $servicePrincipalClientId" 4 }
    $spObjectId = $sp.Id

    # Check if role assignment exists for Service Principal
    $roleName = "Contributor"
    $existingAssignment = Get-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName $roleName -Scope $functionAppResourceId -ErrorAction SilentlyContinue
    
    if ($null -eq $existingAssignment) {
        # If no existing role assignment found, assign now
        New-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName $roleName -Scope $functionAppResourceId
        Write-Output "Role '$roleName' assigned to the Service Principal for the Function App."
    } else {
        Write-Output "Role '$roleName' is already assigned to the Service Principal for the Function App. No action needed."
    }
}
catch { 
    ExitWithError "Caught an exception: $($_)" 1
}