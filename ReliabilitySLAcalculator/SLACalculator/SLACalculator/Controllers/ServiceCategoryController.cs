using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SLACalculator.Models;

namespace SLACalculator.Controllers
{
 [ApiController]
 [Route("[controller]")]
 public class ServiceCategoryController : ControllerBase
 {
  private readonly ILogger<ServiceCategoryController> _logger;

  public ServiceCategoryController(ILogger<ServiceCategoryController> logger)
  {
   _logger = logger;
  }

  [HttpGet]
  public async Task<IEnumerable<ServiceCategory>> Get()
  {
   using (FileStream fs = System.IO.File.OpenRead(@"Data/SLA_data.json"))
   {
    return await JsonSerializer.DeserializeAsync<ServiceCategory[]>(fs);
   }
  }
 }
}
