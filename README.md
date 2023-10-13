# ARM Viz
ARM Viz is a public website that helps to visualize the hierarchy and availability of [Azure Resource Manager REST API](https://learn.microsoft.com/en-us/rest/api/resources/) offerings. Utilizing a browsable sunburst chart, it provides a comprehensive yet simplified representation of Azure namespaces, resource types, and API versions.

## Data Flow
```mermaid
graph TB

    subgraph "Frontend"
        swa --> button-ingest
        swa --> button-retrieve
        button-ingest --> apim
        button-retrieve --> apim
        apim --> op-ingest
        apim --> policy-cors
        apim --> op-retrieve
    end

    subgraph "Backend"
        op-ingest --> func-ingest
        op-retrieve --> func-retrieve
        func-ingest --> arm-api
        arm-api --> func-ingest
        func-ingest --> costab
        func-retrieve --> costab   
    end
```

## Data Modeling
Data is organized based on Azure namespaces, resource types, and API versions, making it easy for users to navigate and explore the Sunburst Chart.

- Example JSON snippet:
    ```json
    {
        "namespace": "Microsoft.Compute",
        "resourceTypes": [
            {
                "resourceType": "virtualMachines",
                "apiVersions": ["2021-07-01", "2020-12-01"]
            },
            {
                "resourceType": "disks",
                "apiVersions": ["2021-07-01", "2020-12-01"]
            }
        ]
    }

## CI/CD Orchestration
- Deployment to multiple environments via Github Actions
  ![Deployment Screenshot](/images/image-3.png)  
  [Learn More](https://learn.microsoft.com/en-us/training/modules/manage-multiple-environments-using-bicep-github-actions/2-understand-environments)
  
- Separate workload identities for each environment  
  ![Workload Identities](/images/image-1.png)  
  [Learn More](https://learn.microsoft.com/en-us/training/modules/manage-multiple-environments-using-bicep-github-actions/4-exercise-set-up-environment?pivots=powershell)

- Reusable Workflows and workflow inputs handle similarities and differences between environments
  [Learn More](https://learn.microsoft.com/en-us/training/modules/manage-multiple-environments-using-bicep-github-actions/3-handle-similarities-between-environments-using-reusable-workflows)

- A protection rule is added to require approval for deployment to the production environment

## IaC Orchestration

### [main.bicep](./main.bicep)
Primary entry for deployments, managing environment-specific configurations.

### [frontend.bicep](./frontend.bicep)
Deploys and configures Azure Static Web App and API Management Service.

### [backend.bicep](./backend.bicep)
Defines Azure Function and Azure Cosmos DB setups for backend processing and data storage.

## Parameters and Secrets Management

### Infrastructure Parameters
Defined within [main.bicep](./main.bicep) and pertain to resource naming, location, and sizing.

### CI/CD Secrets
Secured in GitHub Actions Secrets and used during CI/CD processes.

## PowerShell Scripts
- **Set-AppConfigKVPs.ps1**: This script sets key-value pairs on an Azure App Configuration.
  
- **Set-FuncAppAppConfigPerms.ps1**: This script assigns the "App Configuration Data Reader" role to a Function App's Managed Identity, allowing it to read key-value pairs from a specified App Configuration.
  
- **Set-FuncAppCosmosDBPerms.ps1**: This script assigns the "DocumentDB Account Contributor" role to a Function App's Managed Identity for a Cosmos DB account.
  
- **Set-RepoPlaceholders.ps1**: This script updates the placeholders in an HTML file with specific values for API Management (APIM).
  
- **Set-SPAppConfigRoleDelegate.ps1**: This script assigns the 'User Access Administrator' and 'App Configuration Data Owner' roles to a Service Principal.
  
- **Set-SPCosmosDBRoleDelegate.ps1**: This script assigns the "User Access Administrator" role to a Service Principal for a Cosmos DB account.
  
- **Set-SPFuncAppRoleDelegate.ps1**: This script assigns the "Contributor" role to a Service Principal for a Azure Function App.



