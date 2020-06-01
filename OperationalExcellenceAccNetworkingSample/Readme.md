# Enabling Accelerated Networking on your VMs

This set of Azure CLI commands shows how to enable accelerated networking for all the VMs included in an availability set. Azure Accelerated Networking is a feature for Azure IaaS Virtual Machines occurring at NIC level; it enables single root I/O virtualization (SR-IOV) to a VM, greatly improving its networking performance. This high-performance path bypasses the hosting infrastructure from the datapath, reducing latency, jitter, and CPU utilization.

## Prerequisites

Either run the commands in the Azure Cloud Shell, or by running the CLI from your computer.  These commands require the Azure CLI version 2.0.32 or later. Run az --version to find the installed version. You also need to run az login to log in to Azure. Make sure that you have a subscription associated with your Azure Account. If the CLI can open your default browser, it will do so and load an Azure sign-in page, otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.

### Log in to Azure

```sh
az login
```

### Select your subscription

```sh
az account set -s <Your subscription Id>
```

### Create a resource group.

```sh
az group create --name acceleratedNetwork-rg --location centralus
```

### deploy the ARM template with the scenario

```sh
az deployment group create --resource-group acceleratedNetwork-rg --template-file Deployment/accNetwork.json
```

### Since there are two VMs in an availability set we need to deallocate both VM1 and VM2

```sh
az vm deallocate --resource-group acceleratedNetwork-rg --name accNetwork-Vm1

az vm deallocate --resource-group acceleratedNetwork-rg --name accNetwork-Vm2
```

### Then we enable accelerated networking for both VMs

```sh
az network nic update --name accNetwork-nint1 --resource-group acceleratedNetwork-rg --accelerated-networking true

az network nic update --name accNetwork-nint2 --resource-group acceleratedNetwork-rg --accelerated-networking true
```

### Final step, restart both VMs

```sh
az vm start --resource-group acceleratedNetwork-rg --name accNetwork-Vm1

az vm start --resource-group acceleratedNetwork-rg --name accNetwork-Vm2
```