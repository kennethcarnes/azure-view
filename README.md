# Cloud Service Status Dashboard
A real-time web dashboard for monitoring the status of Azure, GCP, and AWS cloud services. 

## Data Flow
1. User interacts with the front-end, clicking a tile to view the status of Azure, GCP, or AWS.
2. `fetch-function.ps1` is triggered, retrieving JSON data from public APIs for the selected cloud service.
3. `process-function.ps1` filters and transforms this data for UI presentation.
4. Filtered data is stored in Cosmos DB by `store-function.ps1`.
5. UI updates to reflect the latest status.

## CI/CD
- Technology: GitHub Actions
- Style: Promotion-Based Pipeline for multi-environment deployments
- Builds the code and runs unit tests with Pester.
- Deploys code to test environment upon successful tests.
- Requires manual trigger to deploy code to prod environment.

## Infrastructure as Code (IaC)

### main.bicep
- Orchestration of Azure resources
- Includes references to `frontend.bicep` and `backend.bicep`.

### frontend.bicep
- **Azure App Service**: Hosts the front-end
  - **HTML and CSS**: UI consists of simple, clickable tiles for Azure, GCP, and AWS.

### backend.bicep
- **Azure Functions**: PowerShell-based functions
  - `fetch-function.ps1`: Retrieves raw JSON data.
  - `process-function.ps1`: Filters and transforms the JSON data.
  - `store-function.ps1`: Writes the processed data to Cosmos DB.
- **Azure Cosmos DB**: Data Storage
  - Partitioning: Data is partitioned by cloud service type.
  - TTL: Data has a 24-hour lifespan.
- **Azure VNET & Subnets**: Isolate backend and data storage