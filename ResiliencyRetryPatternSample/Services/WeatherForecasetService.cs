using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace RetryPatternSample.Services
{
 public class WeatherForecasetService: IWeatherForecasetService
 {
  private static readonly string[] Summaries = new[]
  {
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
  };

  public async Task<IEnumerable<WeatherForecast>> GetSummaries()
  {
   //simulate some delay and a connectionClosed exception randomly generated when temperature is below 50 C
   await Task.Delay(1000);

   var rng = new Random();
   var temperatureC = rng.Next(-100, 55);

   if (temperatureC < -30)
   {
    throw new WebException("Connection closed exception", WebExceptionStatus.ConnectionClosed);
   }

   return Enumerable.Range(1, 5).Select(index => new WeatherForecast
   {
    Date = DateTime.Now.AddDays(index),
    TemperatureC = temperatureC,
    Summary = Summaries[rng.Next(Summaries.Length)]
   })
   .ToArray();
  }
 }
}
