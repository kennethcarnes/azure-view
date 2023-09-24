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

# Ensure Azure module is loaded
if (-not (Get-Module -Name Az.Websites -ListAvailable)) {
    Write-Error "The required module 'Az.Websites' is not loaded or installed."
    exit 1
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
    Write-Error "Function App '$functionAppName' either does not exist in resource group '$resourceGroupName' or the script lacks permission to access it."
    exit 1
}

Write-Output "Function App details: $($funcApp | ConvertTo-Json)"

try {
    # Update CORS settings for the function app
    Update-AzFunctionAppSetting -Name $functionAppName -ResourceGroupName $resourceGroupName -AppSetting $corsSettings
    Write-Output "CORS settings updated successfully for $functionAppName in $resourceGroupName."
}
catch {
    Write-Error "Failed to update CORS settings for $functionAppName in $resourceGroupName. Detailed Error: $_"
    exit 1
}
