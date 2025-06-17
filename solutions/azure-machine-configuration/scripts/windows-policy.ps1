$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stpoliceswsoxw40.blob.core.windows.net/windowsmachineconfiguration/WindowsFeatures.zip'
  DisplayName   = 'Enable Windows Features - Web Server'
  Description   = 'Enable Windows Features - Web Server'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  LocalContentPath = '.\WindowsFeatures.zip'
  ManagedIdentityResourceId = '/subscriptions/132f0217-59d1-4c16-8b39-c3d71b36e521/resourceGroups/rg-far-machine-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-eastus'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines