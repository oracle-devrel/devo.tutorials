---
title: Deploying the ARGO Project on OKE
parent: tutorials
tags: [open-source, oke, kubernetes, terraform, devops]
categories: [cloudapps, opensource]
thumbnail: assets/argo-icon-color-800.png
date: 2021-09-22 15:30
description: How to deploy the Argo project on an OKE cluster.
toc: true
author: 
  name: Ali Mukadam
  home: https://lmukadam.medium.com
  bio: |-
       Technical Director, Asia Pacific Center of Excellence.

       For the past 16 years, Ali has held technical presales, architect and industry consulting roles in BEA Systems and Oracle across Asia Pacific, focusing on middleware and application development. Although he pretends to be Thor, his real areas of expertise are Application Development, Integration, SOA (Service Oriented Architecture) and BPM (Business Process Management). An early and worthy Docker and Kubernetes adopter, Ali also leads a few open source projects (namely [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke)) aimed at facilitating the adoption of Kubernetes and other cloud native technologies on Oracle Cloud Infrastructure.
  linkedin: https://www.linkedin.com/in/alimukadam/
---
{% img alignright assets/argo-icon-color-800.png 400 400 "ARGO Logo" %}


I was quite thrilled to learn that the [Argo Project](https://argoproj.github.io/) has [recently been accepted as incubator-level](https://www.cncf.io/blog/2020/04/07/toc-welcomes-argo-into-the-cncf-incubator/) project in CNCF's stack.

As a brief introduction, the Argo Project has 4 main components:

* [Argo Workflows](https://argoproj.github.io/projects/argo/): a native workflow engine to orchestrate parallel jobs on Kubernetes
* [Argo CD](https://argoproj.github.io/projects/argo-cd/): a declarative, GitOps continuous delivery tool for Kubernetes
* [Argo Rollouts](https://argoproj.github.io/argo-rollouts/): provides additional deployment strategies such as Blue-Green and Canary to Kubernetes
* [Argo Events](https://argoproj.github.io/projects/argo-events/): provides an event-based dependency manager for Kubernetes

So, without wasting any time, let's give them a try and [I'll be your Huckleberry](https://www.youtube.com/watch?v=R8OWNspU_yE).

## Creating a test OKE cluster for Argo

Clone the [terraform-oci-oke repo](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/master/docs/quickstart.adoc#provisioning-using-this-git-repo) or [use the published terraform OKE module ](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/master/docs/quickstart.adoc#provisioning-using-the-hashicorp-registry-module) on the [Terraform registry](https://registry.terraform.io/modules/oracle-terraform-modules/oke/oci/2.1.6) to create an OKE Cluster. You can also use [the Quick Create ](https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm#create-quick-cluster) feature to create your cluster if you don't want to use terraform.

Ensure you use the following parameters in your terraform.tfvars:

```tf
label_prefix = "argo"
region = "us-phoenix-1"

vcn_dns_label = "oke"
vcn_name = "oke"

bastion_enabled = true
bastion_shape = "VM.Standard.E2.2"
bastion_timezone = "Australia/Sydney"

admin_enabled = true
admin_instance_principal = true
admin_shape = "VM.Standard.E2.2"
admin_timezone = "Australia/Sydney"

node_pools = {
  np1 = ["VM.Standard.E2.2", 3]
}

create_service_account = false
```

```console
$ terraform init  
$ terraform apply -auto-approve
```

Once Terraform has finished, ssh to the admin console by copying the ssh command from the output:

```console
$ ssh -i ~/.ssh/id_rsa -J opc@XXX.XXX.XXX.XXX opc@10.0.1.10
```

## Argo Workflows

From here, we'll follow the [getting started guide](https://argoproj.github.io/docs/argo/getting-started.html) for Argo.

Download the Argo CLI on the admin server:

```console
$ curl -sLO https://github.com/argoproj/argo/releases/download/v2.7.5/argo-linux-amd64
$ chmod +x argo-linux-amd64  
$ sudo mv ./argo-linux-amd64 /usr/local/bin/argo

$ argo version
```

Create the namespace and install Argo:

```console    
$ kubectl create namespace argo  
$ kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml
```

Next, we need to configure a ServiceAccount with the [necessary privileges](https://argoproj.github.io/docs/argo/workflow-rbac.html). But we're in a bit of a hurry so we'll just use the default service account:

```console  
$ kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=default:default
```

Run sample workflows:

```console   
$ argo submit --watch https://raw.githubusercontent.com/argoproj/argo/master/examples/hello-world.yaml
```

And we can watch the workflow steps:

```console
$ argo submit --watch https://raw.githubusercontent.com/argoproj/argo/master/examples/hello-world.yaml                                                   
Name:                hello-world-7j4wn
Namespace:           default
ServiceAccount:      default
Status:              Pending
Created:             Tue Apr 21 14:04:21 +1000 (now)
Name:                hello-world-7j4wn
Namespace:           default
ServiceAccount:      default
Status:              Pending
Created:             Tue Apr 21 14:04:21 +1000 (now)
Name:                hello-world-7j4wn
Namespace:           default
ServiceAccount:      default
Status:              Running
Created:             Tue Apr 21 14:04:21 +1000 (now)
Started:             Tue Apr 21 14:04:21 +1000 (now)
Duration:            0 seconds

STEP                  TEMPLATE  PODNAME            DURATION  MESSAGE
 ◷ hello-world-7j4wn  whalesay  hello-world-7j4wn  0s
Name:                hello-world-7j4wn
Namespace:           default
ServiceAccount:      default
Status:              Running
Created:             Tue Apr 21 14:04:21 +1000 (1 second ago)
Started:             Tue Apr 21 14:04:21 +1000 (1 second ago)
Duration:            1 second

STEP                  TEMPLATE  PODNAME            DURATION  MESSAGE
 ◷ hello-world-7j4wn  whalesay  hello-world-7j4wn  1s        ContainerCreating
Name:                hello-world-7j4wn
Namespace:           default
ServiceAccount:      default
Status:              Running
Created:             Tue Apr 21 14:04:21 +1000 (3 seconds ago)
Started:             Tue Apr 21 14:04:21 +1000 (3 seconds ago)
Duration:            3 seconds

STEP                  TEMPLATE  PODNAME            DURATION  MESSAGE
 ● hello-world-7j4wn  whalesay  hello-world-7j4wn  3s
Name:                hello-world-7j4wn
Namespace:           default
ServiceAccount:      default
Status:              Succeeded
Created:             Tue Apr 21 14:04:21 +1000 (4 seconds ago)
Started:             Tue Apr 21 14:04:21 +1000 (4 seconds ago)
Finished:            Tue Apr 21 14:04:25 +1000 (now)
Duration:            4 seconds

STEP                  TEMPLATE  PODNAME            DURATION  MESSAGE
 ✔ hello-world-7j4wn  whalesay  hello-world-7j4wn  3s
```

You can also try other workflow examples such as the [coinflip](https://raw.githubusercontent.com/argoproj/argo/master/examples/coinflip.yaml). Checkout the GitHub repo for a full list of [examples](https://argoproj.github.io/docs/argo/examples/readme.html).

## Argo CD

The next thing we want to try is [Argo CD](https://argoproj.github.io/projects/argo-cd/). ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. This says a lot without being too wordy. When you look at the user guide and features, this brief description probably undersells Argo CD.

Let's follow Argo CD's [getting started guide](https://argoproj.github.io/argo-cd/getting_started/):

```
$ kubectl create namespace argocdkubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Download and install the Argo CD cli:

```console
$ curl -sLO https://github.com/argoproj/argo-cd/releases/download/v1.4.3/argocd-linux-amd64
$ chmod +x argocd-linux-amd64
$ sudo mv argocd-linux-amd64 /usr/local/bin/argocd
```

Change the service type to Load Balancer and use the IP Address of the Load Balancer to access the UI:

```console
$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Since we didn't add the certificate, we'll be warned of potential security risks ahead. To solve this, we can add a certificate using [Let's Encrypt](https://letsencrypt.org/) and [cert-manager](https://cert-manager.io/) and then use this together with an [Ingress Controller](https://medium.com/oracledevs/experimenting-with-ingress-controllers-on-oracle-container-engine-oke-part-1-5af51e6cdb85) like the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/). Make sure you read Argo's [documentation on using Ingress](https://argoproj.github.io/argo-cd/operator-manual/ingress/). Again, we're in a bit of a hurry, so we'll just skip these and click 'Accept the Risk and Continue'.

We'll now be redirected to Argo CD login page. Let's retrieve the generated password:
    
```console
$ kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

and login with username admin and the retrieved password.

{% img aligncenter assets/argo-oke-login-1024.jpg 1024 557 Argo Login Screen %}

Follow the rest of the instructions in [creating apps via UI](https://argoproj.github.io/argo-cd/getting_started/#creating-apps-via-ui). Once the application is created, click on 'Sync' and watch the application being deployed as Kubernetes works its way to creating the various resources (deployment, service, ReplicaSet, pods, etc).

Once the application is deployed, take a moment to poke around the Argo UI and the Kubernetes resources. Select the guestbook-ui service and click 'Edit'. Change the service type from ClusterIP to LoadBalancer and then save. Once the OCI Load Balancer is provisioned, its public IP address appears. Awesome stuff. I pinch myself and make a quick check on OCI Console to verify the Load Balancer IP just to ensure I'm not imagining this. Nope, I'm not.

From here, you can experiment with other applications such as the sock-shop or using other tools such as [helm ](https://helm.sh/)or [kustomize](https://kustomize.io/). You can find more examples in this [example apps repo](https://github.com/argoproj/argocd-example-apps).

## Argo Rollouts

Argo Rollouts provides additional deployment strategies such as Blue-Green and Canary to Kubernetes. Let's dive right into it and follow Rollouts' [getting started guide](https://argoproj.github.io/argo-rollouts/getting-started/):

```console
$ kubectl create namespace argo-rollouts
$ kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
```

Switching from the default Kubernetes [Deployment to Rollout](https://argoproj.github.io/argo-rollouts/getting-started/#converting-deployment-to-rollout) is very easy:

1. Change the apiVersion from apps/v1 to argoproj.io/v1alpha1
2. Change the kind from Deployment to Rollout
3. Add a deployment strategy to the Rollout object

Create an nginx yaml file (copied from the Argo CD documentation) on the admin server:

```yaml
apiVersion: argoproj.io/v1alpha1 # Changed from apps/v1  
kind: Rollout # Changed from Deployment  
# ----- Everything below this comment is the same as a deployment -----  
metadata:  
  name: example-rollout  
spec:  
  replicas: 5  
  selector:  
    matchLabels:  
      app: nginx  
  template:  
    metadata:  
      labels:  
        app: nginx  
    spec:  
      containers:  
      - name: nginx  
        image: nginx:1.15.4  
        ports:  
        - containerPort: 80  
  minReadySeconds: 30  
  revisionHistoryLimit: 3  
  strategy:  
  # ----- Everything above this comment are the same as a deployment -----  
    canary: # A new field that used to provide configurable options for a Canary strategy  
      steps:  
      - setWeight: 20  
      - pause: {}
```

and then create it:

```console
$ kubectl apply -f nginx.yaml
```

Verify that we have 5 pods created:

```console
$ kubectl get pods 
```

Now let's apply the patch to upgrade the nginx image from 1.15.4 to 1.15.5 and watch the replica set:

```console
$ kubectl patch rollout example-rollout --type merge -p '{"spec": {"template": { "spec": { "containers": [{"name": "nginx","image": "nginx:1.15.5"}]}}}}'kubectl get replicaset -w -o wide
```

This is what we should see:
    
    NAME                         DESIRED   CURRENT   READY  IMAGES  
    example-rollout-66767759b    1         1         0      nginx:1.15.5  
    example-rollout-76f5bddc69   5         5         5      nginx:1.15.4  
    example-rollout-66767759b    1         1         1      nginx:1.15.5  
    example-rollout-66767759b    1         1         1      nginx:1.15.5  
    example-rollout-76f5bddc69   4         5         5      nginx:1.15.4  
    example-rollout-76f5bddc69   4         5         5      nginx:1.15.4  
    example-rollout-76f5bddc69   4         4         4      nginx:1.15.4

Because we set the weight to 20 (percent), only 1 of the 5 replicas was upgraded.

Argo Rollouts has a kubectl plugin that helps automate the promotion. Let's install it on the admin server. Since kubectl is already installed from the yum repo, let's not mess too much with it and instead install it in $HOME/bin:

```console
$ mkdir ~/bin
$ curl -sLO https://github.com/argoproj/argo-rollouts/releases/download/v0.8.1/kubectl-argo-rollouts-linux-amd64
$ mv kubectl-argo-rollouts-linux-amd64 ~/bin/kubectl
$ chmod +x ~/bin/kubectl
$ export PATH=~/bin:$PATH
```

Verify we are now using the local kubectl:
    
```console
$ which kubectl  
~/bin/kubectl
```

Let's do a promote:

```console
$ kubectl promote example-rollout
```

And then a watch again:

```console    
$ kubectl get replicaset -w -o wide
```

And we'll now see all 5 have been upgraded:
    
    NAME                         DESIRED CURRENT READY   IMAGES   
    example-rollout-66767759b        5      5     5      nginx:1.15.5  
    example-rollout-76f5bddc69       0      0     0      nginx:1.15.4

I'll pause here and leave Argo Events for a future post. For now, I hope this shows you that if you were considering running the Argo project on your Kubernetes cluster, OKE will work quite nicely with it.
