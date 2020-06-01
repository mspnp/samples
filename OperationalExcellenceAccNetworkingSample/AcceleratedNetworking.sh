# This set of Azure CLI commands shows how to enable accelerated networking for all the VMS included in an availability set

# Prerequisites

# Either run the commands in the Azure Cloud Shell, or by running the CLI from your computer. 
# These commands require the Azure CLI version 2.0.32 or later. Run az --version to find the installed version. 
# You also need to run az login to log in to Azure.

# Make sure that you have a subscription associated with your Azure Account
# If the CLI can open your default browser, it will do so and load an Azure sign-in page. 
# Otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.


az login

# Select your subscription

az account set -s 3b518fac-e5c8-4f59-8ed5-d70b626f8e10

# Create a resource group.
az group create --name acceleratedNetwork-rg --location centralus

# deploy the ARM template with the scenario

az deployment group create --resource-group acceleratedNetwork-rg --template-file Deployment/accNetwork.json

# Since there are two VMs in an availability set we need to deallocate both VM1 and VM2

az vm deallocate --resource-group acceleratedNetwork-rg --name accNetwork-Vm1

az vm deallocate --resource-group acceleratedNetwork-rg --name accNetwork-Vm2

# Then we enable accelerated networking for both VMs

az network nic update --name accNetwork-nint1 --resource-group acceleratedNetwork-rg --accelerated-networking true

az network nic update --name accNetwork-nint2 --resource-group acceleratedNetwork-rg --accelerated-networking true

# Final step, restart both VMs

az vm start --resource-group acceleratedNetwork-rg --name accNetwork-Vm1

az vm start --resource-group acceleratedNetwork-rg --name accNetwork-Vm2
