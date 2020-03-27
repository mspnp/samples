using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using RetryPatternSample.Services;

namespace RetryPatternSample.Controllers
{
 [ApiController]
 [Route("[controller]")]
 public class WeatherForecastController : ControllerBase
 {
  private readonly ILogger<WeatherForecastController> _logger;
  private IWeatherForecasetService _service;
  private const int maxRetries = 5;
  private TimeSpan delay = TimeSpan.FromSeconds(5);

  public WeatherForecastController(ILogger<WeatherForecastController> logger, IWeatherForecasetService service)
  {
   _logger = logger;
   _service = service;
  }


  [HttpGet]
  public async Task<IEnumerable<WeatherForecast>> Get()
  {

   int currentRetry = 0;

   for (; ; )
   {
    try
    {
     // Call weather service.
     return await _service.GetSummaries();
    }
    catch (Exception ex)
    {
     _logger.LogError("Operation Exception");
 

     currentRetry++;

     // Check if the exception thrown was a transient exception
     if (currentRetry > maxRetries || !IsTransient(ex))
     {
      throw;
     }
    }

    // Wait to retry the operation.
    // Increment the delay in every retry
    _logger.LogInformation($"Transient error, retrying... attempt #{ currentRetry }");

    // Add # of retries as seconds to current delay
    delay = TimeSpan.FromSeconds(5 + currentRetry);

    await Task.Delay(delay);
   }
  }

  private static bool IsTransient(Exception ex)
  {
   // Determine if the exception is transient.

   var webException = ex as WebException;
   if (webException != null)
   {
    
    return new[] {WebExceptionStatus.ConnectionClosed,
                  WebExceptionStatus.Timeout,
                  WebExceptionStatus.RequestCanceled }.
            Contains(webException.Status);
   }

   return false;
  }
 }
}
