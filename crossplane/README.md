# Crossplane

## Install

### CLI

To install **Crossplane** CLI use the folowing commandds

```bash
# Install specific version (use 'current' for latest stable)
export CROSSPLANE_CHANNEL=stable
export CROSSPLANE_VERSION=v1.7.0
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | CHANNEL=$CROSSPLANE_CHANNEL VERSION=$CROSSPLANE_VERSION sh
sudo mv kubectl-crossplane /usr/local/bin

# Verify the installation
kubectl crossplane -v
```

### Cluster

To install **Crossplane** Helm procedure will be used.

```bash
# https://crossplane.io/docs/v1.7/reference/install.html

# Add Crossplane helm Chart repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Get current version
helm search repo crossplane-stable 

# Install Crossplane using
helm install crossplane -n crossplane-system --create-namespace crossplane-stable/crossplane --version 1.7.0 --wait
```

## Configuration

### Providers

https://crossplane.io/docs/v1.7/api-docs/overview.html

The Crossplane ecosystem contains many CRDs that map to API types represented by external infrastructure **providers**. The documentation for these CRDs are auto-generated on `doc.crds.dev`. To find the CRDs available for providers maintained by the Crossplane organization, you can search for the Github URL, or append it in the `doc.crds.dev` URL path (`crossplane` or `crossplane-contrib`). i.e. https://doc.crds.dev/github.com/crossplane/provider-aws or https://doc.crds.dev/github.com/crossplane/provider-aws@v0.25.0 for specific version.

* [AWS](https://doc.crds.dev/github.com/crossplane/provider-aws)
* [Azure](https://doc.crds.dev/github.com/crossplane/provider-azure)
* [Kubernetes](https://doc.crds.dev/github.com/crossplane-contrib/provider-kubernetes)

`provider-aws.yaml`

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-provider-aws
spec:
  package: crossplane/provider-aws:v0.25.0
```

Install provider into kubernetes

```bash
# Apply the manifests
kubectl apply -f ./config/provider-aws.yaml

# Or Install provider using crossplane clli
# kubectl crossplane install provider <packageName>
kubectl crossplane install provider crossplane/provider-aws:v0.25.0
```

### Configuration

`Configuration` is needed so `providers` can use it.

`provider-aws-config.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-account-creds
  namespace: crossplane-system
type: Opaque
data:
  credentials: ${BASE64ENCODED_AWS_ACCOUNT_CREDS}
---
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-account-creds
      key: credentials
```

```bash
# Apply the manifests
kubectl apply -f ./config/provider-aws-config.yaml

```

### Packages

`XRDs` and `Compositions` may be packaged and installed as a `configuration`. A `configuration` is a package of composition configuration that can easily be installed to Crossplane by creating a declarative Configuration resource.

`crossplane.yaml`

```yaml
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: app
spec:
  crossplane:
    version: ">=v1.5"
  dependsOn:
  - provider: crossplane/provider-kubernetes
    version: v0.3.0

```

```bash
# Create the package from current directory
kubectl crossplane build configuration --name app

# Push configuration to registry
kubectl crossplane push configuration jsa4000/crossplane-app:v0.1.0

# Or Install a specific configuration package
kubectl crossplane install configuration <packageName>
```

## Kubernetes Provider

For the example, a service will be deployed using the kubernetes `provider` and `Compositions`.

https://github.com/crossplane-contrib/provider-kubernetes

```bash
# Create the kubernetes provider (installed into 'crossplane-system' namespace)
kubectl apply -f ./config/provider-kubernetes.yaml

# Or using the cli
kubectl crossplane install provider crossplane/provider-kubernetes:v0.3.0

# Wait until the controller is running
kubectl get pods -n crossplane-system -w

# NAME                                                           READY   STATUS    RESTARTS   AGE
# crossplane-provider-kubernetes-e3a9c3ae909b-56448f79bb-gmm2q   1/1     Running   0          47s

# Create configuration based on the cluster

SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
kubectl apply -f https://raw.githubusercontent.com/crossplane-contrib/provider-kubernetes/main/examples/provider/config-in-cluster.yaml

# Or simply Create the configuration for the kubernetes provider (Change account name 'crossplane-provider-kubernetes-****')
kubectl apply -f ./config/provider-kubernetes-config.yaml

# Use the example provided in the official repository
kubectl apply -f https://raw.githubusercontent.com/crossplane-contrib/provider-kubernetes/main/examples/object/object.yaml

# Test if the namespace was created
kubectl get ns  

#NAME                STATUS   AGE
#...
#sample-namespace    Active   49s
```

### Example

## Refernces

* [Crossplane support for the Open Application Model](https://blog.crossplane.io/welcome-microsoft-and-alibaba-to-the-crossplane-community/)