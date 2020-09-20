---
page_type: sample
languages:
- azurecli
products:
- azure
---

# Azure Well Architected Framework Sample (ARM Template)

These Azure Resource Manager (ARM) template samples deploy an Azure Automation account and imports / compiles two PowerShell Desired State Configuration scripts. The template then deploys 1 to many virtual machines (Windows and Linux), onboards them into Azure Automation State Configuration, which then uses the compiled configurations to install a webserver on each of the virtual machines.

The deployment is broken down into several ARM templates.

- azuredeploy.json - parent or main template responsible for deploying all other templates
- azuredeploy-state-congif.json - deploys Azure Automation, imports the DSC resource for Linux DSC modules, imports and compiles two DSC configuration into Azure Automation State Configuration
- azuredeploy-virtual-network.json - deploys an Azure Virtual Network
- azure-deploy-windows-vm.json - creates 1 to many Windows virtual machines and onboard them into Azure Automation State Configuration
- azure-deploy-linux-vm.json - creates 1 to many Linux virtual machines and onboard them into Azure Automation State Configuration

## Azure portal

To deploy this template using the Azure portal, click this button.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fsamples%2Fmaster%2FOperationalExcellence%2FSazure-automation-state-configuraton%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>  

## Azure CLI

To use the Azure CLI, run the following commands for the root of this repository. If you would like to adjust the number of virtual machines deployed, update the *windowsVMCount* and *linuxVMCount* values.

```azurecli
az group create --name state-config-demo --location eastus

az deployment group create --template-file OperationalExcellence/state-configuration-sample/azuredeploy.json --resource-group state-config-demo --parameters adminUserName=azureadmin adminPassword=Password2020! windowsVMCount=2 linuxVMCount=2
```

Once done, the following resource will have been deployed to your Azure Subscription.

![Image of the tailwindtraders.com Azure resources, as seen in the Azure portal.](./images/arm-resources.png)

Click on the Azure Automation Account > State Configuration and notice that all virtual machines have been added to the system and are compliant. These machines have all had the PowerShell DSC configuration applied, which has installed a web server on each.

![Image of the tailwindtraders.com Azure resources, as seen in the Azure portal.](./images/arm-resources.png)

Browse to the public IP address of any virtual machine to verify that a web server is running.

![Image of the tailwindtraders.com Azure resources, as seen in the Azure portal.](./images/arm-resources.png)