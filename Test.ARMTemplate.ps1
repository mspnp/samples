# Generic file used for running ARM TTK test using Pester the Invoke-Pester command.

param (
    [Parameter()]
    [String]$TemplatePath
)
Test-AzTemplate -TemplatePath $TemplatePath -Pester