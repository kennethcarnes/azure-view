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
    # Replace func-ingest-data URL placeholder
    $content = Get-Content $htmlFile
    $updatedContent = $content -replace 'func-ingest-data-ApiUrlPlaceholder', "https://$functionAppName.azurewebsites.net/api/func-ingest-data"
    
    # Check if a replacement happened; if not, throw an error
    if ($updatedContent -eq $content) {
        throw "No 'func-ingest-data-ApiUrlPlaceholder' placeholder found in $htmlFile."
    }

    # Write the updated content back to the file
    $updatedContent | Set-Content $htmlFile

    # Replace func-retrieve-data URL placeholder
    $content = Get-Content $htmlFile
    $updatedContent = $content -replace 'func-retrieve-data-ApiUrlPlaceholder', "https://$functionAppName.azurewebsites.net/api/func-retrieve-data"
    
    # Check if a replacement happened; if not, throw an error
    if ($updatedContent -eq $content) {
        throw "No 'func-retrieve-data-ApiUrlPlaceholder' placeholder found in $htmlFile."
    }

    # Write the updated content back to the file
    $updatedContent | Set-Content $htmlFile
}
catch {
    Write-Error "Error updating placeholders in $htmlFile. Details: $_"
    exit 1
}