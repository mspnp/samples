using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Polly;
using System;
using System.Net;
using System.Net.Http;

namespace RetryPatternSample
{
 public class Startup
 {
  public Startup(IConfiguration configuration)
  {
   Configuration = configuration;
  }

  private ILogger<Startup> _logger;

  public IConfiguration Configuration { get; }

  // This method gets called by the runtime. Use this method to add services to the container.
  public void ConfigureServices(IServiceCollection services)
  {
   //429 - Throttling 
   var retryWhenThrottling = Policy
       .HandleResult<HttpResponseMessage>(r => r.StatusCode == HttpStatusCode.TooManyRequests)
       .WaitAndRetryAsync(2, retryAttempt => TimeSpan.FromSeconds(Math.Pow(5, retryAttempt)));

   //408 - Timeout
   var retryWhenTimeout = Policy
       .HandleResult<HttpResponseMessage>(r => r.StatusCode == HttpStatusCode.RequestTimeout)
       .WaitAndRetryAsync(1, retryAttempt => TimeSpan.FromSeconds(5));

   //503 or 5xx service unavailable
   var retryWhenServiceUnavailable = Policy
       .HandleResult<HttpResponseMessage>(r => r.StatusCode == HttpStatusCode.ServiceUnavailable)
       .WaitAndRetryAsync(1, retryAttempt => TimeSpan.FromSeconds(10));

   //401 unauthorized
   var retryWhenUnauthorized = Policy
       .HandleResult<HttpResponseMessage>(r => r.StatusCode == HttpStatusCode.Unauthorized)
       .RetryAsync(1, (exception, retryCount) =>
       {
         
         this._logger.LogError($"Error occurred retry attempt: {retryCount}, Error details: {exception.ToString()}");
         //Do some logic here like:
         //RenewAccessToken();
        });

   IAsyncPolicy<HttpResponseMessage> policyWrap = Policy.WrapAsync(retryWhenThrottling, retryWhenTimeout, retryWhenServiceUnavailable, retryWhenUnauthorized);

   services.AddHttpClient("SampleService", client =>
   {
    client.BaseAddress = new Uri(@"https://www.googleapis.com");
    client.DefaultRequestHeaders.Add("Accept", "application/json");
   }).AddPolicyHandler(policyWrap);

   services.AddControllers();
  }

  // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
  public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
  {
   this._logger = logger;

   if (env.IsDevelopment())
   {
    app.UseDeveloperExceptionPage();
   }

   app.UseHttpsRedirection();

   app.UseRouting();

   app.UseAuthorization();

   app.UseEndpoints(endpoints =>
   {
    endpoints.MapControllers();
   });
  }
 }
}
