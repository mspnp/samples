# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get Azure VM Resource ID
$rawbody = $Request.RawBody | ConvertFrom-Json
$vmResourceId = $rawbody.data.alertContext.AffectedConfigurationItems
$vm = $vmResourceId.Split('/')

write-output "==========="
write-output $vm
write-output "==========="

# Get function identity credentials
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=https%3A%2F%2Fmanagement.azure.com%2F&api-version=2019-08-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

$resourceGroupName = "RestTest"
$vmName = "windows-vm"
$subscriptionId = "3762d87c-ddb8-425f-b2fc-29e5e859edaf"

$RunCommandApiUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$VMName/runCommand?api-version=2020-06-01"

$Body = @{
    commandId = "RunPowerShellScript"
    script = @("Start-Service w3svc")
}

Invoke-RestMethod -Method Post -Uri $RunCommandApiUri -Headers @{ Authorization ="Bearer $accessToken"} -Body ($Body | ConvertTo-Json) -ContentType 'application/json'