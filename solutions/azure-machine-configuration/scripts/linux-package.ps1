# Create a package that will only audit compliance
$params = @{
    Name          = 'NginxInstall'
    Configuration = './NginxInstall/localhost.mof'
    Type          = 'AuditAndSet'
    Version       = '1.0.0'
    Force         = $true
}
New-GuestConfigurationPackage @params