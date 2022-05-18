---
title: Deploying Verrazzano on Oracle Container Engine for Kubernetes (OKE)
parent: [tutorials, multi-cluster-verrazzano-oke]
tags: [open-source, oke, kubernetes, verrazzano,terraform, devops]
categories: [cloudapps, opensource]
thumbnail: assets/verrazzano-logo.png
date: 2021-12-03 09:11
description: How to deploy Verrazzano an OKE cluster.
color: purple
mrm: WWMK211123P00031
author: ali-mukadam
---
{% imgx alignright assets/verrazzano-logo.png 400 400 "Verrazzano Logo" %}

[Terraform 1.0.0]: https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm

[Verrazzano quickstart guide]: https://verrazzano.io/latest/docs/quickstart/

[Introducing Verrazzano Enterprise]: https://blogs.oracle.com/developers/post/introducing-oracle-verrazzano-enterprise-container-platform

[Hello World Helidon]: https://verrazzano.io/latest/docs/samples/hello-helidon/

[Prometheus]: https://blogs.oracle.com/linux/post/learn-to-monitor-cloud-apps-and-services-with-prometheus

[Grafana]: https://blogs.oracle.com/oracle-systems/post/oracle-pca-x9-2-monitoring-and-alerting-with-grafana

You may have been following Oracle's open-source development of Verrazzano and were curious to know what it was about. Technically speaking, [Verrazzano](https://verrazzano.io/) is an "end-to-end container platform to deploy cloud native and traditional applications in multi-cloud and hybrid environments." If that’s a lot to take in, it’s because Verrazzano, (v8o for short) packs a lot in! But in essence, Verrazzano is a bridge between on-premises and the cloud, enabling you to deploy your container applications to any of the Kubernetes clusters where Verrazzano is installed.

In this first part of the series, we'll first cover the single-cluster deployment of Verrazzano on the [Oracle Container Engine](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm#top) (OKE) and then learn how to deploy an example application and monitor its activity.

Topics include learning how to:

- Create a Kubernetes cluster
- Install the Verrazzano platform operator
- Install and access Verrazzano
- Deploy, access, and monitor an example application

For additional information, see:

- [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)
- [Introducing Verrazzano Enterprise]
- [Verrazzano quickstart guide]

## Before you begin

To successfully complete this tutorial, you will need to have the following:

- An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }})
- A MacOS, Linux, or Windows computer with `ssh` support installed
- Git
- [Terraform 1.0.0] or later

## Creating the OKE cluster

Time to dig in! Let's start by creating the OKE cluster using the [Terraform OKE module](https://github.com/oracle-terraform-modules/terraform-oci-oke). Fortunately, since we're only taking Verrazzano for a spin, we just need the bare minimum of features.  

For this, we've prepared a [quickstart](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/main/docs/quickstart.adoc) guide to get you going.

1. Begin by following the instructions to create:

   - the providers, *and*  
   - a copy of the file, `terraform.tfvars.example`
      > **NOTE:** Be sure that you rename the copy to `terraform.tfvars`.  
      {:.alert}  

2. Before moving ahead, confirm that the following features/resources are enabled/created:  

   ```terraform
   create_bastion_host = true
   bastion_access = ["anywhere"]
   create_operator                    = true
   enable_operator_instance_principal = true
   node_pools = {
     np1 = { shape = "VM.Standard.E4.Flex", ocpus = 2, memory = 32, node_pool_size = 2, boot_volume_size = 150}
   }
   ```

3. Now that we have the environment just as we need it, continue with the rest of the quickstart to run `terraform init` and `tarraform apply`.

4. Once the cluster is created, we can use the output to conveniently copy the command that tells us how to ssh to the operator host:

   ```console
   ssh_to_operator = "ssh -i ~/.ssh/id_rsa -J opc@xyz.xyz.xyz.xyz opc@10.0.0.12"
   ```

> **NOTE:** For the rest of the tutorial, all `kubectl` commands are executed on the operator host.
{:.alert}

## Installing the Verrazzano operator

Verrazzano provides a Kubernetes operator to manage the life cycle of Verrazzano installations. In this section, we'll learn how to install this operator.  

1. Deploy the Verrazzano operator by running:

   ```console
   kubectl apply -f https://github.com/verrazzano/verrazzano/releases/download/v1.0.1/operator.yaml
   ```

2. Wait for the deployment to complete:

   ```console
   $ kubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
   Waiting for deployment "verrazzano-platform-operator" rollout to finish: 0 of 1 updated replicas are available...
   ```

   > **NOTE:** Be patient! The operator make take a couple of minutes to deploy.
   {:.alert}

3. Verify that the operator is running:

   ```console
   $ kubectl -n verrazzano-install get pods
   NAME                                            READY   STATUS    RESTARTS   AGE
   verrazzano-platform-operator-5f788568fd-w8cz7   1/1     Running   0          80s
   ```

## Installing Verrazzano

Now that we have all of the preliminary set up out of the way, we're ready to install Verrazzano.  

1. For this exercise, install Verrazzano with the `dev` profile:

   ```console
   $ kubectl apply -f - <<EOF
   apiVersion: install.verrazzano.io/v1alpha1
   kind: Verrazzano
   metadata:
     name: hello-verrazzano
   spec:
     profile: dev
   EOF
   ```

1. Wait for Verrazzano to install:

   ```console
   $ kubectl wait \
       --timeout=20m \
       --for=condition=InstallComplete \
       verrazzano/
   ```

## Accessing Verrazzano

We've successfully installed Verrazzano, so how do we access it? We'll first need to determine the Verrazzano console URL.  

1. To obtain the console URL, run:

   ```console
   kubectl get vz -o yaml
   ```

   This command will return a list of URLs. For example, a Verrazzano console URL may look similar to: `https://verrazzano.default.168.138.102.88.nip.io`.

2. Once you have the console URL, copy it into your browser. At this point, you'll be prompted to log in:

   {% imgx aligncenter assets/verrazzano-login.png 1024 557 Verrazzano Login Screen %}

   **username:**
   : The username is: `verrazzano`  

   **password:**
   : To get the password, run:

      ```console
      $ kubectl get secret \
          --namespace verrazzano-system verrazzano \
          -o jsonpath={.data.password} | base64 \
          --decode; echo
      ```

   You should now be able to access the Verrazzano console:

   {% imgx aligncenter assets/verrazzano-console.png 1024 557 Verrazzano Console %}

### Deploy an example application to Verrazzano

With Verrazzano installed and configured, we're ready to deploy our first application. We'll keep it simple to start by creating a version of an old friend, the hello-world example. The [Hello World Helidon] application returns a friendly and familiar “Hello World” response when invoked.  

1. Create a namespace for the `hello-helidon` application:

   ```console
   kubectl create namespace hello-helidon
   ```

1. Add labels to identify the namespace as managed by Verrazzano and enabled for Istio:

   ```console
   kubectl label namespace hello-helidon verrazzano-managed=true istio-injection=enabled
   ```

1. Deploy the Verrazzano [component](https://verrazzano.io/docs/applications/#components):

   ```console
   kubectl apply -f https://raw.githubusercontent.com/verrazzano/verrazzano/master/examples/hello-helidon/hello-helidon-comp.yaml
   ```

1. Create the [Application Configuration](https://verrazzano.io/docs/applications/#application-configurations):

   ```console
   kubectl apply -f https://raw.githubusercontent.com/verrazzano/verrazzano/master/examples/hello-helidon/hello-helidon-app.yaml
   ```

1. You can now get the name of your pod:

   ```console
   $ kubectl get pods -n hello-helidon
   NAME                                        READY   STATUS    RESTARTS   AGEhello-helidon-deployment-54979d7d74-6c9nw   1/1     Running   0          2m18s
   ```

1. To check to see if the application is ready, run:

   ```console
   $ kubectl wait — timeout=300s — for=condition=Ready -n hello-helidon pod/hello-helidon-deployment-54979d7d74–6c9nw
   pod/hello-helidon-deployment-54979d7d74-6c9nw condition met
   ```

1. Look up the hostname of the load balancer:

   ```console
   $ HOST=$(kubectl get gateway hello-helidon-hello-helidon-appconf-gw \
       -n hello-helidon \
       -o jsonpath='{.spec.servers[0].hosts[0]}')
   ```

### Test the deployment

The moment of truth! You can then test the application by running:

```console
$ curl -sk \
    -X GET \
    "https://${HOST}/greet"
```

This should return you the following:

```console
{"message":"Hello World!"}
```

Success! You've deployed your first application in Verrazzano.  

## Observability

Now that we have our application running and accessible, we'll want to keep track of how its performing and have a look at its logs and metrics. In both cases, Verrazzano has you covered! Verrazano provides the ELK stack for logging and a combination of [Prometheus] and [Grafana] for metrics and performance monitoring.

### Grafana

On the main page of the Verrazzano console, you'll see a link to Grafana. The same combination of username and password you used for Verrazzano will work here to connect to Grafana.  

1. Once logged in, select **Home** and then the **Helidon Monitoring Dashboard**:

   {% imgx aligncenter assets/verrazzano-grafana.png 1024 557 Grafana %}

2. Similarly, access the **Kibana** dashboard and then select the **Visualize** icon in the left-hand menu.  
   You'll be prompted to create an index pattern.  
   1. Select *verrazzano** and then follow the wizard to add the index pattern.  
   2. Search for our example application, `hello-helidon`, and you should see the following:

      {% imgx aligncenter assets/verrazzano-kibana.png 1024 557 Kibana %}

From here, you can create your own visualizations and dashboards.

### Checking in on the Kubernetes cluster with Rancher

What if we want a peek at the Kubernetes cluster itself? Again, Verrazzano has your back.  

1. From the Verrazzano console, locate the link to **Rancher** and select it.  

   **username:**
   : The default username is: `admin`

   **password:**
   : To retrieve the password, run:

      ```console
      $ kubectl get secret \
          --namespace cattle-system rancher-admin-secret \
          -o jsonpath={.data.password} | base64 \
          --decode; echo
      ```

2. Once logged in, you'll land on the cluster page and see an **Explorer** button. Select it to view your Kubernetes cluster:

   {% imgx aligncenter assets/verrazzano-rancher.png 1024 557 Rancher %}

## What's next

Verrazzano packs in a nice set of capabilities that helps you with the operational side of Kubernetes. From monitoring to logging and security, there's a lot productivity that a Kubernetes or an application administrator can gain.

Hopefully, you've found this article helpful and piqued your interest in what Verrazzano has to offer. In the [next part](2-deploy-multi-cluster-verrazzano-oke.md) of this series, we'll begin exploring other features of Verrazzano, including multi-cluster deployment and network security.

For more information about development with Oracle products:

- [Oracle Developers Portal](https://developer.oracle.com/)
- [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
