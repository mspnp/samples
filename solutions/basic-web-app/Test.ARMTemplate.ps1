param (
    [Parameter()]
    [String]$TemplatePath
)
Test-AzTemplate -TemplatePath $TemplatePath -Pester