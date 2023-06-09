# ARM Deployment Steps

1. Create a new Resource Group to be used by all deployed resources:

    ```azurepowershell
    New-AzResourceGroup -Name rg-avnmquickstart -Location EastUS
    ```

1. Deploy the Azure Virtual Network Manager and hub and spoke environment:

    ```azurepowershell
    $templateParamObj = @{
        location = 'eastus'
        adminPassword = '' # something secure
    }

    New-AzResourceGroupDeployment -Name 'avnm-quickstart-deployment' -ResourceGroupName 'rg-avnmquickstart' -location 'eastus' -templateFile ./avnmResources.json -templateParameterObject $templateParamObj
    ```

1. Deploy the Azure Policy resources which will manage dynamic membership in the Azure Virtual Network Manager Network Group:

   ```azurepowershell
    $templateParamObj = @{
        # see the output of the above AVNM deployment for the Network Group ID
        networkGroupId = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-avnmquickstart/Microsoft.Network/networkManagers/avnm-eastus/networkGroups/ng-learn-prod-eastus-dynamic-001'
        resourceGroupName = 'rg-avnmquickstart'
    }

    New-AzSubscriptionDeployment -Name 'avnm-quickstart-policy-deployment' -templateFile ./avmnDynamicMembershipPolicy.json -templateParameterObject $templateParamObj
```

