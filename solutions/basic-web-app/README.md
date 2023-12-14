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

This sample deploys an empty web app, two web app slots, web app metric alerts, and autoscale rules. A SQL database is also deployed, the connection string stored in Azure Key Vault, and configured on the web application.

Where applicable, each resource is configured to send diagnostics and metrics to an Azure Log Analytics workspace.

For detailed information, see the Basic web application reference architecture:

> [!div class="nextstepaction"]
> [Basic web application reference architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/app-service-web-app/basic-web-app)

## Deploy sample

Create a resource group for the deployment.

```azurecli-interactive
az group create --name basic-web-app --location eastus
```

Run the following command to initiate the deployment. When prompted, enter values for an Azure SQL DB admin user name and password.

```azurecli-interactive
az deployment group create \
    --resource-group basic-web-app  \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/basic-web-app/azuredeploy.json
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | azureadmin |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| logAnalytics | object | Network configuration for the Log Analytics workspace. | name, skuName |
| azureSqlDatabase | object | Network configuration for the Azure SQL and Azure SQL database instances. | name, databaseName, collation, edition, maxSizeBytes, requestedServiceObjectiveName |
| keyVault | object | Network configuration for the Azure Key Vault instance. | name, skuName, skuFamily |
| azureAppService | object | Network configuration for the Azure App Service instance. | name, webSiteName, skuName, skuCapacity, autoScaleMin, autoscaleMax, autoscaleDefault |

## Diagnostic configurations

The following resources are configured to send diagnostic logs, and metric data to the included Log Analytics workspace.

- SQL instance
- Key Vault
- App Service instance
- Web app and all slots

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns
