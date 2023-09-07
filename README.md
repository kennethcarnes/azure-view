# Azure View
A real-time web dashboard displaying parameters for different Azure services.

## Data Flow
1. User interacts with the front-end, selects service from dropdown.
2. A single Azure Function (`fetch-and-store.ps1`) is triggered, retrieving JSON data from ARM API for the selected Azure service.
3. The Azure Function also stores it in Cosmos DB.
4. UI updates to reflect the latest parameters and options.

## CI/CD
- GitHub Actions promotion pipeline for multi-environment deployments
- Deploys code to the test environment upon successful tests.
- Requires manual trigger to deploy code to the prod environment.

## Infrastructure as Code (IaC)

### main.bicep
- Orchestration of Azure resources
- Includes references to `frontend.bicep` and `backend.bicep`.

### frontend.bicep
- Azure App Service
- HTML, CSS, and JS
- AJAX: Updates the UI with data retrieved from Cosmos DB

### backend.bicep
- Azure Function w/ PowerShell
- Azure Cosmos DB: Default automatic indexing

## Version Control
All code is stored in a Github repository and version controlled with Git