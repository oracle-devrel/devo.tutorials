---
title: Deploying the Argo CD on Oracle Container Engine for Kubernetes (OKE)
parent: tutorials
tags:
- open-source
- oke
- kubernetes
- terraform
- devops
categories:
- cloudapps
- opensource
thumbnail: assets/argo-icon-color-800.png
date: 2021-09-22 15:30
description: How to deploy the Argo CD on an OKE cluster.
toc: true
author:
  name: Ali Mukadam
  home: https://lmukadam.medium.com
  bio: |-
    Technical Director, Asia Pacific Center of Excellence.

    For the past 16 years, Ali has held technical presales, architect and industry consulting roles in BEA Systems and Oracle across Asia Pacific, focusing on middleware and application development. Although he pretends to be Thor, his real areas of expertise are Application Development, Integration, SOA (Service Oriented Architecture) and BPM (Business Process Management). An early and worthy Docker and Kubernetes adopter, Ali also leads a few open source projects (namely [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke)) aimed at facilitating the adoption of Kubernetes and other cloud native technologies on Oracle Cloud Infrastructure.
  linkedin: https://www.linkedin.com/in/alimukadam/
redirect_from: "/collections/tutorials/deploying-the-argo-project-on-oke/"
---
{% imgx alignright assets/argo-icon-color-800.png 400 400 "ARGO Logo" %}


I was quite thrilled to learn that the [Argo Project](https://argoproj.github.io/) was [accepted as incubator-level](https://www.cncf.io/blog/2020/04/07/toc-welcomes-argo-into-the-cncf-incubator/) project in CNCF's stack.

As a brief introduction, the Argo Project has 4 main components:

* [Argo Workflows](https://argoproj.github.io/projects/argo/): a native workflow engine to orchestrate parallel jobs on Kubernetes
* [Argo CD](https://argoproj.github.io/projects/argo-cd/): a declarative, GitOps continuous delivery tool for Kubernetes
* [Argo Rollouts](https://argoproj.github.io/argo-rollouts/): provides additional deployment strategies such as Blue-Green and Canary to Kubernetes
* [Argo Events](https://argoproj.github.io/projects/argo-events/): provides an event-based dependency manager for Kubernetes

So without wasting any time, let's take Argo CD for a spin and [I'll be your Huckleberry](https://www.youtube.com/watch?v=R8OWNspU_yE).

## Creating a test OKE cluster for Argo

Clone the [terraform-oci-oke repo](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/master/docs/quickstart.adoc#provisioning-using-this-git-repo) or [use the published terraform OKE module ](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/master/docs/quickstart.adoc#provisioning-using-the-hashicorp-registry-module) on the [Terraform registry](https://registry.terraform.io/modules/oracle-terraform-modules/oke/oci/latest) to create an OKE Cluster. You can also use [the Quick Create ](https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm#create-quick-cluster) feature to create your cluster if you don't want to use terraform.

Ensure you use the following parameters in your terraform.tfvars:

```tf
label_prefix = "argo"
region = "us-phoenix-1"

vcn_dns_label = "oke"
vcn_name = "oke"

create_bastion_host = true

create_operator              = true
admin_instance_principal     = true
control_plane_type           = "private"

node_pools = {
  np1 = { shape = "VM.Standard.E4.Flex", ocpus = 1, memory = 16, node_pool_size = 2, boot_volume_size = 150 }
}
```

```console
$ terraform init  
$ terraform apply -auto-approve
```

Once Terraform has finished, ssh to the operator by copying the ssh command from the output e.g. :

```console
$ ssh -i ~/.ssh/id_rsa -J opc@XXX.XXX.XXX.XXX opc@10.0.1.10
```

## Argo CD

[Argo CD](https://argoproj.github.io/projects/argo-cd/) is a declarative, GitOps continuous delivery tool for Kubernetes. This says a lot without being too wordy. When you look at the user guide and features, this brief description probably undersells Argo CD.

Let's follow Argo CD's [getting started guide](https://argoproj.github.io/argo-cd/getting_started/):

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Download and install the Argo CD cli:

```console
$ curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.1.3/argocd-linux-amd64
$ chmod +x argocd-linux-amd64
$ sudo mv argocd-linux-amd64 /usr/local/bin/argocd
```

Let's use port-forwarding to access the UI. First, we establish an SSH tunnel to operator:

```
ssh -L 8080:localhost:8080 -i ~/.ssh/id_rsa -J opc@<bastion_public_ip> opc@<operator_private_ip>
```

Then we port-forward to the ArgoCD service:

```
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443
```

We can now access the ArgoCD UI in our browser at https://localhost:8080/

Or we can change the service type to Load Balancer and use the IP Address of the Load Balancer to access the UI:

```console
$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

We will be warned of a potential security risk. That's because we didn't install certificates etc. We can do that later by using [Let's Encrypt](https://letsencrypt.org/) and [cert-manager](https://cert-manager.io/) and then use this together with an [Ingress Controller](https://medium.com/oracledevs/experimenting-with-ingress-controllers-on-oracle-container-engine-oke-part-1-5af51e6cdb85) like the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/). Make sure you read Argo's [documentation on using Ingress](https://argoproj.github.io/argo-cd/operator-manual/ingress/). But we are in a hurry, so we'll just skip these and click 'Advanced' > 'Accept the Risk and Continue'.

The ArgoCD login page will appear and we need the password: 

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Login with username `admin` and the password above.

Since we didn't add the certificate, we'll be warned of potential security risks ahead. To solve this, we can add a certificate using  Again, we're in a bit of a hurry, so we'll just skip these and click 'Accept the Risk and Continue'.

We'll now be redirected to Argo CD login page. Let's retrieve the generated password:
    
```console
$ kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

and login with username admin and the retrieved password.

{% imgx aligncenter assets/argo-oke-login-1024.jpg 1024 557 Argo Login Screen %}

Follow the rest of the instructions in [creating apps via UI](https://argoproj.github.io/argo-cd/getting_started/#creating-apps-via-ui). Once the application is created, click on 'Sync' and watch the application being deployed as Kubernetes works its way to creating the various resources (deployment, service, ReplicaSet, pods, etc).

{% imgx aligncenter assets/argo-oke-ui.png 1024 557 Argo CD Screen %}

Once the application is deployed, take a moment to poke around the Argo UI and the Kubernetes resources. Select the guestbook-ui service and click 'Edit'. Change the service type from ClusterIP to LoadBalancer and then save. Once the OCI Load Balancer is provisioned, its public IP address appears. Awesome stuff. I pinch myself and make a quick check on OCI Console to verify the Load Balancer IP just to ensure I'm not imagining this. Nope, I'm not.

From here, you can experiment with other applications such as the sock-shop or using other tools such as [helm ](https://helm.sh/)or [kustomize](https://kustomize.io/). You can find more examples in this [example apps repo](https://github.com/argoproj/argocd-example-apps).

## Argo Rollouts

Argo Rollouts provides additional deployment strategies such as Blue-Green and Canary to Kubernetes. Let's dive right into it and follow Rollouts' [getting started guide](https://argoproj.github.io/argo-rollouts/getting-started/) to do a blue-green deployment:

```console
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

Let's first install the Argo Rollouts kubectl plugin:

```
curl -LO  https://github.com/argoproj/argo-rollouts/releases/download/v1.0.7/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

Let's test the plugin:

```
 kubectl argo rollouts version
```

Switching from the default Kubernetes [Deployment to Rollout](https://argoproj.github.io/argo-rollouts/getting-started/#converting-deployment-to-rollout) is very easy:

1. Change the apiVersion from apps/v1 to argoproj.io/v1alpha1
2. Change the kind from Deployment to Rollout
3. Add a deployment strategy to the Rollout object

Create a bluegreen.yaml file (copied from the Argo CD documentation and example) on the operator host:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-bluegreen
spec:
  replicas: 2
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: rollout-bluegreen
  template:
    metadata:
      labels:
        app: rollout-bluegreen
    spec:
      containers:
      - name: rollouts-demo
        image: argoproj/rollouts-demo:blue
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
  strategy:
    blueGreen: 
      # activeService specifies the service to update with the new template hash at time of promotion.
      # This field is mandatory for the blueGreen update strategy.
      activeService: rollout-bluegreen-active
      # previewService specifies the service to update with the new template hash before promotion.
      # This allows the preview stack to be reachable without serving production traffic.
      # This field is optional.
      previewService: rollout-bluegreen-preview
      # autoPromotionEnabled disables automated promotion of the new stack by pausing the rollout
      # immediately before the promotion. If omitted, the default behavior is to promote the new
      # stack as soon as the ReplicaSet are completely ready/available.
      # Rollouts can be resumed using: `kubectl argo rollouts promote ROLLOUT`
      autoPromotionEnabled: false
---
kind: Service
apiVersion: v1
metadata:
  name: rollout-bluegreen-active
spec:
  type: LoadBalancer
  selector:
    app: rollout-bluegreen
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080

---
kind: Service
apiVersion: v1
metadata:
  name: rollout-bluegreen-preview
spec:
  type: LoadBalancer
  selector:
    app: rollout-bluegreen
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

and let's deploy it:

```console
$ kubectl apply -f bluegreen.yaml
```

Verify that we have 2 pods created:

```console
kubectl get pods 
```

Let's list the ReplicaSet:

```
NAME                                  DESIRED   CURRENT   READY   AGE   CONTAINERS       IMAGES                                       SELECTOR
rollout-bluegreen-6565b74f44          1         1         1       83s   rollouts-demo    argoproj/rollouts-demo:blue                  app=rollout-bluegreen,rollouts-pod-template-hash=6565b74f44
```
We can see that the image deployed is of the `blue` variety. Similarly, if get Argo Rollouts to print thing for us:

```
kubectl argo rollouts get rollout rollout-bluegreen -w

Name:            rollout-bluegreen
Namespace:       default
Status:          ✔ Healthy
Strategy:        BlueGreen
Images:          argoproj/rollouts-demo:blue (stable, active)
Replicas:
  Desired:       2
  Current:       2
  Updated:       2
  Ready:         2
  Available:     2

NAME                                           KIND        STATUS     AGE    INFO
⟳ rollout-bluegreen                            Rollout     ✔ Healthy  21m
└──# revision:1
   └──⧉ rollout-bluegreen-6565b74f44           ReplicaSet  ✔ Healthy  20m    stable,active
      ├──□ rollout-bluegreen-6565b74f44-qps4m  Pod         ✔ Running  19m    ready:1/1
      └──□ rollout-bluegreen-6565b74f44-twx2x  Pod         ✔ Running  4m19s  ready:1/1
```

We can also use the Argo Rollouts dashboard to visualize things. If you're logged in the operator host, exit and login again:

```
ssh -L 3100:localhost:3100 -i ~/.ssh/id_rsa -J opc@132.226.28.30 opc@10.0.0.14
```

Then, run the following command to access the dashboard:

```
kubectl argo rollouts dashboard
```

And use the browser to access the Rollout dashboards:

{% imgx alignright assets/argo-oke-dhasboard.png 400 400 "ARGO Rollout Dashboard" %}

Finally, since we deployed both services as `type=LoadBalancer`, we will have 2 Load Balancers. You can look up their respective public IP addresses in the OCI console or use kubectl to look them up in the EXTERNAL-IP column when you run:

```
kubectl get svc 
```

Use you browser to access them:

{% imgx aligncenter assets/argo-oke-blue.png 400 400 "Blue Rollout" %}

Both the active and preview will be blue. 

Let's now patch to upgrade from blue to green:

```
kubectl patch rollout rollout-bluegreen --type merge -p '{"spec": {"template": { "spec": { "containers": [{"name": "rollouts-demo","image": "argoproj/rollouts-demo:green"}]}}}}'
```

And we can see effect immediately:

{% imgx aligncenter assets/argo-oke-rollout-patch.png 600 400 "Patch Rollout" %}

And if we access the preview and active Load Balancers, we'll see the preview is green and active is still blue.

{% imgx aligncenter assets/argo-oke-green.png 600 400 "Patch Rollout" %}

Let's give the rollout a promotion. We can use command line as thus:

```console
  $ kubectl promote rollout-bluegreen
```

or if you have Argo Rollouts Dashboard still open, you can use that too.

{% imgx aligncenter assets/argo-oke-promoted.png 600 400 "Patch Rollout" %}

If we now access both load balancers, they'll both show up as green. You can keep switching between them to simulate upgrading to newer versions of your application.

I'll pause here and leave Argo Events for a future post. For now, I hope this shows you that if you were considering running the Argo project on your Kubernetes cluster, OKE will work quite nicely with it.

N.B. This article was originally posted on https://medium.com/oracledevs/deploying-the-argo-project-on-oke-ee96cabf8910. It has been updated to focus on ArgoCD and Rollouts and also to reflect the changes in the terraform-oci-oke project.
