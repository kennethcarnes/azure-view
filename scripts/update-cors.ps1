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

# Construct the hashtable for CORS settings
$corsSettings = @{
    CorAllowedOrigin = $allowedOrigins;
    CorSupportCredentials = $false  # Assuming you want to support credentials, adjust as needed.
}

try {
    # Update CORS settings for the function app
    Update-AzFunctionAppSetting -Name $functionAppName -ResourceGroupName $resourceGroupName -AppSetting $corsSettings -SubscriptionId $subscriptionId  # <-- Modified this line
}
catch {
    Write-Error "Failed to update CORS settings for $functionAppName in $resourceGroupName. Error: $_"
    exit 1
}