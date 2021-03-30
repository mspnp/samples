# Generic file used for running ARM TTK test using Pester the Invoke-Pester command.

param (
    [Parameter()]
    [String]$TemplatePath,
    [array]$skipTests = "DependsOn-Best-Practices","IDs-Should-Be-Derived-From-ResourceIDs"
)

$tests = @('DependsOn-Best-Practices';'IDs-Should-Be-Derived-From-ResourceIDs')

Test-AzTemplate -TemplatePath $TemplatePath -Skip $skipTests -Pester 