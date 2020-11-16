# App Service / Website Slots Demo

az group create --location eastus --name slotsDemo001

az deployment group create \
    --resource-group slots018 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/appservice-slots-demo/OperationalExcellence/azure-appservice-slots/azuredeploy.json

az webapp list --resource-group slots018 -o table

curl wh7srjrdniwve.azurewebsites.net

az webapp deployment slot list --resource-group slots018 --name wh7srjrdniwve -o table

az webapp deployment slot swap --slot KnownGood --target-slot production --name wh7srjrdniwve --resource-group slots018

curl wh7srjrdniwve.azurewebsites.net
