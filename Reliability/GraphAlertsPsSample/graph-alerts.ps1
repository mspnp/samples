$subscriptionId = $args[0]

Write-Output 'This query searchs for alerts in a specific subscription'

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subscriptionId' "

Write-Output 'Same query but listing specific fields'

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subscriptionId' | project name, type, resourceGroup"

Write-Output 'Query alerts in a subscription and list their common properties'

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subscriptionId' | project properties"

Write-Output 'Query alerts in a subscription and list a specific common property'

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subscriptionId' | project properties.essentials.severity"

Write-Output 'In case you want to build a JSON object that contains the common alert metadata'

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subscriptionId' | project properties | summarize buildschema(properties)"

