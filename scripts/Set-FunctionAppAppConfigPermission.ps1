# This script assigns the "App Configuration Data Reader" role to a Function App's Managed Identity, allowing it to read key-value pairs from a specified App Configuration.

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $appConfigName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $functionAppName
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

    Write-Host "Fetching Managed Identity Object ID for the Function App '$functionAppName'..."
    $functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
    $objectId = $functionApp.Identity.PrincipalId
    if (-not $objectId) { ExitWithError "Failed to retrieve Managed Identity for the Function App: $functionAppName" 4 }

    # Using built-in role 'App Configuration Data Reader' for reading key-value pairs
    $roleName = "App Configuration Data Reader"

    Write-Host "Checking if role assignment exists for the Function App's Managed Identity..."
    $existingAssignment = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $roleName -Scope $appConfigResourceId -ErrorAction SilentlyContinue
    if ($null -eq $existingAssignment) {
        Write-Host "No existing role assignment found. Assigning now..."
        New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $roleName -Scope $appConfigResourceId
    } else {
        Write-Host "Role '$roleName' is already assigned to the Function App's Managed Identity at App Configuration scope. No action needed."
    }
} catch { 
    ExitWithError "Caught an exception: $($_)" 1
}