# Fetch data from ARM API
$apiUrl = "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProvider}/{resourceName}?api-version=2021-04-01"
$apiResponse = Invoke-RestMethod -Uri $apiUrl -Headers @{ "Authorization" = "Bearer $env:ACCESS_TOKEN" }

# Store in Cosmos DB
$cosmosDbUri = "https://your-cosmos-db-uri.com/dbs/YourDb/colls/YourCollection/docs"
Invoke-RestMethod -Method Post -Uri $cosmosDbUri -Body ($apiResponse | ConvertTo-Json) -Headers @{ "Authorization" = "Bearer $env:COSMOS_DB_TOKEN" }
