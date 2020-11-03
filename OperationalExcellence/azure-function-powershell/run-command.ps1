<#
 .DESCRIPTION
    Returns a list of Resource Groups

 .NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate accessing Azure .via REST endpoint
 #>

# Get Azure secrets from Key Vault
$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$ClientId = "a0b6351a-f319-4d35-b666-7bce9d6133f6"
$ClientSecret = "pf-m8tXVB~l~GOSM7PBCelRVVHwzK3SlA5"
$SubscriptionId = "3762d87c-ddb8-425f-b2fc-29e5e859edaf"

# VM Details
$resourceGroupName = "rfefreferhrthb"
$VMName = "windows-vm"

# Acquire an access token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$Body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Body -ContentType 'application/x-www-form-urlencoded'

# Query RG Endpoint
$RunCommandApiUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$VMName/runCommand?api-version=2020-06-01"
$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$Body = @{
    commandId = "RunPowerShellScript"
    script = @("Start-Service w3svc")
}

Invoke-RestMethod -Method Post -Uri $RunCommandApiUri -Headers $Headers -Body ($Body | ConvertTo-Json) -ContentType 'application/json'
