# Service Level Agreement Estimator sample

This is an example of how you can calculate the composite SLA of your architecture. This is React web application that can run locally and totally disconnected from the Internet; the data source is a local json file. By changing the `SLA_data.json` file you can add and remove services or modify the SLA values of the individual services using your own SLA numbers.

For more information about business metrics and how the composite SLA is calculated, refer to the [relibility pillar on the Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/resiliency/business-metrics#understand-service-level-agreements).

This project was bootstrapped with [Create React App](https://github.com/facebookincubator/create-react-app).

## Folder Structure

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

* `public/index.html` is the page template
* `src/index.js` is the JavaScript entry point
 

 ## How to use the SLA estimator
 

 The web application's user interface is similar to the Azure Pricing calculator, so if you are familiarized with it you will easily be able to create your own estimations. You can select your service categories from the menu on the left, when you select your category, the related services will display on the main panel. Alternatively you can serch for services by using the alphabetic search box.

 When you click on a service, you are selecting it and it will be added to the estimate section below. while you keep on adding services the composite estimate will be automatically calculated. Alternatively you can select in which tier you want the service to be included by using the tier dropdown list; so if you decide to include more than one tier you will see the composite SLA calculated per tier and the total composite SLA. There are predefined Tiers that you can use out of the box, but you can also remove and create new ones as needed.

 ## How to save your SLA estimation

 Your SLA estimation will be automatically saved to your browser's local storage, whenever you select and add a service to your estimation, it will be saved. If you close the browser and re-open it, you will still see your last changes.
 