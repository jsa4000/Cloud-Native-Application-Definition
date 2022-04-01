# Kubevela

**KubeVela** is a modern application platform that makes it easier and faster to deliver and manage applications across hybrid, multi-cloud environments. At the mean time, it is highly extensible and programmable, which can adapt to your needs as they grow.

![](../images/what-is-kubevela-0c2584fd19c8a603b9dea994cfdadcb2.png)

KubeVela practices the "render, orchestrate, deploy" workflow with below highlighted values added to existing ecosystem:

* **Application Centric** - KubeVela introduces **Open Application Model (OAM)** as the consistent yet higher level API to capture and render a full deployment of microservices on top of hybrid environments. Placement strategy, traffic shifting and rolling update are declared at application level. No infrastructure level concern, simply deploy.
* **Programmable Workflow** - KubeVela models application delivery as DAG (Directed Acyclic Graph) and expresses it with CUE - a modern data configuration language. This allows you to design application deployment steps per needs and orchestrate them in programmable approach. No restrictions, natively extensible.
* **Infrastructure Agnostic** - KubeVela works as an application delivery control plane that is fully decoupled from runtime infrastructure. It can deploy any workload types including containers, cloud services, databases, or even VM instances to any cloud or Kubernetes cluster, following the workflow designed by you.

**Open Application Model (OAM)**

Initially created by Microsoft, Alibaba, and Upbound, the **Open Application Model (OAM)** specification describes a model where developers are responsible for defining application components, application operators are responsible for creating instances of those components and assigning them application configurations, and infrastructure operators are responsible for declaring, installing, and maintaining the underlying services that are available on the platform. `Crossplane` and `KubeVela` are some Kubernetes implementations of the specification.

With OAM, platform builders can provide reusable modules in the format of Components, Traits, and Scopes. This allows platforms to do things like package them in predefined application profiles. Users choose how to run their applications by selecting profiles, for example, microservice applications with high service level objective (SLO) requirements, stateful apps with persistent volumes, or event-driven functions with horizontally autoscaling.

The OAM specification introduction document presents a story that explores a typical application delivery lifecycle.

* The developer creates a web application;
* The application operator deploys instances of that application, and configures it with operational traits, such as autoscaling;
* The infrastructure operator decides which underlying technology is used to handle the deployment and operations.

![](../images/Ew6zDjTWYAA5Wpp.jpg)

To deliver an application, each individual component of a program is described as a Component YAML by an application developer. This file encapsulates a workload and the information needed to run it.

To run and operate an application, the application operator sets parameter values for the developers’ components and applies operational characteristics, such as replica size, autoscaling policy, ingress points, and traffic routing rules in an ApplicationConfiguration YAML. In OAM, these operational characteristics are calle../d Traits. Writing and deploying an ApplicationConfiguration is equivalent to deploying an application. The underlying platform will create live instances of defined workloads and attach operational traits to workloads according to the ApplicationConfiguration spec.

Infrastructure operators are responsible for declaring, installing, and maintaining the underlying services that are available on the platform. For example, an infrastructure operator might choose a specific load balancer when exposing a service, or a custom database configuration that ensures data is encrypted and replicated globally.

## Install

### vela CLI

**Kubevela** provides a CLI to manage all resources more simply.

```bash
# Script
curl -fsSl https://kubevela.io/script/install.sh | bash -s 1.2.4

# Via package manager
brew update
brew install kubevela

# Verify the intallation
vela version
```

### Core

There are multiple ways to install `Kubevela` into a `kubernetes` cluster.

```bash
# Using vela CLI
vela install

# Using Helm
# https://github.com/oam-dev/kubevela/tree/master/charts/vela-core
helm repo add kubevela https://charts.kubevela.net/core
helm repo update
helm install --create-namespace -n vela-system kubevela kubevela/vela-core --version 1.2.4 --wait

# Install dashboard
vela addon enable velaux
```

Verify the installation

```bash
# Using kubectl
kubectl get pods,svc -n vela-system

# NAME                                        READY   STATUS      RESTARTS   AGE
# kubevela-cluster-gateway-7cbf4886db-96s6z   1/1     Running     0          2m4s
# kubevela-vela-core-697bd5d56-xsxqn          1/1     Running     0          2m4s

# NAME                                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# service/kubevela-cluster-gateway-service   ClusterIP   10.43.243.241   <none>        9443/TCP   3m35s
# service/vela-core-webhook                  ClusterIP   10.43.162.20    <none>        443/TCP    3m35s

# Verify installation using velaux (both ways work)
# vela port-forward addon-velaux -n vela-system 8080:80
kubectl port-forward -n vela-system service/velaux 8080:80

#? You have 4 deployed resources in your app. Please choose one:  [Use arrows to move, type to filter]
Choose >  Cluster: local | Namespace: vela-system | Component: velaux | Kind: Service
```

Uninstall Kubevela Core

```bash
# Using vela CLI
vela addon disable velaux
vela uninstall

# Using helm
helm uninstall -n vela-system kubevela
```

## Templates

### Default

* [Webservice](https://kubevela.io/docs/end-user/components/cue/webservice)
* [Worker](https://kubevela.io/docs/end-user/components/cue/worker)
* [Task](https://kubevela.io/docs/end-user/components/cue/task)
* [Kustomize](https://kubevela.io/docs/end-user/components/kustomize)
* [Raw](https://kubevela.io/docs/end-user/components/cue/raw)
* [Helm](https://kubevela.io/docs/end-user/components/helm)

```bash
# Get all the components available
vela component 

# NAME            DEFINITION              
# worker          deployments.apps        
# webservice      deployments.apps        
# raw             autodetects.core.oam.dev
# k8s-objects     autodetects.core.oam.dev
# task            jobs.batch   

# Get all the traits available
vela trait

# NAME                            APPLIES-TO        
# volumes                         [deployments.apps]
# service-account                 [*]               
# node-affinity                   [*]               
# storage                         [deployments.apps]
# labels                          [*]               
# env                             [*]               
# cpuscaler                       [deployments.apps]
# register-grafana-datasource     []                
# pvc                             [deployments.apps]
# service-binding                 [*]               
# ...

```

### Custom

There are multiple ways to [create new definitions](https://kubevela.io/docs/platform-engineers/cue/definition-edit) in Kubevela: cue, yaml, etc..

In KubeVela CLI (>= v1.1.0), `vela def` command group provides a series of convenient definition writing tools. With these commands, users only need to write CUE files to generate and edit definitions, instead of composing Kubernetes YAML object with mixed CUE string.

In addition, users can create definitions from existing YAML files. For example, if a user want to create a ComponentDefinition which is designed to generate a deployment, and this deployment has already been created elsewhere, he/she can use the --template-yaml flag to complete the transformation.

```bash
# CReate empty definition (trait,component,scope, etc..)
vela def init my-trait -t trait --desc "My trait description."

# Create interactive definition
vela def init my-comp --interactive 

# Generate cue definition from yalm file
vela def init my-comp -t component --desc "My component." --template-yaml ./custom/my-deployment.yaml > ./custom/my-comp.cue

# validate the definition
vela def vet ./custom/my-comp.cue

# Render the cue definition into a OAM component
vela def render ./custom/my-comp.cue -o ./custom/my-comp.yaml
```

## First Application

Deploy the first application using **Kubevela**

`vela-app.yaml`

```yaml
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: first-vela-app
spec:
  components:
    - name: express-server
      # Built-in Component Type 'webservice'
      # https://kubevela.io/docs/end-user/components/cue/webservice
      type: webservice
      properties:
        image: crccheck/hello-world
        port: 8000
      traits:
        # https://kubevela.io/docs/end-user/traits/ingress
        - type: gateway
          properties:
            domain: hello.webapp.example.com
            class: traefik
            http:
              "/": 8000
```

Create application from `Application` crd

```bash
# https://kubevela.io/docs/end-user/quick-start-cli

# Create namespace
kubectl create ns webapp

# Apply the manifest
kubectl apply -n webapp -f vela-app.yaml
```

Verify the Application

```bash
# Verify the status app
vela status -n webapp first-vela-app

# About:
# 
#   Name:         first-vela-app                
#   Namespace:    webapp                        
#   Created at:   2022-03-30 22:28:38 +0200 CEST
#   Status:       running                       
# 
# Workflow:
# 
#   mode: DAG
#   finished: true
#   Suspend: false
#   Terminated: false
#   Steps
#   - id:c6wjd8eoft
#     name:express-server
#     type:apply-component
#     phase:succeeded 
#     message:
# 
# Services:
# 
#   - Name: express-server  Env: Control plane cluster
#     Type: webservice
#     healthy Ready:1/1
#     Traits:
#       - ✅ gateway: Visiting URL: hello.webapp.example.com, IP: 192.168.1.142

vela status -n webapp first-vela-app --endpoint
# Error in the CLI since it is looking for "networking.k8s.io/v1beta1" instead "networking.k8s.io/v1"

# Check the kubernetes resources that has been created by kubevela
kubectl get all,ingress,hpa,sa,cm,secret -n webapp

# NAME                                 READY   STATUS    RESTARTS   AGE
# pod/express-server-84fd6d69d-gl4qs   1/1     Running   0          30m
# 
# NAME                     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
# service/express-server   ClusterIP   10.43.88.71   <none>        8000/TCP   30m
# 
# NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/express-server   1/1     1            1           30m
# 
# NAME                                       DESIRED   CURRENT   READY   AGE
# replicaset.apps/express-server-84fd6d69d   1         1         1       30m
# 
# NAME                                       CLASS    HOSTS                      ADDRESS         PORTS   AGE
# ingress.networking.k8s.io/express-server   <none>   hello.webapp.example.com   192.168.1.142   80      30m
# 
# NAME                     SECRETS   AGE
# serviceaccount/default   1         31m
# 
# NAME                                        DATA   AGE
# configmap/kube-root-ca.crt                  1      31m
# configmap/workflow-first-vela-app-context   2      30m
# 
# NAME                         TYPE                                  DATA   AGE
# secret/default-token-crgt9   kubernetes.io/service-account-token   3      31m
```

Test the application

```bash
# Test using port-forward internally (http://localhost:8000)
kubectl port-forward -n webapp svc/express-server 8000:8000

vela port-forward -n webapp first-vela-app 8000:8000
```

Add following entry into the host file `/etc/host`

```bash
127.0.0.1 hello.webapp.example.com
```

## Example

`nginx-application.yaml`

```bash
# Apply the manifest
kubectl apply -n webapp -f nginx-application.yaml
```

Add entry into `/etc/host/`

```bash
...
127.0.0.1 nginx.webapp.example.com
```

Test the service using url http://nginx.webapp.example.com

```bash
# Describe the deployment to get: labele, annotations, volumes, request, etc..
kubectl describe deployment -n webapp nginx

# Get some resources created
kubectl get hpa,ingress -n webhap

# NAME                                        REFERENCE          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
# horizontalpodautoscaler.autoscaling/nginx   Deployment/nginx   <unknown>/50%   1         10        1          65s
# 
# NAME                                       CLASS    HOSTS                      ADDRESS         PORTS   AGE
# ingress.networking.k8s.io/nginx            <none>   nginx.webapp.example.com   192.168.1.142   80      10m

# Get the pod running
kubectl get pods -n webapp

# Connect into the pod (it must be running)
kubectl exec -it -n webapp nginx-7ffdc68c6b-v6q59 -- sh

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
