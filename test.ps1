# using namespace System.Net

# # Input bindings are passed in via param block.
# param($Request, $TriggerMetadata)

# # Write to the Azure Functions log stream.
# Write-Host "PowerShell HTTP trigger function processed a request."

# # Get Azure VM Resource ID
# $rawbody = $Request.RawBody | ConvertFrom-Json
# $vmResourceId = $rawbody.data.alertContext.AffectedConfigurationItems
# $vm = $vmResourceId.Split('/')

# Create script within function and run on VM
[System.String]$ScriptBlock = {Start-Service w3svc}
$scriptFile = "RunScript.ps1"
Out-File -FilePath $scriptFile -InputObject $ScriptBlock -NoNewline

try {
    $InvokeCommandResult = Invoke-AzVMRunCommand -ResourceGroupName AZUREMONITORNINER001 -Name windows-vm -CommandId 'RunPowerShellScript' -ScriptPath $scriptFile -ErrorVariable badoutput -ErrorAction Stop
}
catch {
    write-output "-----"
    write-output $badoutput
}

# Remove-Item -Path $scriptFile -Force