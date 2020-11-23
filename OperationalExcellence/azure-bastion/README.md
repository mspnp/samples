**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name bast002 --location eastus
```

Run the following command to initiate the deployment.c

```azurecli
az deployment group create \
    --resource-group bast002 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/azure-software-updates/OperationalExcellence/azure-bastion/azuredeploy.json \
    --parameters adminPassword=Password2020!
```