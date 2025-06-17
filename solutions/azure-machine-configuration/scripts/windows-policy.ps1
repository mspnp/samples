$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://<st_name>.blob.core.windows.net/windowsmachineconfiguration/WindowsFeatures.zip'
  DisplayName   = 'Enable Windows Features - Web Server'
  Description   = 'Enable Windows Features - Web Server'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  LocalContentPath = '.\WindowsFeatures.zip'
  ManagedIdentityResourceId = '/subscriptions/xxx/resourceGroups/rg-machine-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-download-eastus'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines