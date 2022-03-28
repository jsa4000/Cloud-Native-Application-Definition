# KNative

## Install

### CLI

[https://github.com/knative](https://github.com/knative)

```bash
# https://knative.dev/docs/getting-started/quickstart-install/#install-the-knative-cli

# Install from brew
brew install kn

# Update existing one
brew upgrade kn

# Install from releases
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')
export KNATIVE_VERSION=1.3.1
export KNATIVE_DL_URL=https://github.com/knative/client/releases/download/knative-v${KNATIVE_VERSION}
curl -LO ${KNATIVE_DL_URL}/kn-${OS}-${ARCH}
chmod +x kn-${OS}-${ARCH} && sudo mv kn-${OS}-${ARCH} /usr/local/bin/kn

# Verify the installation
kn version
```

### Serving

Installation can be done using multiple ways, in this case KNative operator will be installed

```bash
# Install Knative Operator into `default` namespace (it cannot be changed)
export KNATIVE_VERSION=1.3.1
kubectl apply -f https://github.com/knative/operator/releases/download/knative-v$KNATIVE_VERSION/operator.yaml

# To install using yaml files
# https://platform9.com/blog/how-to-set-up-knative-serving-on-kubernetes/
```

Create a kubernetes manifest

`knative-serving.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: knative-serving
---
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  version: 1.3.0
  manifests:
    - URL: https://github.com/knative/serving/releases/download/knative-v${VERSION}/serving-core.yaml
    - URL: https://github.com/knative/serving/releases/download/knative-v${VERSION}/serving-hpa.yaml
    - URL: https://github.com/knative/serving/releases/download/knative-v${VERSION}/serving-post-install-jobs.yaml
    - URL: https://github.com/knative/net-istio/releases/download/knative-v${VERSION}/net-istio.yaml
  #config:
  #  istio:
  #    local-gateway.<local-gateway-namespace>.knative-local-gateway: "knative-local-gateway.<istio-namespace>.svc.cluster.local"
```

Install `knative-serving`

```bash
# Apply custom manifest
kubectl apply -f knative-serving.yaml
```
