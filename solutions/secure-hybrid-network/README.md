---
page_type: sample
languages:
- azurepowershell
- azurecli
products:
  - azure-app-service
  - azure-log-analytics
  - azure-key-vault
  - azure-sql-database
description: This sample deploys an empty web app, two web app slots, web app metric alerts, and autoscale rules. A SQL database is also deployed, the connection string stored in Azure Key Vault, and configured on the web application. 
---

# Basic web app deployment

[![Build Status](https://nepeters-devops.visualstudio.com/arm-template-validation-pipelines/_apis/build/status/basic-web-app?branchName=master)](https://nepeters-devops.visualstudio.com/arm-template-validation-pipelines/_build/latest?definitionId=131&branchName=master)

For detailed information, see the Implement a secure hybrid network:

> [!div class="nextstepaction"]
> [Implement a secure hybrid network](https://docs.microsoft.com/azure/architecture/reference-architectures/dmz/secure-vnet-dmz)

## Deploy sample

Create a resource group for the deployment.

```azurecli-interactive
az group create --name secure-hybrid --location eastus
```

Run the following command to initiate the deployment. When prompted, enter values for an Azure SQL DB admin user name and password.

```azurecli-interactive
az deployment group create \
    --resource-group secure-hybrid   \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/solutions/secure-hybrid-network/azuredeploy.json
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | azureadmin |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |

## Diagnostic configurations

The following resources are configured to send diagnostic logs, and metric data to the included Log Analytics workspace.

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
