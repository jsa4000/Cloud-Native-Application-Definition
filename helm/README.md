# Helm

## Pre-requisites

* Kubernetes cluster +1.22.,x
* Helm +3.8.x

## Create Chart

Helm provides a default generator for the initial scaffold

```bash
# Create App Chart
helm create myapp

# Also, it can be specified a custom starter
helm create --starter=spring-boot myapp
```

## Template

Use the `template`  command to see the values

```bash
# Create App Chart
helm template myapp .

# Create App Chart and send the output into a file
helm template myapp . > template.yaml

# Create App Chart using `--set-file` flag
helm template myapp \
    --set configMap.enabled=true \
    --set-file 'configMap.data.application\.yaml'=config/application.yaml \
    .

# Create App Chart using `--set-file` flag
helm template myapp \
    --set secret.enabled=true \
    --set-file secret.data.username=secrets/username \
    --set-file secret.data.password=secrets/password \
    .

# Create App Chart using `--set-file` flag
helm template myapp \
    --set configMap.enabled=true \
    --set-file 'configMap.data.application\.yaml'=config/application.yaml \
    --set secret.enabled=true \
    --set-file secret.data.username=secrets/username \
    --set-file secret.data.password=secrets/password \
    .

```

## Install

Use the `install`  command.

```bash
# Create App Chart
helm install myapp .

# Create App Chart using `--set-file` flag
helm install myapp \
    --set configMap.enabled=true \
    --set-file 'configMap.data.application\.yaml'=config/application.yaml \
    --set secret.enabled=true \
    --set-file secret.data.username=secrets/username \
    --set-file secret.data.password=secrets/password \
    .

```

## Uninstall

```bash
# Use delete command
helm delete myapp
```

## Verify

```bash
# Get the pods installed
kubectl get pods

# NAME                    READY   STATUS    RESTARTS   AGE
# myapp-c5d5c996d-lgqcf   1/1     Running   0          37s

# Shell to the pod to verify the config files
kubectl exec -it myapp-c5d5c996d-lgqcf -- sh

# Use the following commands to list the files
ls /var/app/config
ls /var/app/secrets

# Use the following commands to list the files and see the content
for FILE in '/var/app/config/*'; do echo $FILE && cat $FILE; done && echo
for FILE in '/var/app/secrets/*'; do cat $FILE; done && echo

# Print the word count to know whether there are additional characters
for FILE in '/var/app/config/*'; do echo $FILE && wc $FILE; done && echo

#/var/app/config/application.yaml /var/app/config/foo
# 2  4 39 /var/app/config/application.yaml
# 0  1  3 /var/app/config/foo
# 2  5 42 total

# get all the environment variables set by deployment
env
# Since the are not configured as env variables, they are not available in environment
```

## Example

See `values-dev.yaml` file.

Test using `template` and then `install` it. We will be useinig some best practices

* Use `namespaces` to create deployments and organize the cluster (RBAC, NetworkPolicies, Accounts, etc..)
* Create Resources `request` and `limits` so kubernetes scheduler can detect issues and work accurately.
* Use of `podAntiAffinity` so pods are create spread all over the cluster.
* Use of HPA in order to scale by demand depending on metrics (CPU, Memory, etc.)
* Create custom `Service Account` instead default (using `least-privilege` principle even `default` sa does not allow anything)
* Configured health checks for `readinessProbe` and `livenessProbe`

```bash
# Create App Chart using `--set-file` flag
helm template myapp -n webapp --create-namespace -f values-dev.yaml \
    --set configMap.enabled=true \
    --set-file 'configMap.data.application\.yaml'=config/application.yaml \
    --set secret.enabled=true \
    --set-file secret.data.username=secrets/username \
    --set-file secret.data.password=secrets/password \
    .

# Create App Chart using `--set-file` flag
helm install myapp -n webapp --create-namespace -f values-dev.yaml \
    --set configMap.enabled=true \
    --set-file 'configMap.data.application\.yaml'=config/application.yaml \
    --set secret.enabled=true \
    --set-file secret.data.username=secrets/username \
    --set-file secret.data.password=secrets/password \
    .

```

```bash
# Get the pods installed usnig the namespace
kubectl get all,sa,secret,cm,hpa,ingresses -n webapp

# NAME                             READY   STATUS    RESTARTS   AGE
# pod/nginx-app-5c47b6674b-tc4pj   1/1     Running   0          71s
# 
# NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# service/nginx-app   ClusterIP   10.43.182.30   <none>        80/TCP    71s
# 
# NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/nginx-app   1/1     1            1           71s
# 
# NAME                                   DESIRED   CURRENT   READY   AGE
# replicaset.apps/nginx-app-5c47b6674b   1         1         1       71s
# 
# NAME                                            REFERENCE              TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
# horizontalpodautoscaler.autoscaling/nginx-app   Deployment/nginx-app   <unknown>/80%   1         100       1          71s
# 
# NAME                       SECRETS   AGE
# serviceaccount/default     1         11m
# serviceaccount/nginx-app   1         71s
# 
# NAME                                 TYPE                                  DATA   AGE
# secret/default-token-bhp9f           kubernetes.io/service-account-token   3      11m
# secret/nginx-app                     Opaque                                2      71s
# secret/nginx-app-token-dxpdr         kubernetes.io/service-account-token   3      71s
# secret/sh.helm.release.v1.myapp.v1   helm.sh/release.v1                    1      71s
# 
# NAME                         DATA   AGE
# configmap/kube-root-ca.crt   1      11m
# configmap/nginx-app          2      71s
# 
# NAME                                  CLASS    HOSTS       ADDRESS         PORTS   AGE
# ingress.networking.k8s.io/nginx-app   <none>   localhost   192.168.1.132   80      2m8s

# Use Port forward to verify it is working
kubectl port-forward -n webapp service/nginx-app 8080:80

# Describe the deployment (podAntiAffinity, volumes, service accounts, etc.. )
kubectl describe -n webapp deployment/nginx-app

# Delete the app
helm delete myapp -n webapp
```