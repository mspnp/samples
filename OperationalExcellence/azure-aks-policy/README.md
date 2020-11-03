--- 
page_type: sample
languages:
- azurecli
products:
- azure
---

# Azure Well Architected Framework Sample: Azure Policy for Azure Kubernetes Service (AKS)

Azure Policy extends Gatekeeper v3, an admission controller webhook for Open Policy Agent (OPA), to apply at-scale enforcements and safeguards on your clusters in a centralized, consistent manner. Azure Policy makes it possible to manage and report on the compliance state of your Kubernetes clusters from one place.

In this sample, an AKS cluster is deployed, a policy applied to the cluster that only allows specific images to run in the cluster, and some steps are detailed that you can follow to experience an Azure Policy protected AKS cluster.

## Deploy sample

**Azure portal**

To deploy this template using the Azure portal, click this button.

<br />

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fsamples%2Fmaster%2FOperationalExcellence%2Fazure-aks-policy%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>  

**Azure CLI**

Create a resource group for the deployment.

```azurecli
$ az group create --name azurePolicyDemo --location eastus
```

Run the following command to initiate the deployment.

```azurecli
$ az deployment group create \
    --resource-group azurePolicyDemo \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/OperationalExcellence/azure-aks-policy/azuredeploy.json
```

Connect with the AKS cluster.

```azurecli
$ az aks get-credentials --name azurePolicyDemo --resource-group azurePolicyDemo
```

Verify that policies have propagated to the cluster. This process could take up to 20 minutes.

```azurecli
$ kubectl get constrainttemplate

NAME                             AGE
k8sazurecontainerallowedimages   34s
k8sazurepodenforcelabels         33s
```

If you would like to run the command on a loop to visually indicate when policies have propagated down to the cluster, run the following command. You will see the message 'No resources found in default namespace' until the policies have propagated to your cluster.

```azurecli
$ while $true; do kubectl get constrainttemplate; sleep 5; done

No resources found in default namespace.
No resources found in default namespace.
No resources found in default namespace.
No resources found in default namespace.
NAME                             AGE
k8sazurecontainerallowedimages   6s
k8sazurepodenforcelabels         5s
```

## Policies

Two policies have been applied to the AKS cluster with this deployment. The first will deny the creation of any pods unless the specified container image equals _nginx_. The second one will raise a policy validation issue if the pod is not labeled with _DemoLabel = Demo_.

| Name | Value | Effect | 
|---|---|---|
| allowed-images| _nginx_ | Deny |
| pod-labels | _DemoLabel = Demo_ | Audit |

## Demo the solution

Create a pod using the `Ubuntu` image. Take note that the policy has denied pod creation.

```azurecli
$ kubectl run ubuntu --generator=run-pod/v1 --image ubuntu

Error from server ([denied by azurepolicy-container-allowed-images-1f8eb52bcdec7549c616] Container image ubuntu for container ubuntu has not been allowed.): admission webhook "validation.gatekeeper.sh" denied the request: [denied by azurepolicy-container-allowed-images-1f8eb52bcdec7549c616] Container image ubuntu for container ubuntu has not been allowed.
```

Create a pod using the `nginx` image. Because _nginx_ has been designated as an acceptable image, the pod is successfully created.

```azurecli
$ kubectl run nginx --generator=run-pod/v1 --image nginx
```

To see a policy compliance report, open the Azure portal and navigate to **Policy** > **Compliance**. Here you will see that the _pod-labels_ policy is non-compliant because the _nginx_ pod was not labeled as per the policy. Note, it can take up to 20 minutes for compliance results to reflect in the portal.

![](./images/compliance.png)

## Clean up demo

To remove the AKS cluster, run the following command.

```azurecli
$ az group delete --name azurePolicyDemo --yes --no-wait
```

You also need to remove the policy assignments; this can be done in the Azure portal or with these Azure CLI commands.

```azurecli
$ az policy assignment delete --name pod-labels --resource-group azurePolicyDemo
$ az policy assignment delete --name allowed-images --resource-group azurePolicyDemo
```

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.