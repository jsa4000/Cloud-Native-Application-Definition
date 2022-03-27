# Kustomize

## Structure

**Kustomize** has the concepts of `bases` and `overlays`. A *base* is a directory with a `kustomization.yaml`, which contains a set of resources and associated customization. A base could be either a **local** directory or a directory from a **remote** repo, as long as a `kustomization.yaml` is present inside. An *overlay* is a directory with a `kustomization.yaml` that refers to other kustomization directories as its bases. A base has no knowledge of an overlay and can be used in multiple overlays. An overlay may have multiple bases and it composes all resources from bases and may also have customization on top of them.

├── base
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── kustomization.yaml
│   ├── service.yaml
│   └── serviceaccount.yaml
└── overlays
    └── dev
        ├── Kustomization.yaml
        ├── config
        │   └── application.yaml
        ├── deployment.yaml
        ├── ingress.yaml
        └── secrets
            ├── password
            └── username

## Deployment

```bash
# Generate the manifest build using the base and overlays
kubectl apply -k overlays/dev --dry-run=client -o yaml> manifest.yaml

# Install the kustomization using the overlay (http://localhost)
kubectl create ns webapp
kubectl apply -n webapp -k overlays/dev

# Resources installedd
# serviceaccount/nginx-app created
# configmap/nginx-app-hcck9g96d4 created
# secret/nginx-app-m84m9g76mm created
# service/nginx-app created
# deployment.apps/nginx-app created
# horizontalpodautoscaler.autoscaling/nginx-app created
# ingress.networking.k8s.io/nginx-app created

# Note the hash used in Secret and ConfigMap. This enforces to restart the pod every
# time these files changes since the hash changes each time.
```

Delete the deployment

```bash
# Install the kustomization using the overly
kubectl delete -n webapp -k overlays/dev
```

## Verify

```bash
# Get the pods installed
kubectl get pods -n webapp

# NAME                         READY   STATUS    RESTARTS   AGE
# nginx-app-6657b945b5-7wmd4   1/1     Running   0          37s

# Shell to the pod to verify the config files
kubectl exec -n webapp -it nginx-app-6657b945b5-7wmd4 -- sh

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