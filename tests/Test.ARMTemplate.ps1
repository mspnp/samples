# Generic file used for running ARM TTK test using Pester the Invoke-Pester command.

param (
    [Parameter()]
    [String]$TemplatePath,
    [string]$skipTests = "DependsOn-Best-Practices,IDs-Should-Be-Derived-From-ResourceIDs"
)

# $tests = @('DependsOn-Best-Practices';'IDs-Should-Be-Derived-From-ResourceIDs')

$ab = $skipTests.split(',')

Test-AzTemplate -TemplatePath $TemplatePath -Skip $ab -Pester 