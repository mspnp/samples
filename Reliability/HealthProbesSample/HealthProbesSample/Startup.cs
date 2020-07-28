using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using System.Data.SqlClient;

namespace ResiliencyHealthProbesSample
{
 public class Startup
 {
  public Startup(IConfiguration configuration)
  {
   Configuration = configuration;
  }

  public IConfiguration Configuration { get; }

  // This method gets called by the runtime. Use this method to add services to the container.
  public void ConfigureServices(IServiceCollection services)
  {
   services.AddControllers();

   services.AddHealthChecks()
     .AddCheck("sql", () => {

      ///Perform your health check here. This sample considers the service unhealthy 
      ///if it can't connect to the configured default database
      /// by using  app.UseHealthChecks("/Health");
      /// You configure the health check path
      /// Use that path when configuring the load balancer health probes

      var connectionString = ConfigurationExtensions.GetConnectionString(this.Configuration, "DefaultConnection");

      using (var connection = new SqlConnection(connectionString))
      {
       try
       {
        connection.Open();
       }
       catch (SqlException)
       {
        return HealthCheckResult.Unhealthy();
       }
      }

      return HealthCheckResult.Healthy();

     });
  }

  // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
  public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
  {
   if (env.IsDevelopment())
   {
    app.UseDeveloperExceptionPage();
   }

   app.UseHttpsRedirection();

   app.UseRouting();

   app.UseAuthorization();

   app.UseHealthChecks("/Health");

   app.UseEndpoints(endpoints =>
   {
    endpoints.MapControllers();
   });
  }
 }
}
