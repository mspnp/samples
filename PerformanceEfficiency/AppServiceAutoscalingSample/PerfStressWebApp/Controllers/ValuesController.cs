using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace PerfStressWebApp.Controllers
{
/// <summary>
/// Sample controller HttpGet action to simulate some delayed response.
/// </summary>
 public class ValuesController : Controller
 {

  private static readonly string[] DaysOfWeek = new[]
  {
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
  };

  [HttpGet]
  public async Task<ActionResult> Index()
  {
   await Task.Delay(1000);

   return Ok(DaysOfWeek);
  }
 }
}
