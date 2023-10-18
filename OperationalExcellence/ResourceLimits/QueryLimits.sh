# This set of Azure CLI commands shows how to query limit and quotas for networking, SQL Database, storage, and virtual machine resources.

# Prerequisites

# Either run the commands in the Azure Cloud Shell, or by running the CLI from your computer.
# These commands require the Azure CLI version 2.0.32 or later. Run az --version to find the installed version.
# You also need to run az login to log in to Azure.

# Make sure that you have a subscription associated with your Azure Account
# If the CLI can open your default browser, it will do so and load an Azure sign-in page.
# Otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.

az login

# Set the subscription you are going to query

az account set -s <your subscription id>


# This command gets the limits for networking resources in the West US location

az network list-usages --location westus --query "[].{Name: localName, limit:limit}" --out table


# Alternatively you can query for specific resources, this command gets the limits for all the IP related resources in the West US location

az network list-usages --location westus --query "[?contains(id, 'IP')].{Name: localName, limit:limit}" --out table


# This command gets the limits for all the Load Balancer related resources in the West US location

az network list-usages --location westus --query "[?contains(id, 'Balancer')].{Name: localName, limit:limit}" --out table


# Use this command to get all SQL limits in the West US location

az sql list-usages --location westus --query "[].{Name: name, Limit: limit}" --out table


# Use this command in case you need to query for a specific SQL limit in the West US location

az sql list-usages --location westus --query "[?name == 'SubscriptionFreeDatabaseDaysLeft'].limit" --out tsv

# or

az sql show-usage --location westus --usage VCoreQuota


# Use this command to get the storage accounts limit in the West US location

az storage account show-usage --location westus


# Use this command to get virtual machine related resource limits in the West US location

az vm list-usage --location westus --out table