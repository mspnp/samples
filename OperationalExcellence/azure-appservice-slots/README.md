# App Service / Website Slots Demo

This sample demonstrates how to use Azure App Service Slots to rollback to a known good deployment.

## Deploy sample

Create a resource group for the deployment.

```azurecli
az group create --location eastus --name slotsDemo
```

Run the following command to initiate the deployment.

```
az deployment group create \
    --resource-group slotsDemo \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/OperationalExcellence/azure-appservice-slots/azuredeploy.json
```

## Demo Solution

Once the deployment has completed, run the following command to return both the application name and URL.

```azurecli-interactive
az webapp list --resource-group slotsDemo --output table
```

Use the _curl_ command to see the application content. Replace the URL with that from your application. The application should return 'Hello World', notice this it is malformed.

```azurecli-interactive
curl jnmdzncbja5qe.azurewebsites.net
```

The results will look similar to the following:

```azurecli
Hello, Wa*rld!
```

Use the _az webapp deployment slot list_ command to return a list of application slots. Replace the application name with the name from your deployment.

```azurecli-interactive
az webapp deployment slot list --resource-group slotsDemo --name jnmdzncbja5qe --output table
```

Use the _az webapp deployment slot swap_ command to swap the known good and production slot. Replace the application name with the name from your deployment.

```azurecli-interactive
az webapp deployment slot swap --slot KnownGood --target-slot production --resource-group slotsDemo --name jnmdzncbja5qe 
```

## Delete solution

Once done with this solution experience, delete the resource group, which also deletes the App Service Plan and applications.

```azurecli-interactive
az group delete --name slotsDemo --yes --no-wait
```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns