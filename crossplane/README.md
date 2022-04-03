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

No matter it is for `Provider` or `Configuration`, all packages must have a file called `crossplane.yaml` in the root directory. For providers, it is typically located at the package folder in the project root directory. This file contains the package’s metadata which governs how Crossplane will install the package.

`XRDs` and `Compositions` may be packaged and installed as a `configuration`. A `configuration` is a package of composition configuration that can easily be installed to Crossplane by creating a declarative Configuration resource.

[Package Documentation](https://negz.github.io/crossplane.github.io/docs/v1.4/getting-started/create-configuration.html)

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
    version: ">=v0.3.0"

```

Following are the main commands for managing `crossplane` packages

```bash
# To build a package
kubectl crossplane build [provider|configuration] [name]

# To publish a package
kubectl crossplane push [provider|configuration] <tag>

# To update a package
kubectl crossplane update [provider|configuration] <name> <tag>

# To install a packages
kubectl crossplane install [provider|configuration] <tag>
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

# The the ServiceAccount for the Kubernetes Provider Controller and attach it the default ClusterRoleBinding
SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
kubectl apply -f https://raw.githubusercontent.com/crossplane-contrib/provider-kubernetes/main/examples/provider/config-in-cluster.yaml

# Or simply Create the configuration for the kubernetes provider (Change account name 'crossplane-provider-kubernetes-****')
kubectl apply -f ./config/provider-kubernetes-config.yaml
```

Verify the installation creating a simple `Object`

```bash
# Use the example provided in the official repository
kubectl apply -f object.yaml

# Test if the namespace was created
kubectl get ns  

#NAME                STATUS   AGE
#...
#sample-namespace    Active   49s
```

### Example

Example to `build` and `publish` a package for `Configuration` into a container registry

```bash
# Create the package from current directory ()
kubectl crossplane build configuration -f ./app --name app

# Push configuration to registry
kubectl crossplane push configuration -f ./app/app.xpkg jsa4000/crossplane-app:v0.1.0

# Or Install a specific configuration package
kubectl crossplane install configuration jsa4000/crossplane-app:v0.1.0

# Get the installed resources
kubectl get CompositeResourceDefinition,Composition,Configuration    

# NAME                                                                       ESTABLISHED   OFFERED   AGE
# compositeresourcedefinition.apiextensions.crossplane.io/apps.example.com   True          True      90s
# 
# NAME                                                   AGE
# composition.apiextensions.crossplane.io/app-backend    90s
# composition.apiextensions.crossplane.io/app-frontend   90s
# 
# NAME                                                     INSTALLED   HEALTHY   PACKAGE                         AGE
# configuration.pkg.crossplane.io/jsa4000-crossplane-app   True        True      jsa4000/crossplane-app:v0.1.0   96s
```

Create a custom application from previous `CompositeResourceDefinition` and `Composition` for frontend applications.

```bash
# Create the namespace set into Manifest
kubectl create ns webapp

# Use the following command to create the AppClaim for frontend Composition.
kubectl apply -f app-frontend.yaml

# Get all resources created by kubernetes Provider
kubectl get Object

# NAME               SYNCED   READY   AGE
# nginx-deployment   True     True    3m35s
# nginx-service      True     True    3m34s
# nginx-ingress      True     True    3m34s

# Describe an objects to get errors if SYNCED or READY statuses are false
kubectl describe Object nginx-deployment

# Custom Resource Definitions can be get as same as kubernetes objects exposing custom columns
kubectl get AppClaim

# NAME    HOST        READY   CONNECTION-SECRET   AGE
# nginx   localhost   True                        4m53s

# Verify it is working at http://localhost
```

## Refernces

* [Crossplane support for the Open Application Model](https://blog.crossplane.io/welcome-microsoft-and-alibaba-to-the-crossplane-community/)