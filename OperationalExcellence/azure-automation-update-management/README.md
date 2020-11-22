**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name update0001 --location eastus
```

Run the following command to initiate the deployment.c

```azurecli
az deployment group create \
    --resource-group update0001 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/azure-software-updates/OperationalExcellence/azure-automation-update-management/azuredeploy.json \
    --parameters adminUserName=azureadmin adminPassword=Password2020! windowsVMCount=2 linuxVMCount=2
```