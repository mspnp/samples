
```
az group create --name template-003 --location eastus
```

```
az deployment group create --template-file OperationalExcellence/state-configuration-sample/azuredeploy.json --resource-group template-003 --parameters adminUserName=azureadmin adminPassword=Password2020!
```