# Generic file used for running ARM TTK test using Pester the Invoke-Pester command.

param (
    [Parameter()]
    [String]$TemplatePath,
    [string]$skipTests
)

$skip = $skipTests.split(',')
Test-AzTemplate -TemplatePath $TemplatePath -Skip $skip -Pester 