# Create a package that will only audit compliance
$params = @{
    Name          = 'WindowsFeatures'
    Configuration = './windowsfeatures/localhost.mof'
    Type          = 'AuditAndSet'
    Version       = '1.0.0'
    Force         = $true
}
New-GuestConfigurationPackage @params