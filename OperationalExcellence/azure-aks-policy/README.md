--- 
page_type: sample
languages:
- azurecli
products:
- azure
- azure kubernetes service
---

# Azure Well Architected Framework Sample (Secure AKS Cluster Pods with Azure Policy)

Azure Policy extends Gatekeeper v3, an admission controller webhook for Open Policy Agent (OPA), to apply at-scale enforcements and safeguards on your clusters in a centralized, consistent manner. Azure Policy makes it possible to manage and report on the compliance state of your Kubernetes clusters from one place.

In this sample, an AKS cluster is deployed, a policy applied to the cluster that only allows specific images to run in the cluster, and some steps are detailed that you can follow to experience Azure Policy protected AKS cluster.

## Deploy sample

**Azure portal**

To deploy this template using the Azure portal, click this button.  

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fsamples%2Fazure-function-powershell%2FOperationalExcellence%2Fazure-aks-policy%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>  

**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name aks-azure-policy --location eastus
```

Run the following command to initiate the deployment.

```azurecli
az deployment group create \
    --resource-group aks-azure-policy \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/aks-azure-policy/OperationalExcellence/azure-aks-policy/azuredeploy.json
```

Verify that policies have propagated to the cluster. This process could take up to 20 minutes.

```azurecli
kubectl get constrainttemplate
```

If you would like to run the command on a loop to visually indicate when policies have propagated down to the cluster, run the following command.

```azurecli
while $true; do kubectl get constrainttemplate; sleep 5; done
```

Alternatively, a little hack to speed up the process is to delete the `gatekeeper-controller` pods. This operation can be done by deleting all pods with the `gatekeeper.sh/operation=webhook` label.

```azurecli
kubectl delete pods -l gatekeeper.sh/operation=webhook -n gatekeeper-system
```

Now return a list of `constrainttemplate` again, and you should see that the policy has now registered with the cluster.

```azurecli
$ kubectl get constrainttemplate
```

## Other Details

### Find the ID of the applied Azure Policy

It is possible to trace the applied Azure Policy from the cluster back to Azure. To see the details of the `constrainttemplate` object, run this command.

```azurecli
kubectl describe constrainttemplate k8sazurecontainerallowedimages
```

You will find an annotation on the `constrainttemplate` that includes the ID of the Azure Policy used to create it.

```yaml
Annotations:  azure-policy-definition-id: /providers/Microsoft.Authorization/policyDefinitions/febd0533-8e55-448f-b837-bd0e06f16469
```

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.