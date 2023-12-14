# Failure mode analysis

Failure mode analysis (FMA) is a process for building resiliency into a system, by identifying possible failure points in the system. This sample is used as part of the [Failure mode analysis for Azure applications](https://learn.microsoft.com/azure/architecture/resiliency/failure-mode-analysis) article in the Azure Architecture Center.

In this sample controller action you make a call to an external service. The web API is designed to include different retry strategies depending on the expected exceptions: 

- 429 - Throttling 
- 408 - Timeout
- 503 or 5xx service unavailable
- 401 unauthorized
   
This is done in startup class in the ConfigureServices method by using Polly library. (https://github.com/App-vNext/Polly)
