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
redirect_from: "/collections/tutorials/deploying-the-argo-project-on-oke/"
---
{% imgx alignright assets/verrazzano-logo.png 400 400 "Verrazzano Logo" %}

Oracle recently released [Verrazzano](https://verrazzano.io/), an "end-to-end container platform to deploy cloud native and traditional applications in multi-cloud and hybrid environments." If that’s a lot to take in, it’s because Verrazzano, (v8o for short) packs a lot. In this post, we will explore deploying Verrazzano on [OKE (Oracle Container Engine)](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm#top).

The single cluster deployment model is easy:

- Create a Kubernetes cluster
- Install the Verrazzano platform operator
- Install Verrazzano

After this, you can deploy your application of choice.

## Creating the OKE cluster

We will start by creating the OKE cluster using [Terraform OKE module](https://github.com/oracle-terraform-modules/terraform-oci-oke). Since we are only taking Verrazzano for a spin, we only need the bare minimum features. Follow the [quickstart](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/main/docs/quickstart.adoc) guide, create the providers and create a copy of the terraform.tfvars.example and rename the copy to terraform.tfvars. Ensure the following features/resources are enabled/created:

```terraform
create_bastion_host = true
bastion_access = ["anywhere"]
create_operator                    = true
enable_operator_instance_principal = true
node_pools = {
  np1 = { shape = "VM.Standard.E4.Flex", ocpus = 2, memory = 32, node_pool_size = 2, boot_volume_size = 150}
}
```

Follow the rest of the quickstart to run terraform init and apply.

Once the cluster is created, use the convenient output to copy the command to ssh to the operator host:

```console
ssh_to_operator = "ssh -i ~/.ssh/id_rsa -J opc@xyz.xyz.xyz.xyz opc@10.0.0.12"
```

From here onwards, all kubectl commands are executed on the operator host.

## Installing the Verrazzano operator

Let’s first install the Verrazzano operator:

```console
$ kubectl apply -f https://github.com/verrazzano/verrazzano/releases/download/v1.0.1/operator.yaml
```

and wait for the deployment to complete:

```console
$ kubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
Waiting for deployment "verrazzano-platform-operator" rollout to finish: 0 of 1 updated replicas are available...
```

Give it a couple of minutes and the operator should have deployed by then. Verify that the operator is running:

```console
$ kubectl -n verrazzano-install get pods
NAME                                            READY   STATUS    RESTARTS   AGE
verrazzano-platform-operator-5f788568fd-w8cz7   1/1     Running   0          80s
```

## Installing Verrazzano

We can now install Verrazzano. We will use the dev profile for this exercise:

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

We need to wait for Verrazzano to install:

```console
$ kubectl wait \
    --timeout=20m \
    --for=condition=InstallComplete \
    verrazzano/
```

## Accessing Verrazzano

In order to access Verrazzano, you need to get the console URL:

<!--EDIT-->

```console
$ kubectl get vz -o yaml
```

You will get a list of URLs printed. For example, my Verrazzano console URL is `https://verrazzano.default.168.138.102.88.nip.io`.

Access this url in your browser and you will be prompted to login:

{% imgx aligncenter assets/verrazzano-login.png 1024 557 Verrazzano Login Screen %}

The username is `verrazzano` and you can obtain the password by issuing the following command:

```console
kubectl get secret \
    --namespace verrazzano-system verrazzano \
    -o jsonpath={.data.password} | base64 \
    --decode; echo
```

You should now be able to access the Verrazzano console:

{% imgx aligncenter assets/verrazzano-console.png 1024 557 Verrazzano Console %}

### Deploy an application to Verrazzano

We will deploy the hello-helidon application. First, create a namespace:

```console
kubectl create namespace hello-helidon
```

and add labels to identify the namespace as managed by Verrazzano and enabled for Istio:

```console
kubectl label namespace hello-helidon verrazzano-managed=true istio-injection=enabled
```

Next, deploy the Verrazzano [component](https://verrazzano.io/docs/applications/#components):

```console
kubectl apply -f https://raw.githubusercontent.com/verrazzano/verrazzano/master/examples/hello-helidon/hello-helidon-comp.yaml
```

Then create the [Application Configuration](https://verrazzano.io/docs/applications/#application-configurations):

```console
kubectl apply -f https://raw.githubusercontent.com/verrazzano/verrazzano/master/examples/hello-helidon/hello-helidon-app.yaml
```
You can now get the name of your pod:

```bash
$ kubectl get pods -n hello-helidon
NAME                                        READY   STATUS    RESTARTS   AGEhello-helidon-deployment-54979d7d74-6c9nw   1/1     Running   0          2m18s
```

And check if the application is ready:

```bash
$ kubectl wait — timeout=300s — for=condition=Ready -n hello-helidon pod/hello-helidon-deployment-54979d7d74–6c9nw
pod/hello-helidon-deployment-54979d7d74-6c9nw condition met
```

Lookup the hostname of the load balancer:

```bash
HOST=$(kubectl get gateway hello-helidon-hello-helidon-appconf-gw \
    -n hello-helidon \
    -o jsonpath='{.spec.servers[0].hosts[0]}')
```   

You can then test the application:

```bash
$ curl -sk \
    -X GET \
    "https://${HOST}/greet"
```

This should return you the following:

```bash
{"message":"Hello World!"}
```

## Observability

Now, that we’ve got our application running and accessible, we want to also look at its logs and metrics. Verrazzano has got you covered in the form of the ELK stack for logging and the combination of Prometheus and Grafana for metrics and performance monitoring.

Let’s look at Grafana first. On the main page of the Verrazzano console, you will see a link to Grafana. You can use the same combination of username and password you used to log into Grafana. Once logged in, click on "Home" and select the "Helidon Monitoring Dashboard":

{% imgx aligncenter assets/verrazzano-grafana.png 1024 557 Grafana %}


Similarly, access the Kibana dashboard and click on Visualize icon in the left menu. You will be prompted to create an index pattern. Select the verrazzano* and follow the wizard to add the index pattern. Search for hello-helidon and you should be able to see the following:

{% imgx aligncenter assets/verrazzano-kibana.png 1024 557 Kibana %}

From here, you can create your own visualizations and dashboards.

What if we want to peek at the Kubernetes cluster itself? Again, Verrazzano has got you covered. From the Verrazzano console, locate the link to Rancher and click on it. The default username is "admin" and you can retrieve the password as follows:

```console
kubectl get secret \
    --namespace cattle-system rancher-admin-secret \
    -o jsonpath={.data.password} | base64 \
    --decode; echo
```    

Once logged in, you will land on the cluster page and you will see an Explorer button. Click on it and you will be able to view your Kubernetes cluster:

{% imgx aligncenter assets/verrazzano-rancher.png 1024 557 Rancher %}

## Summary

Verrazzano packs a nice set of capabilities that helps you with the operational side of of Kubernetes. From monitoring to logging and security, there is a lot productivity that a Kubernetes or an application administrator can gain.

I hope you find this article helpful. In future, we will explore other features of Verrazzano, including multi-cluster deployment and network security among others.
