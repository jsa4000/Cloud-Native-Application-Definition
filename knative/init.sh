#!/bin/bash

echo "Installing Istio"

# Remove traefik from Rancher Desktop
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik

# Install Istio using  istioctl 
export ISTION_VERSION=1.12.5
istioctl operator init --watchedNamespaces=istio-system --operatorNamespace=istio-operator --tag=$ISTION_VERSION

# Wait until istio-operator is ready
kubectl rollout -n istio-operator status deployment istio-operator
while [ $? -ne 0 ]; do kubectl rollout -n istio-operator status deployment istio-operator; done

# Install istio using operator and manifest
kubectl apply -f istio.yaml

# Wait until istio is ready
kubectl rollout -n istio-system status deployment istiod
while [ $? -ne 0 ]; do kubectl rollout -n istio-system status deployment istiod; done

echo "Installing Knative"

# Install Knative Operator into `default` namespace (it cannot be changed)
export KNATIVE_VERSION=1.3.1
kubectl apply -f https://github.com/knative/operator/releases/download/knative-v$KNATIVE_VERSION/operator.yaml

# Waint unto operator is ready
kubectl rollout -n default status deployment knative-operator
while [ $? -ne 0 ]; do kubectl rollout -n default status deployment knative-operator; done  

# Apply custom manifest for knative-serving (using Istio and custom domain)
kubectl apply -f knative-serving.yaml

# Wait until istio is ready
kubectl rollout -n default status deployment knative-operator
while [ $? -ne 0 ]; do kubectl rollout -n knative-serving status deployment controller; done

echo "Configuring Knative"

# Create namespace
kubectl create ns webapp

# Inject agent into knative-serving namespace
kubectl label namespace knative-serving istio-injection=enabled

# Enable `istio-injection` within the webapp namespace
kubectl label namespace webapp istio-injection=enabled

echo "Knative Installed"
echo "Uee 'webapp' namespace to isntall your services"
echo "Uer 'kni inspect -s <service-name>' to inspect the resources created by knative"