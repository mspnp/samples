<#
 .DESCRIPTION
    Returns a list of Resource Groups

 .NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate accessing Azure .via REST endpoint
 #>

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get an access token for managed identities for Azure resources
$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -Headers @{Metadata="true"}
$content =$response.Content | ConvertFrom-Json
$access_token = $content.access_token

$resourceGroupName = "RestTest"
$vmName = "windows-vm"
$subscriptionId = "3762d87c-ddb8-425f-b2fc-29e5e859edaf"

$RunCommandApiUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$VMName/runCommand?api-version=2020-06-01"

$Body = @{
    commandId = "RunPowerShellScript"
    script = @("Start-Service w3svc")
}

Invoke-RestMethod -Method Post -Uri $RunCommandApiUri -Headers @{ Authorization ="Bearer $access_token"} -Body ($Body | ConvertTo-Json) -ContentType 'application/json'