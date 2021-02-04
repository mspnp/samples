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
---

# Basic web app deployment

This sample deploys an empty web app, two web app slots, web app metric alerts, and autoscale rules. A SQL database is also deployed, the connection string stored in Azure Key Vault, and configured on the web app.

Where applicable, each resource is configured to send diagnostics to an Azure Log Analytics instance.

For detailed information, see the Basic web application reference architecture:

> [!div class="nextstepaction"]
> [Basic web application reference architecture](https://docs.microsoft.com/azure/architecture/reference-architectures/app-service-web-app/basic-web-app)

## Deploy sample

Create a resource group for the deployment.

```azurecli-interactive
az group create --name basic-web-app --location eastus
```

Run the following command to initiate the deployment.

```azurecli-interactive
az deployment group create \
    --resource-group basic-web-app \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/solutions/basic-web-app/azuredeploy.json --parameters adminPassword=Password2020!
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | azureadmin |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| hubNetwork | object | Network configuration for the hub virtual network. | [see template] |
| logAnalytics | object | Network configuration for the Log Analytics workspace. | [see template] |
| azureSqlDatabase | object | Network configuration for the Azure SQL and Azure SQL database instances. | [see template] |
| keyVault | object | Network configuration for the Azure Key Vault instance. | [see template] |
| azureAppService | object | Network configuration for the Azure App Service instance. | [see template] |
| storageAccount | object | Network configuration for the Azure Storage Account instance. | [see template] |


## Diagnostic configurations

The following resources are configured to send diagnostic logs and metric data to the included Log Analytics workspace.

- SQL instance
- Key Vaule
- App Service instance
- Web app and all slots

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
