param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $HtmlFile,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ApimName
)

try {
    $OriginalContent = Get-Content -Path $HtmlFile -Raw
    
    $Replacements = @{
        'apim-ingest-ApiUrlPlaceholder' = "https://$ApimName.azure-api.net/api/ingest";
        'apim-retrieve-ApiUrlPlaceholder' = "https://$ApimName.azure-api.net/api/retrieve";
    }
    
    $UpdatedContent = $OriginalContent
    foreach ($Placeholder in $Replacements.Keys) {
        if ($UpdatedContent -match $Placeholder) {
            $UpdatedContent = $UpdatedContent -replace $Placeholder, $Replacements[$Placeholder]
        } else {
            Write-Warning "Placeholder '$Placeholder' not found in $HtmlFile."
        }
    }

    # Only write back if content has changed
    if ($UpdatedContent -ne $OriginalContent) {
        $UpdatedContent | Set-Content -Path $HtmlFile
        Write-Output "Placeholders replaced in $HtmlFile."
    } else {
        Write-Output "No changes were made to $HtmlFile."
    }
}
catch {
    Write-Error "Error updating placeholders in $HtmlFile. Details: $_"
    exit 1
}