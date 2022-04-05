# Cloud-Native Application Definition

## Terminology

### Shift Left & Shift Right

To understand **shift left** and **shift right**, consider the software development cycle as a continuum, or infinity loop, from left to right. On the left side of the loop, teams plan, develop, and test software in pre-production. The main concern in pre-production on the left side of the loop is building software that meets design criteria. When teams release software into production on the right side of the loop, they make the software available to users. The concern in production is to maintain software that meets business goals and reliability criteria.

![](images/13429_ILL_DevOpsLoop_shiftleft_shiftright-1.jpg)

**Shift-left** is the practice of moving testing, quality, and performance evaluation early in the software development process, thus the process of shifting to the “left” side of the DevOps lifecycle. This concept has become increasingly important as teams face pressure to deliver software faster and more frequently with higher quality. **Shift-left** speeds up development efficiency and reduces costs by detecting and addressing software defects earlier in the development cycle before they get to production.

**Shift–right** is the practice of performing testing, quality, and performance evaluation in production under real-world conditions. **Shift-right** methods ensure that applications running in production can withstand real user load while ensuring the same high levels of quality. With shift right, DevOps teams test a built application to ensure performance, resilience, and software reliability. The goal is to detect and remediate issues that would be difficult to anticipate in development environments.

Both **shift-left** and **shift-right** testing have become important components of Agile software development, enabling teams to build and release software incrementally and reliably but also test software at various points in the lifecycle.

### Open Application Model (OAM)

Initially created by Microsoft, Alibaba, and Upbound, the **Open Application Model (OAM)** specification describes a model where developers are responsible for defining application components, application operators are responsible for creating instances of those components and assigning them application configurations, and infrastructure operators are responsible for declaring, installing, and maintaining the underlying services that are available on the platform. `Crossplane` and `KubeVela` are some Kubernetes implementations of the specification.

With OAM, platform builders can provide reusable modules in the format of Components, Traits, and Scopes. This allows platforms to do things like package them in predefined application profiles. Users choose how to run their applications by selecting profiles, for example, microservice applications with high service level objective (SLO) requirements, stateful apps with persistent volumes, or event-driven functions with horizontally autoscaling.

The OAM specification introduction document presents a story that explores a typical application delivery lifecycle.

* The developer creates a web application;
* The application operator deploys instances of that application, and configures it with operational traits, such as autoscaling;
* The infrastructure operator decides which underlying technology is used to handle the deployment and operations.

![](images/Ew6zDjTWYAA5Wpp.jpg)

To deliver an application, each individual component of a program is described as a Component YAML by an application developer. This file encapsulates a workload and the information needed to run it.

To run and operate an application, the application operator sets parameter values for the developers’ components and applies operational characteristics, such as replica size, autoscaling policy, ingress points, and traffic routing rules in an ApplicationConfiguration YAML. In OAM, these operational characteristics are called Traits. Writing and deploying an ApplicationConfiguration is equivalent to deploying an application. The underlying platform will create live instances of defined workloads and attach operational traits to workloads according to the ApplicationConfiguration spec.

Infrastructure operators are responsible for declaring, installing, and maintaining the underlying services that are available on the platform. For example, an infrastructure operator might choose a specific load balancer when exposing a service, or a custom database configuration that ensures data is encrypted and replicated globally.

## Models and Tools

### Helm

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

* No need to **install** any controller or operator into the cluster
* Configuration and deployment is **specified** just by a `values` files.
* There are **multiples** ways to configure depending on your requirements.
* You can create **revisions** and perform **rollbacks**.
* It is good for **third party** applications.

Cons:

* There is no `drift` detection, so any manual changes in the cluster are **not detected** automatically.
* For `statefulset` there is no way to control safely the update is additional constraints must be checked (sync, restore, etc..).
* For developers can be difficult to modify the `templates` by their selfs if changes are needed.

### ArgoCD

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

* ArgoCD has **support** with different formats such as `Helm`, `Kustomize` and kubernetes `manifest`.
* Since it is base on **GitOps** principles, It can detect `drift` changes performed in the manifests deployed.
* It has almost the same features and benefits as using `helm` and `kustomize`.
* For developers can be easy, since the configuration is stored in an `Application` manifest and managed by ArgoCD and kubernetes.

Cons:

* ArgoCD does **not** manage helm charts as same as `helm` cli does, since it creates the deployment based on the manifests generated by `helm template`.
* ArgCD must be **deployed** into the system. ArgoCD needs high-availability, resilience, fault-tolerant in production environments that requires tons of resources.
* ArgoCD has the same **drawbacks** that using `helm` or `kustomize`.

### Kustomize

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

* It allows to modify or add any manifest to the the `base` using `overlays`.
* It does not **requires** any controller or operator to be installed.

Cons:

* The definition cannot be visualized in an `high level` way.
* It can be difficult from Developers to understand the way **manifest** are defined.

### Operator SDK

This is the file Operator SDK uses to create an `application`.

```yaml
apiVersion: demo.example.com/v1alpha1
kind: MyApp
metadata:
  name: nginx-myapp
spec:
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
    data: 
      application.yaml: |-
        spring:
          application:
            name: my-app
      foo: |-
        bar

  secret:
    enabled: true
    data: 
      password: cGFzc3dvcmQ=
      username: dXNlcm5hbWU=
```

Pros:

* It detects the `drift` between the source and the destination. If a `manifest` gets deleted the operator will automatically recover it from the current state.
* It can be created from a `Helm` Chart, so it shares the same benefits.
* It creates a new `CustomResourceDefinition (CRD)` to be used as a kubernetes resource that expose the same parameters and the helm chart.

Cons:

* The method used requires a Helm Chart to be used, so it requires Helm templating knowledge.
* Operator must be **build** and **published** again, if the Helm Chart is modified.
* It needs to install `OLM operator` to deploy the operators.
* Depending on the kubernetes distribution `OLM` is not used very often. OLM has been created by **Redhat**, so `Openshift` is a target platform.

### Crossplane

[https://github.com/crossplane/crossplane](https://github.com/crossplane/crossplane)

![](images/crossplane.png)

This is the file Crossplane uses to create an `application`.

```yaml
apiVersion: example.com/v1alpha1
kind: AppClaim
metadata:
  name: nginx
  labels:
    app-owner: owner
spec:
  id: nginx
  compositionSelector:
    matchLabels:
      type: frontend
  parameters:
    namespace: webapp
    image: nginx:1.21.6-alpine
    host: localhost
```

Pros:

* It can create new `CustomResourcesDefinitions` to define resources using kubernetes API.
* `Crossplane` define interfaces (`definitions`) and implementations (`components`) that are packaged as `Configuration` or `Providers`.
* Developers use the **interfaces** based on kubernetes labels and selectors to create applications.
* It check the `drift` between the current state of the manifests in the cluster and the state is stored in etcd.

Cons:

* It is a very new technology that is starting to gain contributors and used by companies.
* The way `interfaces` are implemented can be difficult, this is usually done by SRE or DevOps teams.
* It requires to **install** Crossplane operators and controllers to run.

### KubeVela

**KubeVela** is a modern application platform that makes it easier and faster to deliver and manage applications across hybrid, multi-cloud environments. At the mean time, it is highly extensible and programmable, which can adapt to your needs as they grow.

![](images/what-is-kubevela-0c2584fd19c8a603b9dea994cfdadcb2.png)

This is the file Kubevela uses to create an `application`.

```yaml
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: nginx
spec:
  components:
    - name: nginx
      type: webservice
      properties:
        image: nginx:1.21.6-alpine
        ports:
          - port: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80 
        env:
          - name: CONFIG_FILE
            value: file:/var/app/config/application.yml
          - name: DATABASE_USERNAME
            valueFrom:
              secretKeyRef:
                key: username
                name: nginx-app
          - name: DATABASE_PASSWORD
            valueFrom:
              secretKeyRef:
                key: password
                name: nginx-app
        volumeMounts:
          configMap:
            - name: config-volume
              cmName: nginx-app
              mountPath: /var/app/config
          secret:
            - name: secret-volume
              secretName: nginx-app
              mountPath: /var/app/secrets
      traits:
        - type: gateway
          properties:
            domain: nginx.webapp.example.com
            class: traefik
            http:
              "/": 80
        - type: labels
          properties:
            version : "stable"
        - type: annotations
          properties:
            test-annotation: "test-annotation"
        - type: resource
          properties:
            cpu: 0.25
            memory: "200Mi"
        - type: cpuscaler
          properties:
            min: 1
            max: 10
            cpuPercent: 60
```

Pros:

* Its is based on `Open Application Model (OAM)` and kubernetes resources to create applications.
* Developers consume `components` and `traits` already defined to create their applications
* New `components` and `traits` can be created to definea an `Application` resources using kubernetes API.
* It check the `drift` between the current state of the manifests in the cluster and the state is stored in etcd.

Cons:

* It is a very new technology that is starting to gain contributors and used by companies.
* The way `components` and `traits` are implemented can be difficult using the `cue` language, this is usually done by SRE or DevOps teams.
* It requires to **install** Kubevela operators and controllers to run.

### Knative

[https://github.com/knative/serving](https://github.com/knative/serving)

![](images/knative.png)

This is the file Knative uses to create an `application`.

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: nginx
  #labels:
    ## Internal-only (cluster-local) services 
    # serving.knative.dev/visibility: cluster-local
spec:
  template:
    metadata:
      # This is the name of our new "Revision," it must follow the convention {service-name}-{revision-name}
      name: nginx-v1
      labels:
        test-label: "test-value"
      annotations:
        autoscaling.knative.dev/max-scale: "3" # 0 value is unlimited
    spec:
      # To process maximum N requests at a time
      containerConcurrency: 20
      containers:
        - image: nginx:1.21.6-alpine
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80  
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
                  key: username
                  name: nginx-app
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: password
                  name: nginx-app
          volumeMounts:
            - name: config-volume
              mountPath: /var/app/config
            - name: secret-volume
              mountPath: /var/app/secrets
      volumes:
        - name: config-volume
          configMap:
            name: nginx-app
        - name: secret-volume
          secret:
            secretName: nginx-app
```

Pros:

* It has a custom resource definition named `KService` that simplifies the way kubernetes create resources: deployments, services, ingress, hpa, etc..
* **Knative serving** has another benefits such as scale-to-zero, manage multiple revisions, Concurrency, etc..
* It is simple to manage applications from developer perspective.

Cons:

* **Knative serving** control plane must be installed in the computer ensuring HA, replicas, etc..
* It is required to install a `Service Mesh` to provide specific functionality: `istio`, `kourier` and `Contour`.
* KService **cannot** be modified or override with custom ones.
