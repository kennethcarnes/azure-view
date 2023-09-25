# This script updates the Cross-Origin Resource Sharing (CORS) settings for a specified Azure Function App

param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $functionAppName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $allowedOrigins,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $subscriptionId
)

function ExitWithError {
    param (
        [string] $message,
        [int] $exitCode = 1
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
    # Ensure Azure module is loaded
    if (-not (Get-Module -Name Az.Websites -ListAvailable)) {
        ExitWithError "The required module 'Az.Websites' is not loaded or installed." 2
    }

    # Set the Azure Context to the provided SubscriptionId
    Set-AzContext -SubscriptionId $subscriptionId

    # Construct the hashtable for CORS settings
    $corsSettings = @{
        CorAllowedOrigin = $allowedOrigins;
        CorSupportCredentials = $false  # Assuming you want to support credentials, adjust as needed.
    }

    # Check Function App existence
    Write-Output "Checking existence of Function App: $functionAppName in Resource Group: $resourceGroupName"
    $funcApp = Get-AzFunctionApp -Name $functionAppName -ResourceGroupName $resourceGroupName

    if (-not $funcApp) {
        ExitWithError "Function App '$functionAppName' either does not exist in resource group '$resourceGroupName' or the script lacks permission to access it." 3
    }

    Write-Output "Function App details: $($funcApp | ConvertTo-Json)"

    # Update CORS settings for the function app
    Update-AzFunctionAppSetting -Name $functionAppName -ResourceGroupName $resourceGroupName -AppSetting $corsSettings
    Write-Output "CORS settings updated successfully for $functionAppName in $resourceGroupName."

} catch {
    ExitWithError "Failed to update CORS settings for $functionAppName in $resourceGroupName. Detailed Error: $($_)"
}