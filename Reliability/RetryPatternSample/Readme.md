---
title: AAF resiliency pillar - Error Handling - Cascading Failures
description: Sample to illustrate the retry pattern
ms.date: 03/26/2020
author: Magrande
ms.topic: guide
ms.service: architecture-framework
ms.subservice: resiliency
ms.custom: data-managemt
---

# Retry pattern example

This example in C# shows a simple custom implementation of the Retry pattern. The retry logic is implemented in the WeatherForecastController when asynchronously invoking the corresponding WeatherForcastService which randomly simulates a ConnectionClosed exception, considered transient by the controller's logic.
