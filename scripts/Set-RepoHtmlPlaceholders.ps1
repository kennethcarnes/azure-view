# This script updates an HTML file by replacing placeholder API URLs with actual API endpoints associated with a specified Azure Function App.

param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "The file path '$_' does not exist."
        }
        if (-not ($_ -match "\.html$")) {
            throw "The file '$_' is not an HTML file."
        }
        return $true
    })]
    [string] $htmlFile,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $functionAppName
)

try {
    # Get the content of the HTML file
    $content = Get-Content $htmlFile -Raw

    # Define a hashtable of placeholders and their replacements
    $replacements = @{
        'func-ingest-data-ApiUrlPlaceholder'     = "https://$functionAppName.azurewebsites.net/api/func-ingest-data";
        'func-retrieve-data-ApiUrlPlaceholder'  = "https://$functionAppName.azurewebsites.net/api/func-retrieve-data";
    }

    # Iterate over each placeholder and replace in content
    foreach ($placeholder in $replacements.Keys) {
        if ($content -match $placeholder) {
            $content = $content -replace $placeholder, $replacements[$placeholder]
        } else {
            throw "Placeholder '$placeholder' not found in $htmlFile."
        }
    }

    # Write the updated content back to the file
    $content | Set-Content $htmlFile
}
catch {
    Write-Error "Error updating placeholders in $htmlFile. Details: $_"
    exit 1
}