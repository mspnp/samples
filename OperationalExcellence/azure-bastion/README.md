**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name bast-hub-spoke-002 --location eastus
```

Run the following command to initiate the deployment.c

```azurecli
az deployment group create \
    --resource-group bast020 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/azure-software-updates/OperationalExcellence/azure-bastion/azuredeploy.json \
    --parameters adminPassword=Password2020!
```

```azurecli
az deployment group create \
    --resource-group bast-hub-spoke-002 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/azure-software-updates/OperationalExcellence/azure-bastion/azuredeploy.json \
    --parameters adminPassword=Password2020! windowsVMCount=1
```


```azurecli
az group create --name bast-hub-spoke-013 --location eastus
```



```azurecli
az deployment group create \
    --resource-group bast-hub-spoke-013 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/bastion-hub-spoke/OperationalExcellence/azure-bastion/azuredeploy.json \
    --parameters adminPassword=Password2020! windowsVMCount=1
```