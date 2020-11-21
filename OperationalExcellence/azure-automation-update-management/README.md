**Azure CLI**

Create a resource group for the deployment.

```azurecli
$ az group create --name azureUpdatesDemo --location eastus
```

Run the following command to initiate the deployment.

```azurecli
$ az deployment group create \
    --resource-group azureUpdatesDemo \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/OperationalExcellence/azure-automation-update-management/azuredeploy.json
```