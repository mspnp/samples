---
title: AAF resiliency pillar - Error Handling - Application Health Probes
description: Sample to illustrate the retry pattern
ms.date: 03/30/2020
author: Magrande
ms.topic: guide
ms.service: architecture-framework
ms.subservice: resiliency
ms.custom: error-handling
---

## Health Probes Sample

This example includes an ARM deployment template for setting up the infrastructure.

A Load Balancer is configured to accept public requests and load balance to an availability set of virtual machines.
The health probe is set up so that it check for service's path /Health.

The provided .net core web api code is a simple demostration of how health check can be configured at startup



### Instructions


Deploy the Provided Azure template .\AzureDeploymentTemplates\AzureHealthProbesTemplate.json, by using this PS command:

New-AzResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName <ResourceGroup> -TemplateFile AzureHealthProbesTemplate.json


After deployment is done you will have two virtual machines configured in the backend pool of the load balancer.

Connect to the virtual machine by using [Azure Bastion](https://docs.microsoft.com/azure/bastion/bastion-connect-vm-rdp)

Install IIS feature

Open Windows defender firewall and add an InBound rule to allow TCP port 80 incoming requests

Alternatively you can edit image under c:\inetpub\wwwroot\iisstart image and add the VM name so you know which virtual machine is being targeted

Restart the VM

Do this procedure in both VMs


Open the .net core solution under "ResiliencyHealthProbesSample" using VS 2019

Edit the connection string in appsettings.json, so it points to an existing SQL Azure database server.

The Sample checks for a valid SQl connection to consider the service as healthy

Publish the Web API Service to both VMs, by follwing [these instructions](https://docs.microsoft.com/en-us/azure-stack/user/azure-stack-dev-start-howto-vm-dotnet?view=azs-2002)

Use the Load Balancer's public IP address to run the application.
