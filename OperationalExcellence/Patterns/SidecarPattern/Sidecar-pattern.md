## Operational Excellence - The Sidecar Pattern in Kubernetes

The Sidecar pattern consists of adding a separate container with responsibilities that are required by your application (the main container), but are not necessarily part of the application itself, this container is attached to the main application and provides supporting features.

A good example of these features could be logging utilities and monitoring agents. It wouldn't make sense for a logging container to run while the application itself isn't running, that's why the sidecar and the parent container share the same lifecycle, being created and retired at the same time. Another benefit of decoupling these responsibilities is that if the logging or monitoring code is faulty it won't bring down the main application.

### Example

Consider this [Example YAML configuration](sidecar.yaml), it creates a Pod with two containers, the main application container which writes the current CPU usage % to a log file every ten seconds. The sidecar container hosts nginx and serves that log file.

### How to run the sample

Find file named sidecar.yaml in the sample's folder and run the pod:

```bash
kubectl apply -f sidecar.yaml
```

#### Once the pod is running, connect to the sidecar pod

```bash
kubectl exec sidecar-pattern-pod -c sidecar-container -it bash
```

#### Install curl on the sidecar

```bash
apt-get update && apt-get install curl
```

#### Use curl to access the log file via the sidecar

```bash
curl 'http://localhost:80/cpu-usage-log.txt'
```

### Note on Public Container Usage

This pattern's example yaml file pulls container images from a public registry. When implementing this or any pattern in production, always ensure you're pulling images from a container registry that meets your SLO requirements, such as an Azure Container Registry owned by your organization.
