# Cloud-Native Application Definition

## Helm

This is the file Helm uses to create an `application`.

```yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: Always
  tag: 1.21.6-alpine

strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 1

imagePullSecrets: []
nameOverride: nginx
fullnameOverride: nginx-app

serviceAccount:
  create: true

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  annotations: 
    kubernetes.io/ingress.class: traefik
  hosts:
    - host: localhost
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

env:
  - name: CONFIG_FILE
    value: file:/var/app/config/application.yml
  - name: DATABASE_USERNAME
    valueFrom:
      secretKeyRef:
        name: nginx-app
        key: username
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: nginx-app
        key: password

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  # targetMemoryUtilizationPercentage: 80

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: nginx
              app.kubernetes.io/instance: myapp
          topologyKey: kubernetes.io/hostname
        weight: 100

configMap:
  enabled: true
  data: {}

secret:
  enabled: true
  data: {}
```

Pros:
Cons:

## ArgoCD

This is the file ArgoCD uses to create an `application`.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ngnix-app
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "10"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: webapp
  source:
    path: helm
    helm:
      values: |
        image:
          tag: 1.21.0-alpine
        configMap:
          enabled: true
        secret:
          enabled: true
      valueFiles:
      - values-dev.yaml
      fileParameters:
      - name: 'configMap.data.application\.yaml'
        path: config/application.yaml
      - name: secret.data.username
        path: secrets/username
      - name: secret.data.password
        path: secrets/password
    repoURL: https://github.com/jsa4000/Cloud-Native-Application-Definition
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
        - CreateNamespace=true
```

Pros:
Cons:

## Kustomize

This is the file Kustomize uses to create an `application`.

```yaml
resources:
- ../../base
- ingress.yaml

images:
- name: nginx
  newName: nginx
  newTag: 1.21.6-alpine

configMapGenerator:
- name: nginx-app
  files:
  - config/application.yaml

secretGenerator:
- name: nginx-app
  files:
  - secrets/username
  - secrets/password
  
patchesStrategicMerge:
  - deployment.yaml
```

Pros:
Cons:

## Crossplane

This is the file Crossplane uses to create an `application`.

```yaml

```

Pros:
Cons:

## Kubevela

This is the file Kubevela uses to create an `application`.

```yaml

```

Pros:
Cons:

## Knative

This is the file Knative uses to create an `application`.

```yaml

```

Pros:
Cons: