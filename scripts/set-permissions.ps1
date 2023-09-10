Install-Module -Name Az.CosmosDB -RequiredVersion 1.2.0 -Force -SkipPublisherCheck

New-AzCosmosDBSqlRoleDefinition -AccountName "<YourCosmosDBAccountName>" `
          -ResourceGroupName ${{ inputs.resourceGroupName }} `
          -Type CustomRole -RoleName MyReadWriteRole `
          -DataAction @( `
            'Microsoft.DocumentDB/databaseAccounts/readMetadata',
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*', `
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*') `
          -AssignableScope "/" `