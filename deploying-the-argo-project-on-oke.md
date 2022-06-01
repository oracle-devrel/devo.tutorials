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
mrm: WWMK211125P00029
xredirect: https://developer.oracle.com/tutorials/deploying-the-argo-project-on-oke/
---
{% imgx alignright assets/argo-icon-color-800.png 400 400 "ARGO Logo" %}

In early 2020, the [Argo Project] was [accepted as an incubator-level] project in CNCF's stack and comprises a set of Kubernetes-native tools for running and managing jobs and applications on Kubernetes.

As a brief introduction, the Argo Project has 4 main components:

* [Argo Workflows]: a native workflow engine to orchestrate parallel jobs on Kubernetes
* [Argo CD]: a declarative, GitOps continuous delivery tool for Kubernetes
* [Argo Rollouts]: provides additional deployment strategies such as Blue-Green and Canary to Kubernetes
* [Argo Events]: provides an event-based dependency manager for Kubernetes

## Prerequisites

In order to successfully complete this tutorial, you'll need:

* A MacOS, Linux, or Windows computer with `ssh` support installed.
* The `kubectl` command-line tool.
* A `kubeconfig` file (default location is ~/.kube/config).

## Getting started

In this tutorial, we'll cover how to:

* Create a test OKE cluster for Argo
* Install Argo CD
* Connect to the Argo CD API Server
* Deploy applications using the Argo CD UI
* Deploy Argo Rollouts

So, without wasting any time, let's take Argo CD for a spin!

## Creating a test OKE cluster for Argo

1. Clone the [terraform-oci-oke repo] or [use the published terraform OKE module] on the [Terraform registry] to create an OKE Cluster.  
   >**NOTE:** You can also use [the Quick Create] feature to create your cluster if you don't want to use Terraform.

1. Ensure you use the following parameters in your `terraform.tfvars`:

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

1. In the console, run:

      ```console
      terraform init  
      terraform apply -auto-approve
      ```

1. Once Terraform has finished, ssh to the operator by copying the ssh command from the output. For example:

      ```console
      ssh -i ~/.ssh/id_rsa -J opc@XXX.XXX.XXX.XXX opc@10.0.1.10
      ```

## Argo CD

[Argo CD] is a declarative, GitOps continuous delivery tool for Kubernetes. It allows:

* Application definitions, configurations, and environments to be declarative and version controlled
* Application deployment and lifecycle management to be automated, auditable, and easy to understand

In this section we'll follow Argo CD's [getting started guide].

1. Install Argo CD

      ```console
      kubectl create namespace argocd
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      ```

2. Download and install the Argo CD CLI:

      ```console
      curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.1.3/argocd-linux-amd64
      chmod +x argocd-linux-amd64
      sudo mv argocd-linux-amd64 /usr/local/bin/argocd
      ```

### Access the Argo CD API server

#### Using port-forwarding

1. Establish an SSH tunnel to operator:

      ```console
      ssh -L 8080:localhost:8080 -i ~/.ssh/id_rsa -J opc@<bastion_public_ip> opc@<operator_private_ip>
      ```

2. Then we port-forward to the Argo CD service:

      ```console
      kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443
      ```

   We can now access the ArgoCD UI in our browser at `https://localhost:8080`

#### Using the Load Balancer

Or, we can change the service type to Load Balancer and use the IP Address of the Load Balancer to access the UI:

```console
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### Argo CD login

Whichever way we use to connect to the Argo CD API server, we'll be warned of a potential security risk. That's because we didn't install certificates and take other security precautions. However, we can still do that later by using [Let's Encrypt](https://letsencrypt.org/) and [cert-manager](https://cert-manager.io/) and then use this together with an [Ingress Controller](https://medium.com/oracledevs/experimenting-with-ingress-controllers-on-oracle-container-engine-oke-part-1-5af51e6cdb85) like the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/). Make sure you read Argo's [documentation on using Ingress](https://argoproj.github.io/argo-cd/operator-manual/ingress/).  

1. **Skip security warning for now:** Since our goal is to get things set up and we know that we can postpone these tasks until later, we'll just skip passed these warnings and select:  
   **Advanced > Accept the Risk and Continue**

2. **log in:** The ArgoCD login page will appear and will require a password.  
   Use the following to log in:  

   * **login:** admin
   * **password:** `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`  
   Since the initial password is just saved as plain text in the `argocd-initial-admin-secret` secret, we can use this to retrieve the information we need.

   {% imgx aligncenter assets/argo-oke-login-1024.jpg 1024 557 Argo Login Screen %}

### Creating apps via the UI

Once you're connected to the Argo CD API server, follow the rest of the instructions in [creating apps via UI].  

#### Deploy application

Once the application is created, select **Sync** and watch the application being deployed as Kubernetes works its magic to create the various resources (deployment, service, ReplicaSet, pods, etc.).

{% imgx aligncenter assets/argo-oke-ui.png 1024 557 Argo CD Screen %}

#### Acquaint yourself with the UI

Once the application is deployed, take a moment to poke around the Argo UI and the Kubernetes resources.  

While you're taking the tour, there are definitely some destinations you should visit. Let's take a quick look at one of them:  

1. Select the *guestbook-ui* service and then select **Edit**.
2. Change the service type from *ClusterIP* to *LoadBalancer* and then save.  
   Once the OCI Load Balancer is provisioned, its public IP address appears. Awesome stuff! You can make a quick check on the OCI Console to verify.

From here, you can experiment with other applications such as the *sock-shop* or using other tools such as [helm] or [kustomize]. You can find more examples in this [example apps repo].

## Argo Rollouts

Argo Rollouts provides additional deployment strategies such as *Blue-Green* and *Canary to Kubernetes*. In this section, we'll dive right in and follow Rollouts' [getting started guide] to do a Blue-Green deployment.

### Deploy Blue-Green

1. To install Blue-Green, run:

      ```console
      kubectl create namespace argo-rollouts
      kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
      ```

1. Install the Argo Rollouts *kubectl* plugin by running the following commands:

      ```console
      curl -LO  https://github.com/argoproj/argo-rollouts/releases/download/v1.0.7/kubectl-argo-rollouts-linux-amd64

      chmod +x kubectl-argo-rollouts-linux-amd64

      sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
      ```

1. To test the plugin:

      ```console
       kubectl argo rollouts version
      ```

### Switch from Kubernetes

Switching from the default Kubernetes [Deployment to Rollout] is very easy:

1. Change the `apiVersion` from *`apps/v1*` to _`argoproj.io/v1alpha1`_
2. Change the `kind` from *Deployment* to *Rollout*
3. Add a *deployment strategy* to the Rollout object

### Deploy a Rollout

1. Create a `bluegreen.yaml` file (copied from the Argo CD documentation and example) on the operator host:

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

1. Deploy it:

      ```console
      kubectl apply -f bluegreen.yaml
      ```

### Verify deployment

1. Verify that we have 2 pods created:

      ```console
      kubectl get pods 
      ```

1. List the `ReplicaSet`:

      ```console
      NAME                                  DESIRED   CURRENT   READY   AGE   CONTAINERS       IMAGES                                       SELECTOR
      rollout-bluegreen-6565b74f44          1         1         1       83s   rollouts-demo    argoproj/rollouts-demo:blue                  app=rollout-bluegreen,rollouts-pod-template-hash=6565b74f44
      ```

   We can see that the image deployed is of the `blue` variety. Similarly, if get Argo Rollouts to print thing for us:

      ```console
      kubectl argo rollouts get rollout rollout-bluegreen -w
      ```

   **Sample output:**  

      ```console
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

### Dashboard

We can also use the Argo Rollouts dashboard to visualize things.  

>**NOTE:** If you're logged in the operator host, exit and log in again:
>
>```console
>ssh -L 3100:localhost:3100 -i ~/.ssh/id_rsa -J opc@132.226.28.30 opc@10.0.0.14
>```
>
{:.notice}

#### Access the dashboard

1. To start up the dashboard, run:

      ```console
      kubectl argo rollouts dashboard
      ```

1. Use your browser to access the Rollout dashboards:

   {% imgx alignright assets/argo-oke-dhasboard.png 400 400 "ARGO Rollout Dashboard" %}

#### Example - load balancers

Finally, since we deployed both services as `type=LoadBalancer`, we will have 2 Load Balancers.  

1. **Look up public IP addresses -** You can look up their respective public IP addresses in the OCI console or use kubectl to look them up in the EXTERNAL-IP column when you run:

      ```console
      kubectl get svc 
      ```

1. Use you browser to access them:

   {% imgx aligncenter assets/argo-oke-blue.png 400 400 "Blue Rollout" %}

   >**NOTE:** Both the active and preview will be blue.
   {:.notice}

**Quick test - upgrade from blue to green:**

1. **Upgrade -** Let's now patch to upgrade from blue to green:

      ```console
      kubectl patch rollout rollout-bluegreen --type merge -p '{"spec": {"template": { "spec": { "containers": [{"name": "rollouts-demo","image": "argoproj/rollouts-demo:green"}]}}}}'
      ```

   And we can see effect immediately:

   {% imgx aligncenter assets/argo-oke-rollout-patch.png 600 400 "Patch Rollout" %}

1. **Preview -** If we access the preview for *active Load Balancers*, we'll see the preview is green and active is still blue.

   {% imgx aligncenter assets/argo-oke-green.png 600 400 "Patch Rollout" %}

1. **Promotion -** Let's give the rollout a promotion. We can use command line as thus:

      ```console
        kubectl promote rollout-bluegreen
      ```

   or if you have Argo Rollouts Dashboard still open, you can use that too.

   {% imgx aligncenter assets/argo-oke-promoted.png 600 400 "Patch Rollout" %}

   If we now access both load balancers, they'll both show up as green. You can keep switching between them to simulate upgrading to newer versions of your application.

## What's next

At this point, we'll pause here and leave Argo Events for a future article. Hopefully this tutorial has shown you that if you were considering running the Argo project on your Kubernetes cluster, OKE will work quite nicely with it.

>**NOTE:** This article was originally included as part of the [Oracle developers series] on April, 2020. It has been updated to focus on ArgoCD and Rollouts and also to reflect the changes in the terraform-oci-oke project.
{:.notice}

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

<!--- Links -->

[Argo Project]: https://argoproj.github.io/
[accepted as an incubator-level]: https://www.cncf.io/blog/2020/04/07/toc-welcomes-argo-into-the-cncf-incubator/

[Argo Workflows]: https://argoproj.github.io/workflows
[Argo CD]: https://argoproj.github.io/cd
[Argo Rollouts]: https://argoproj.github.io/rollouts
[Argo Events]: https://argoproj.github.io/events
[Argo Project]: https://argoproj.github.io/
[accepted as incubator-level]: https://www.cncf.io/blog/2020/04/07/toc-welcomes-argo-into-the-cncf-incubator/
[terraform-oci-oke repo]: https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/master/docs/quickstart.adoc#provisioning-using-this-git-repo
[use the published terraform OKE module]: https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/master/docs/quickstart.adoc#provisioning-using-the-hashicorp-registry-module
[Terraform registry]: https://registry.terraform.io/modules/oracle-terraform-modules/oke/oci/latest
[the Quick Create]: https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingokehtm#create-quick-cluster
[getting started guide]: https://argo-cd.readthedocs.io/en/stable/getting_started/
[Deployment to Rollout]: https://argoproj.github.io/argo-rollouts/getting-started/#converting-deployment-to-rollout
[creating apps via UI]: https://argoproj.github.io/argo-cd/getting_started/#creating-apps-via-ui
[helm]: https://helm.sh/
[kustomize]: https://kustomize.io/
[example apps repo]: https://github.com/argoproj/argocd-example-apps
[getting started guide]: https://argoproj.github.io/argo-rollouts/getting-started/

[Oracle developers series]: https://medium.com/oracledevs/deploying-the-argo-project-on-oke-ee96cabf8910
