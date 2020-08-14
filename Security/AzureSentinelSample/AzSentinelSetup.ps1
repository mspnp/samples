param (
    $TenantId, 
    [Parameter(Mandatory=$true)]
    $ClientId, 
    [Parameter(Mandatory=$true)]
    $ClientSecret, 
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

# Adding OperationalInsights module

Install-Module -Name Az.OperationalInsights

# Creating Log Analytics Workspace

New-AzOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -Sku Standard -ResourceGroupName $ResourceGroupName

# Getting Azure Analytics Workspace to which the new Azure Sentinel solution will be assigned

$workspaceResult = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName

# Setting up body and headers for the API call

$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"

$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=https://management.core.windows.net/"

$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'


$scbody = @{
    'id'         = ''
    'etag'       = ''
    'name'       = ''
    'type'       = ''
    'location'   = $workspaceResult.location
    'properties' = @{
        'workspaceResourceId' = $workspaceResult.resourceId
    }
    'plan'       = @{
        'name'          = 'Test'
        'publisher'     = 'Microsoft'
        'product'       = 'OMSGallery/SecurityInsights'
        'promotionCode' = ''
    }
}

$Headers = @{}

$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$Headers.Add("Content-Type","application/json")


# Calling Management API to set up the Azure Sentinel solution
try {
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationsManagement/solutions/SecurityInsights($WorkspaceName)?api-version=2015-11-01-preview"

    Invoke-webrequest -Uri $uri -Method Put -Headers $Headers -Body ($scbody | ConvertTo-Json)
}
catch {
    $errorReturn = $_
    $errorResult = ($errorReturn | ConvertFrom-Json ).error
    Write-Error "Unable to enable Sentinel on $WorkspaceName with error message: $($errorResult.message)"

    exit
}

Write-Output "Successfully enabled Sentinel on workspace: $WorkspaceName"

# Deploying App Gateway with WAF connected to log analytics workspace

Write-Output "Creating Azure App Gateway..." 

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile AppGatewayDeployment.json
