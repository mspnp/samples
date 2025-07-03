$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://<st_name>.blob.core.windows.net/azuremachineconfiguration/NginxInstall.zip'
  DisplayName   = 'Enable Nginx on Linux VMs'
  Description   = 'Enable Nginx on Linux VMs'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  LocalContentPath = '.\NginxInstall.zip'
  ManagedIdentityResourceId = '/subscriptions/xxx/resourceGroups/rg-machine-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-download-eastus'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines