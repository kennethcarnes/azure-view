# Azure REST API Visualization Dashboard
This is a public website that displays a daily-updated dashboard designed to visualize the hierarchy and availability of Azure's REST API offerings. Utilizing a browsable Sunburst Chart, it provides a comprehensive yet simplified representation of Azure namespaces, resource types, and API versions.

## Data Flow
1. When the solution is deployed, an Azure Function fetches and stores the latest JSON data for all Azure namespaces, resource types, and API versions from Azure's REST API.
   
2. When a user visits the dashboard, the front-end retrieves pre-existing data from Cosmos DB to populate the Sunburst Chart visualization.
   
3. The user can interact with the Sunburst Chart to explore the structure and versions of Azure's REST APIs.
   
4. The Azure Function is set to re-run automatically every 24 hours to refresh the data.

## Data Modeling
Data is organized based on Azure namespaces, resource types, and API versions, making it easy for users to navigate and explore the Sunburst Chart.

- JSON snippet:
    ```json
    {
        "namespace": "Microsoft.Compute",
        "resourceTypes": [
            {
                "resourceType": "virtualMachines",
                "apiVersions": ["2021-07-01", "2020-12-01", ...]
            },
            {
                "resourceType": "disks",
                "apiVersions": ["2021-07-01", "2020-12-01", ...]
            }
        ]
    }
    ```

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

- `main.bicep`: Orchestrates frontend and backend resource deployments.

- `frontend.bicep`: Sets up the Azure App Service to host the Sunburst Chart created with [Plotly](https://plotly.com/)

- `backend.bicep`: Sets up an Azure Function which runs the `fetch-and-store.ps1` script on initial deployment, and again every 24 hours. It also sets up an Azure Cosmos DB with default automatic indexing, configures a 24 hour TTL, and `resourceType` as the partition key.

## Parameters and Secrets
- Parameters that pertain to infrastructure are stored in `main.bicep`
- Secrets that pertain to CI/CD are stored in Github Actions Secrets
- Secrets that pertain to infrastructure are stored in Azure Key vault

## Security

The Function App authenticates to resources via System-Assigned Managed Identities. The Function App is granted the following roles:

## PowerShell Scripts



