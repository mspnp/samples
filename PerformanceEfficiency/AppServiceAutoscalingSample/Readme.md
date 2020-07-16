## Application Service Autoscaling Sample

### Stress CPU scenario

In this sample you create an Azure App Service plan which includes an Azure App Service. Then you deploy a basic Asp.Net Core MVC application that you can use to simulate a CPU spike. The App Service plan is configured with a basic S1 SKU (1 core, 1.75 GB) to easily create the conditions for the autoscaling scenario. You can deploy the azure resources by publishing the Web Application, but it's recommended to use the provided ARM template since it has a set of custom autoscale rules.

#### Autoscale rules

For this scenario, the App Service plan Scale-out custom setting is configured with the following rule combination:

Increase instances by 1 count when CPU% > 80
Decrease instances by 1 count when CPU% <= 60


This margin between the scale-out and in and the threshold is recommended, consider this case:

Let's start with a single instance. When the CPU% usage is 81, the autoscaler adds another instance because the threshold is set at 80. 

Then, over time the CPU% falls to 60. The autoscaler's scale-in rule estimates the final state for scale-in. Taking the current instance count of 2, the CPU% is 120.  If scaled in it would be 120 for one instance. So the autoscaler does not scale-in because it would have to scale-out again immediately. 

The next time the autoscale checks, the CPU% usage is down to 30%. It estimates again. This time 30 x 2 instances = 60 per instance, which is below is the threshold of 80, so it scales in successfully to 1 instance.

The amount of time that the autoscaler checks for metrics is determined by the the duration, which is set to 5 minutes.  So, every time autoscale runs, it will query metrics for 5 minutes. This way the autoscaler can get stable metrics instead of reacting to transient spikes. 

 The instance limits are:  max 5 instances, min 1 instance. The cool down setting is set to 5 minutes. This setting is the amount of time to wait after a scale operation before scaling again. This value allows the metrics to stabilize.

 These settings may not be valid for a real scenario, but are intentionally set (in conjunction with a small SKU for the app service plan) to easily reproduce the autoscale conditions.

 #### Deployment instructions


#### Run these commands by using the Azure CLI from your computer. You need to run az login to log in to Azure. Make sure that you have a subscription associated with your Azure Account If the CLI can open your default browser, it will do so and load an Azure sign-in page. Otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.
<br><br>
1 - Log in to Azure.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az login
<br><br>
2 - Deploy the ARM template provided by the sample, you will need to have a resource group already created.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az deployment group create --resource-group [your resource-group-name] --template-file .\deploymentTemplate\AppServiceAutoScale.json
<br><br>
3 - Once the deployment has successfully completed go to the Azure Portal, you will see three new resources created under the resource group.

4 - Find the App Service called "PerfStressWebApp",  go to overview.

5 - Click on "Get Publish Profile" option in the upper toolbar, that will download the publish profile to your computer.

6 - Open the solution in Visual Studio, right click on the project named "PerfStressWebApp", select "Publish".

7 - Select the option "New", then click on the "Import Profile" button located at the bottom of the dialog.

8 - Find and select the publish profile file that you downloaded in step 5.

9 - Click on "Publish", that will publish the PerfStress Web App to the App Service.

10 - Once the Web App has been successfully published, a browser's window will show up with the web application's home page.

11 - The UI is simple, by clicking the "trigger CPU Spike" button, a 100% CPU usage spike will happen for a period of time of one minute by default, or the number of minutes selected in the "minutes to run" text box (ten minutes is recommended to have a spike long enough to see the scaling effect). This is a fire and forget action.

12 - Go back to the Azure portal, select the App Service Plan (PerfStressWebAppPlan), in the overview, view you will see the CPU percentage chart.

13 - In 5 minutes the CPU spike will be reflected in the chart.

14 - Once you see the CPU spike, select the setting "Scale Out (App Service Plan)" on the settings Menu on the left.

15 - Select "Run History" in the upper toolbar.

16 - In the run history view, you will see the number of instances increased to two, also you will see the operation called "Autoscale scale up completed" in the autoscale events.

17 - Now you need to wait for the CPU spike to finish, and then after the cool period has passed (5 more minutes), the "Autoscale scale down" operation will appear in the list of autoscale events, and the number of instances will decrease to one again.

### Networking stress scenario

In this sample you will need to create an Azure App Service plan which includes an Azure App Service. Then you deploy a basic Asp.Net Core MVC application that you can use to simulate a delayed HttpGet Action. The App Service plan is configured with a basic S1 SKU (1 core, 1.75 GB) to easily create the conditions for the autoscaling scenario. You can deploy the azure resources by publishing the Web Application, but it's recommended to use the provided ARM template since it has a set of custom autoscale rules.

To simulate load and stress test, use [the Apache JMeter™ application](https://jmeter.apache.org/). This tool is an open source software, designed to load test Web Applications and offers other test capabilities. You will use JMeter to simulate a heavy load on the App Service and analyze the response of the autoscaling engine and the configured rules. 

#### Autoscale rules

For this scenario, the App Service plan Scale-out custom setting is configured with the following rule combination:

Increase instances by 1 count when the sum of the HttpQueueLength metric > 8
Decrease instances by 1 count when the sum of the HttpQueueLength metric <= 4

The amount of time that the autoscaler checks for metrics is determined by the the duration, which is set to 1 minute.  So, every time autoscale runs, it will query metrics for a minute.  
The instance limits are:  max 5 instances, min 1 instance (for the deployed AppService Plan SKU you can set it up to 10 instances), and the cool down setting is set to 5 minutes as the time to wait between scaling operations. This allows the metrics to stabilize. These settings are not valid for a real scenario. They are intentionally set to reproduce the autoscale conditions.

#### HttpQueueLength metric

This metric represents the average number of HTTP requests waiting in the queue before being processed. A high or increasing HTTP Queue length is a symptom of a plan under heavy load.

#### SocketOutboundTimeWait 

The SocketOutboundTimeWait metric is a networking metric available for in the App Service custom autoscaling configuration. This metric represents the number of TCP connections in TIME_WAIT state. This metric can affect scalability because a socket in a TCP connection that is shut down cleanly will stay in the TIME_WAIT state for period of 4 minutes. If many connections are being opened and closed quickly then socket's in TIME_WAIT may begin  to accumulate. There are a finite number of socket connections that can be established at one time and is impacted by the number of available local ports . If too many sockets are in TIME_WAIT you will find it difficult to establish new outbound connections and you will need to tune your App Service plan scale out settings and prevent the system reaching the limits.


#### Download and configure JMeter

1. Download JMeter from [this link](https://downloads.apache.org//jmeter/binaries/apache-jmeter-5.3.zip) (Requires Java 8+), and install it in you computer. 
2. Find the JMeter windows batch file (JMeter.bat) in the /Bin folder. Double click the .bat file. A command prompt window will open. JMeter will run on this window. Also, the JMeter UI is shown. You will use this UI to create a Test Plan.

#### Create a JMeter Test Plan

1) Create a thread group

    In the JMeter UI, an empty test plan is created by default. 
    On the left tree, right click **TestPlan** -> **Add** -> **Threads** -> **Thread Group**. Enter a name for the new thread group. From the **Action to be taken after a sample error** setting, select **Continue**.

2) Thread properties

    Number of Threads: 700. This will simulate a number of users hitting your app service endpoint simultaneously.

    Ramp-up period: Default value of 1 second. Determines the time taken  to ramp-up to the full number of threads.

    Loop count setting: Select a high number of loops or set it to infinite. If you choose infinite, you can stop the run with the stop button in the UI.

    Same user on each iteration setting: By checking this box, cookies in the first response are used for the following requests.

    Delay Thread Creation Until Needed: By checking this option, the ramp-up delay and startup delay are performed before the thread data is created. If not checked, all the data required for threads is created before starting the execution of a test
    
    Specify thread lifetime: Use this setting if you want to schedule and manage the thread's lifetime

3) Add the HTTP sampler

    Right-click on the Thread Group in the left tree, select **Add** -> **Sampler** -> **HTTP Request**. Enter a name for the HTTP Request and description in the comments box. 

    Provide the server name of the App Service  to load test. For this scenario, enter  "perfstresswebapp.azurewebsites.net" in **Server Name or IP**.

    Enter /Values in **Path** as the path of the controller's action that simulates a web application having some delays. In this scenario there are no URL parameters but alternatively you can add them to the parameters list below.

    Keep the other default options (Http Request should be GET).

4) Add a View Results window

    Right-click the HTTP Request added to the left tree and select **Add** -> **Listener** -> **View Results Tree**. After you run the load test, you can view results in this window.  

5) Add a response assertion

    Optional. Right-click the HTTP request on the left tree. Select **Add** -> **Assertions** -> **Response Assertions**. For example, you can add a 200 response assertion. The entire test plan will fail if any of the HTTP requests receive a response with a response code other than 200. Use the patterns to test section and click on the **Add** button, enter 200 and add the row to the list.

5) Save the test plan

    Save the test plan in a folder of your choice. The extension for JMeter is ".jmx". 
    
    Your test plan is now ready to run.



#### Deployment instructions

*If you already ran the CPU stress scenario, you can skip steps 1-10 and go to the JMeter running section below*

> Run these commands by using the Azure CLI from your computer. You need to run az login to log in to Azure. Make sure that you have a subscription associated with your Azure Account If the CLI can open your default browser, it will do so and load an Azure sign-in page. Otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.
<br><br>
1 - Log in to Azure.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az login
<br><br>
2 - Deploy the ARM template provided by the sample, you will need to have a resource group already created.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az deployment group create --resource-group [your resource-group-name] --template-file .\deploymentTemplate\AppServiceAutoScale.json
<br><br>
3 - Once the deployment has successfully completed go to the Azure Portal, you will see three new resources created under the resource group.

4 - Find the App Service called "PerfStressWebApp",  go to overview.

5 - Click on "Get Publish Profile" option in the upper toolbar, that will download the publish profile to your computer.

6 - Open the solution in Visual Studio, right click on the project named "PerfStressWebApp", select "Publish".

7 - Select the option "New", then click on the "Import Profile" button located at the bottom of the dialog.

8 - Find and select the publish profile file that you downloaded in step 5.

9 - Click on "Publish", that will publish the PerfStress Web App to the App Service.

10 - After the web application has been successfully published, a browser's window will show up with the application's home page.


#### Run the JMeter test plan

There are two ways of running the test plan. 
- Use the GUI. You have buttons for starting, stopping, clearing the results and monitoring you HTTP requests in the results view (you will see green successful requests or red failed ones). 
- Recommended. Use the CLI mode instead for better performance, leaving the GUI for Test creation and Test debugging.

For load testing using CLI Mode, use this command:

```Azure CLI
   jmeter -n -t [jmx file] -l [results file] -e -o [Path to web report folder]
```

See the test plan results on the results file.

Check the [JMeter Best Practices](https://jmeter.apache.org/usermanual/best-practices.html) for more information.


### Autoscale verification

 - After some time, the number of Http requests or outbound sockets in wait time is going to increase. From the Azure portal, find the App Service named "PerfStressWebApp" in your resource group. Select **Scale Out (App Service Plan)** on the left.

- Select **Run History** in the top toolbar.

- In the run history view, verify that the number of instances have been increased to 2. There should be an operation named **Autoscale scale up completed** in the autoscale events.

- After the scale up operation has completed, continue watching the autoscale events, and then after the cool period has passed (5 more minutes), the **Autoscale scale down** operation will appear in the list of autoscale events, and the number of instances will decrease to 1.


Alternatively, you can query the current number of instances by running this Az CLI command

```Azure CLI
   az appservice plan show --name PerfStressWebAppPlan --resource-group [your resource-group-name]
```

The output of this command is a json structure, you should see the number of instances ("capacity": 2) in the "sku" section:

  "sku": {
    "capabilities": null,
    "capacity": 2,
    "family": "S",
    "locations": null,
    "name": "S1",
    "size": "S1",
    "skuCapacity": null,
    "tier": "Standard"
  },


To learn more about autoscaling, check the [Autoscale best practises](https://docs.microsoft.com/azure/azure-monitor/platform/autoscale-best-practices)
