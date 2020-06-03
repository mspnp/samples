using System;
using System.Net.Http;
using System.Threading;

namespace StressAppServiceConsole
{

/// <summary>
/// Use this sample client app to stress the App Service front end. If you want
/// you run more than one instance concurrently. Right click on the project and 
/// select 'Debug', then 'start new instance'.
/// The app is going to run for a period of ten minutes, sending HTTP GET requests
/// in separate threads.
/// </summary>
 class Program
 {
  static void Main(string[] args)
  {
   int time = 600 * 1000;
   CancellationTokenSource cs = new CancellationTokenSource();
   CancellationToken ct = cs.Token;

  //Update the value according to your endpoint's url
   var url = "https://perfstresswebapp.azurewebsites.net/values";


   for (int i = 0; i < Environment.ProcessorCount; i++)
   {
    var t = new Thread(
           () => ProcessRequest(url, ct));

    t.Start();
   }
   Thread.Sleep(time);
   cs.Cancel();
  }

  async static void ProcessRequest(string url, CancellationToken ct)
  {
   HttpClient client = new HttpClient();

   while (!ct.IsCancellationRequested)
   {
    var result = client.GetByteArrayAsync(url).Result;
   }
  }

 }
}
