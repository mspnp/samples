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

Run the following command to initiate the deployment. When prompted, enter values for an admin user name and password. These values are used to log into the included virtual machines.

```azurecli-interactive
az deployment sub create \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/site-to-site-demo/solutions/secure-hybrid-network/azuredeploy.json \
    --location eastus --parameters mocOnPremResourceGroup=site-to-site-mock-onprem-999 azureNetworkResourceGroup=site-to-site-azure-network-999
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | azureadmin |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| mocOnPremResourceGroup | string | Name of the moc on-prem resource group. | |
| azureNetworkResourceGroup | string | Name of the azurre network resource group. | |

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
