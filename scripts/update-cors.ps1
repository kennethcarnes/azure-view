param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $functionAppName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $allowedOrigins
)

# Ensure Azure module is loaded
if (-not (Get-Module -Name Az.Websites -ListAvailable)) {
    Write-Error "The required module 'Az.Websites' is not loaded or installed."
    exit 1
}

try {
    # Setting CORS Allowed Origins
    Set-AzWebAppCorsAllowedOrigins -ResourceGroupName $resourceGroupName -Name $functionAppName -AllowedOrigins $allowedOrigins
}
catch {
    Write-Error "Failed to set CORS allowed origins for $functionAppName in $resourceGroupName. Error: $_"
    exit 1
}