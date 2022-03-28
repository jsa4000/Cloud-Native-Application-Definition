# Operator SDK

## Install

[https://github.com/operator-framework/operator-sdk](https://github.com/operator-framework/operator-sdk)

```bash
# https://sdk.operatorframework.io/docs/installation/

# Install from brew
brew install operator-sdk

# Install from releases
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.18.1
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk

# Verify the installation
operator-sdk version
```

## Create Operator from Helm Chart

With `Operator SDK` it is possible to create an operator from Helm Chart.

```bash
# https://sdk.operatorframework.io/docs/building-operators/helm/tutorial/

# Create a directory for the operator
mkdir myapp-operator
cd myapp-operator

# Create a new boiler-plate project from scratch (it creates a default helm template similar to 'helm create myapp')
operator-sdk init --plugins helm --domain example.com --group demo --version v1alpha1 --kind MyApp

# [USED] Create a project for existing helm chart
operator-sdk init --plugins helm --domain example.com --group demo --version v1alpha1 --kind MyApp --helm-chart=../../helm  

# WARN[0000] The RBAC rules generated in config/rbac/role.yaml are based on the chart's default manifest. Some rules may be missing for resources that are only enabled with custom values, and some existing rules may be overly broad. Double check the rules generated in config/rbac/role.yaml to ensure they meet the operator's permission requirements. 

```

It creates the following `CustomResourceDefinition` file with the information to create kubernetes resource.

`/myapp-operator/config/crd/bases/demo.example.com_myapps.yaml`

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myapps.demo.example.com
spec:
  group: demo.example.com
  names:
    kind: MyApp
    listKind: MyAppList
    plural: myapps
    singular: myapp
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        description: MyApp is the Schema for the myapps API
        properties:
...
```

## Run the operator

```bash
# Login into docker
docker login

# Generate docker image and push into the registry
make docker-build docker-push IMG=jsa4000/myapp-operator:0.1.0

# Install and Run the Operator locally
make install run

# Deploy the operator
make deploy IMG=jsa4000/myapp-operator:0.1.0
```

## Deploy with Operator Lifecycle Manager (OLM)

```bash
# First Install operator-sdk
operator-sdk olm install

# Make the bundle
make bundle bundle-build bundle-push BUNDLE_IMG=jsa4000/myapp-operator-bundle:0.1.0

# Run the current bundle
operator-sdk run bundle registry.hub.docker.com/jsa4000/myapp-operator-bundle:0.1.0

# Update an existing bundle
operator-sdk run bundle-upgrade registry.hub.docker.com/jsa4000/myapp-operator-bundle:0.2.0
```

## Deploy Manifest

```bash
# Deploy custom sample
kubectl apply -f nginx-myapp.yaml
```