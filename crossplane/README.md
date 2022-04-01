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
# Add Crossplane helm Chart repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Get current version
helm search repo crossplane-stable 

# Install Crossplane using
helm install crossplane -n crossplane-system --create-namespace crossplane-stable/crossplane --version 1.7.0 --wait
```

### Configuration

`XRDs` and `Compositions` may be packaged and installed as a `configuration`. A `configuration` is a package of composition configuration that can easily be installed to Crossplane by creating a declarative Configuration resource.

```bash
# Install a specific configuration package
kubectl crossplane install configuration <packageName>
```

## Example

```bash

```

## Refernces

* [Crossplane support for the Open Application Model](https://blog.crossplane.io/welcome-microsoft-and-alibaba-to-the-crossplane-community/)