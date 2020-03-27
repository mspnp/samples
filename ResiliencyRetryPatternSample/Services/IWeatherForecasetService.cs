using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace RetryPatternSample.Services
{
 public interface IWeatherForecasetService
 {
  Task<IEnumerable<WeatherForecast>> GetSummaries();
 }
}
