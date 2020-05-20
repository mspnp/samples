using CPUstressWebApp.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;

namespace CPUstressWebApp.Controllers
{
 public class HomeController : Controller
 {
  private readonly ILogger<HomeController> _logger;

  public HomeController(ILogger<HomeController> logger)
  {
   _logger = logger;
  }

  public IActionResult Index()
  {
   return View(new RunViewModel { Minutes = 1 });
  }

  [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
  public IActionResult Error()
  {
   return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
  }

  [HttpPost]
  public async Task<IActionResult> CpuSpike(RunViewModel runViewModel)
  {

   Task.Run(() => GenerateCpuSpike(runViewModel));

   TempData["CpuSpikeTriggered"] = true;
   return View("Index");
  }


  private static void GenerateCpuSpike(RunViewModel viewmodel)
  {
   int cpuUsage = 99;
   int time = viewmodel.Minutes * 60 * 1000;
   CancellationTokenSource cs = new CancellationTokenSource();
   CancellationToken ct = cs.Token;

   Tuple<int, CancellationToken> parameters = new Tuple<int, CancellationToken>(cpuUsage, cs.Token);

   List<Thread> threads = new List<Thread>();
   for (int i = 0; i < Environment.ProcessorCount; i++)
   {
    var t = new Thread(
           () => ConsumeCPU(cpuUsage, ct));

    t.Start();
    threads.Add(t);
   }
   Thread.Sleep(time);
   cs.Cancel();

  }
  private static void ConsumeCPU(int cpuUsage, CancellationToken ct)
  {
   Parallel.For(0, 1, new Action<int>((int i) =>
   {
    Stopwatch watch = new Stopwatch();
    watch.Start();
    int threadcount = 0;
    while (!ct.IsCancellationRequested)
    {
     threadcount++;
     if (watch.ElapsedMilliseconds > cpuUsage)
     {
      Thread.Sleep(100 - cpuUsage);
      watch.Reset();
      watch.Start();
     }
    }
   }));
  }
 }
}
