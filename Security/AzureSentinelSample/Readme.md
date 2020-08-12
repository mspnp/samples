## Azure Sentinel Sample

In this sample you create an Azure Log Analytics workspace, which is required if you want to start collecting, analyzing, and taking action on data, and an Azure Sentinel on top of it. [Azure Sentinel](https://docs.microsoft.com/azure/sentinel/overview) is a cloud-native SIEM (security instant and event management) service that runs in Azure.

This powershell script makes use [PowerShell module for Azure Sentinel](https://github.com/wortell/AZSentinel) to setup the service. 

The script also installs an Azure Application Gateway as sample, after you run it you can manually configure a diagnostics setting to connect App Gateway to the Log Analytics Workspace installed before. Behind the scenes, you are connecting Azure Sentinel to the Azure Application Gateway’s web application firewall (WAF). This WAF protects your applications from common web vulnerabilities such as SQL injection and cross-site scripting, and lets you customize rules to reduce false positives.​

### Prerequisites
 - Powershell 6.2.4 or higher version
 - PowerShell Core
 - Powershell AZ Module - tested with version 2.4.0
 - An Azure subscription

### Instructions

