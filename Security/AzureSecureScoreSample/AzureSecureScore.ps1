param ($TenantId, $ClientId, $ClientSecret, $Resource, $SubscriptionId)


$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"

$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"

$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

Write-Host "Print Token" -ForegroundColor Green

Write-Output $Token

# List secure scores for all your Security Center initiatives within your current scope.
$SecureScoreApiUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/secureScores?api-version=2020-01-01-preview"

$Headers = @{}

$method = "GET"

$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")

$query = Invoke-WebRequest -Method $method -Uri $SecureScoreApiUri -ContentType "application/json" -Headers $Headers -ErrorAction Stop 

Write-Host "Azure Secure Score saved to file AzureSecureScore.json `n" -ForegroundColor Green


$query.content | Out-File "AzureSecureScore.json"

write-host -Foregroundcolor green "`nScript Completed`n"

