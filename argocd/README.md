# ArgoCD

## Install ArgoCD

```bash
# Add Helm Repo
helm3 repo add argo https://argoproj.github.io/argo-helm

# Update repo
helm3 repo update

## Install ArgoCD with custom values equal to the application (argocd/argocd.yaml)
helm3 install argocd -n argocd --create-namespace argo/argo-cd --version 4.2.1 \
  --set redis-ha.enabled=false \
  --set controller.enableStatefulSet=false \
  --set server.autoscaling.enabled=false \
  --set repoServer.autoscaling.enabled=false
```

Use the `dashboard` to verify the applications

```bash
# Get the ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Access ArgoCD as admin user
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Deployment

Create an [AppProject](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/) to enable **policies** and **limit** the scope in which applications are deployed.

```bash
# Deploy the ArgoCd project into kubernetes
kubectl apply -f project.yaml  
```

Crate Application

```bash
# Deploy the application into kubernetes
kubectl apply -f application.yaml  

# Deploy the application using OTS (off-the-shelf) helm chart 
# https://github.com/argoproj/argocd-example-apps/tree/master/helm-dependency
kubectl apply -f application-ots.yaml  
```

Delete Application

```bash
# Deploy the application into kubernetes
kubectl delete -f application.yaml  

# Delete the project
kubectl delete -n webapp -f project.yaml  
```

## Manual Installation

```bash
# Create App Chart using `--set-file` flag
helm template myapp --dependency-update -n webapp --create-namespace -f ./helm/values-dev.yaml \
    --set app.configMap.enabled=true \
    --set-file 'app.configMap.data.application\.yaml'=helm/config/application.yaml \
    --set-file 'app.configMap.data.application-dev\.yaml'=helm/config/application-dev.yaml \
    --set app.secret.enabled=true \
    --set-file app.secret.data.username=helm/secrets/username \
    --set-file app.secret.data.password=helm/secrets/password \
    ./helm

# Create App Chart using `--set-file` flag
helm install myapp -n webapp --create-namespace -f ./helm/values-dev.yaml \
    --set app.configMap.enabled=true \
    --set-file 'app.configMap.data.application\.yaml'=helm/config/application.yaml \
    --set-file 'app.configMap.data.application-dev\.yaml'=helm/config/application-dev.yaml \
    --set app.secret.enabled=true \
    --set-file app.secret.data.username=helm/secrets/username \
    --set-file app.secret.data.password=helm/secrets/password \
    ./helm

```