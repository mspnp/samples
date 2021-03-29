param (
    [Parameter()]
    [String]$TemplatePath = "D:\a\1\s/solutions/basic-web-app/azuredeploy.json"
)
Test-AzTemplate -TemplatePath $TemplatePath -Pester