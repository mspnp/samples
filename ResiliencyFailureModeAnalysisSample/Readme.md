---
title: AAF resiliency pillar - Error Handling - Cascading Failures
description: Sample to illustrate Failure mode Analysis
ms.date: 04/03/2020
author: Magrande
ms.topic: guide
ms.service: architecture-framework
ms.subservice: resiliency
ms.custom: application design
---

# Failure mode analysis
Failure mode analysis (FMA) is a process for building resiliency into a system, by identifying possible failure points in the system.

In this sample controller action you make a call to an external service. The web API is designed to include different retry strategies depending on the expected exceptions: 
   429 - Throttling 
   408 - Timeout
   503 or 5xx service unavailable
   401 unauthorized
   
This is done in startup class in the ConfigureServices method by using Polly library. (https://github.com/App-vNext/Polly)
PI