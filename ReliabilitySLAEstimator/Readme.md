# Service Level Agreement Estimator sample

This sample shows you how to calculate the composite SLA of your architecture. This is React web application. It can run locally and disconnected from the internet because the data source is a local json file. By changing the SLA_data.json file you can add, remove services, or modify the SLA values of individual services using your own SLA numbers.

For more information about business metrics and how the composite SLA is calculated, refer to the [relibility pillar on the Azure Well Architected Framework](https://docs.microsoft.com/azure/architecture/framework/resiliency/business-metrics#understand-service-level-agreements)

This project was bootstrapped with [Create React App](https://github.com/facebookincubator/create-react-app).

### Folder Structure

After downloading and opening the solution your project should look like this:

```
ClientApp/
  node_modules/
  package.json
  public/
    index.html
    favicon.ico
    public/images/
        png files
        ...
  src/
    App.js
    App.test.js
    custom.css
    index.js
  src/components/
        Home.js
        MainPanel.js
        Navigation.js
        SearchBar.js
        ...
  Controllers/
        ServiceCategoryController.cs
  Data/
    SLA_data.json
  Models/
    Service.cs
    ServiceCategory.cs
  Pages/
    

```

For the project to build, **these files must exist with exact filenames**:

* `public/index.html` is the page template;
* `src/index.js` is the JavaScript entry point.
 

 ## How to use the SLA estimator?
 
 The web application's user interface is similar to the [Azure Pricing calculator](https://azure.microsoft.com/pricing/calculator). Here are some key features:
 - Select an Azure categories from the menu on the left.
 - Choose from the list of related services on the main panel. Alternatively you can search for services by using the alphabetic search box.
 - When you choose a service, it's added to the estimate section below. If keep adding services the composite estimate will be automatically calculated. Alternatively you can select in which tier you want the service to be included by using the tier dropdown list. If you decide to include more than one tier, you will see the composite SLA calculated per tier and the total composite SLA.

 ## How to save your SLA estiamation

 You SLA estimation will be automatically saved to your browser's local storage when you select and add a service to you estimation. If you close you browser and re-open it you will see you last changes.

