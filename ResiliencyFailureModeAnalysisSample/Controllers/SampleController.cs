using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;

namespace FailureModeAnalysisSample.Controllers
{
 [ApiController]
 [Route("[controller]")]
 public class SampleController : ControllerBase
 {
  private readonly ILogger<SampleController> _logger;
  private readonly IHttpClientFactory _httpClientFactory;

  public SampleController(ILogger<SampleController> logger, IHttpClientFactory httpClientFactory)
  {
   _logger = logger;
   _httpClientFactory = httpClientFactory;
  }


  [HttpGet]
  public async Task<ActionResult> Get()
  {
   var httpClient = _httpClientFactory.CreateClient("SampleService");

   HttpResponseMessage httpResponseMessage = await httpClient.GetAsync("<your operation. i.e. users?_format=json>");
   var content = await httpResponseMessage.Content.ReadAsStringAsync();

   if (httpResponseMessage.IsSuccessStatusCode)
   {
    return Ok(content);
   }
   
   _logger.LogError(content);
   return StatusCode((int)httpResponseMessage.StatusCode, content);
  }
 }
}