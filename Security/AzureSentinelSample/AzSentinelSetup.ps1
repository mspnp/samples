param (
    [Parameter(Mandatory=$true)]
    $Location, 
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $ResourceGroupName, 
    [Parameter(Mandatory=$true)]
    $WorkspaceName
)

# Connecting to Azure

Connect-AzAccount

# Setting Azure Context

Set-AzContext -SubscriptionId $SubscriptionId

# Creating Azure resource group

New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Adding AzSentinel module

Install-Module -Name powershell-yaml

Install-Module AzSentinel -Scope CurrentUser -Force

Import-Module AzSentinel

# Adding OperationalInsights module

Install-Module -Name Az.OperationalInsights

# Creating Log Analytics Workspace

New-AzOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -Sku Standard -ResourceGroupName $ResourceGroupName

# Adding Azure Sentinel to the log analytics workspace

Set-AzSentinel -SubscriptionId $SubscriptionId -WorkspaceName $WorkspaceName 

# Deploy App Gateway with WAF connected to log analytics workspace

Write-Host "Azure Sentiel successfully set up, creating Azure App Gateway..." 

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile AppGatewayDeployment.json
