# Generic file used for running ARM TTK test using Pester the Invoke-Pester command.

param (
    [Parameter()]
    [String]$TemplatePath
    [String[]]$Skip
)
Test-AzTemplate -TemplatePath $TemplatePath -Skip $Skip -Pester 