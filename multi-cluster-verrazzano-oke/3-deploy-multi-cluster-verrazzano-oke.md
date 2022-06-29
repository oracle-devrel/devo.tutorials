---
title: Deploying A Multi-Cluster Verrazzano On Oracle Container Engine for Kubernetes
  (OKE) Part 2
parent:
- tutorials
- multi-cluster-verrazzano-oke
tags:
- open-source
- oke
- kubernetes
- verrazzano
- terraform
- devops
categories:
- cloudapps
- opensource
thumbnail: assets/verrazzano-logo.png
date: 2021-12-03 09:11
description: How to deploy Verrazzano an OKE cluster.
color: purple
mrm: WWMK211123P00031
author: ali-mukadam
xredirect: https://developer.oracle.com/tutorials/multi-cluster-verrazzano-oke/3-deploy-multi-cluster-verrazzano-oke/
slug: 3-deploy-multi-cluster-verrazzano-oke
---
{% imgx alignright assets/verrazzano-logo.png 400 400 "Verrazzano Logo" %}

In [Part 1](2-deploy-multi-cluster-verrazzano-oke), we discussed setting up the network infrastructure for a multi-cluster [Verrazzano](https://verrazzano.io/) deployment. Earlier, we focused on deploying Verrazzano on [Oracle Container Engine (OKE)](1-deploying-verrazzano-on-oke). In this article, we will configure the clusters so they behave as a kind of global cluster. Below is the multi-clustering process depicted graphically:

{% imgx aligncenter assets/vNjGKLaGatczobm2O5Ycdw.png 1076 630 "Verrazzano multi-cluster deployment and registration process" "Verrazzano multi-cluster deployment and registration process" %}

## Prerequisites

To successfully complete this tutorial, you will need to have:

- An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }})
- A MacOS, Linux, or Windows computer with `ssh` support installed
- Git
- [Terraform 1.0.0] or later
- Completed [section 2] of the series

## Getting started

First, a little refresher.

- Recall that a Verrazzano multi-cluster has:  

  - 1 Admin cluster, *and*
  - 1 or more managed clusters

- Where *each* Verrazzano cluster is also a Kubernetes cluster:

  {% imgx aligncenter assets/5i_215fK15AiaYSz.png 535 413 "Verrazzano multi-cluster architecture" "Verrazzano multi-cluster architecture" %}

- Also, remember we have the following setup:  

  {% imgx aligncenter assets/bF77x66gHN42zsW_2_9Dxw.png 695 554 "Remote peering with different regions" "Remote peering with different regions using star architecture for managed clusters" %}

- And that we chose the Admin server to be in the Singapore OCI region.

Next, We'll install Verrazzano with the *dev/prod* profile on the Admin cluster and with *managed-cluster* profile on the managed clusters.

### Quick note on using `kubectx`

In the commands below, we'll use `kubectx` to set the Kubernetes context such that a context is equivalent to a Kubernetes cluster. Strictly speaking, that’s not really true, but it does serve our purposes here.  

In our example, since we have 1 Admin server and 3 managed servers in 4 different regions, we have *4 different contexts*:

{% imgx aligncenter assets/8IaaB1P-hc9P6vjffKZaDA.png 700 121 "Verifying your Kubernetes context" "Verifying your Kubernetes context" %}

To ensure we're always using the correct context, we execute the `kubectx <context-name>` before every command.

## Installing Verrazzano as Admin

Installing Verrazzano as the Admin cluster is straightforward, just follow the steps in the [quickstart guide](https://verrazzano.io/docs/quickstart/). During the set up process you can choose between the dev/prod profile.  

### First things first

Before you start, make sure that your context is pointing to “admin” on the operator host:  

{% imgx aligncenter assets/8IaaB1P-hc9P6vjffKZaDA.png 700 121 "Verifying your Kubernetes context" "Verifying your Kubernetes context" %}

If it’s pointing to one of the other clusters, change it as follows:  

```console
kubectx admin
```

### Install Verrazzanno

1. Begin the deployment:  

      ```console
      kubectl apply -f https://github.com/verrazzano/verrazzano/releases/download/v1.0.3/operator.yaml
      ```

1. Wait for the deployment to finish:  

      ```console
      kubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
      ```

1. Confirm that the operator pods are working correctly:

      ```console  
      kubectl -n verrazzano-install get pods
      NAME                                            READY   STATUS    RESTARTS   AGE
      verrazzano-platform-operator-54cf56884f-46zzk   1/1     Running   0          91s
      ```

1. Install Verrazzano:  

      ```console
      kubectl apply -f - <<EOF  
      apiVersion: install.verrazzano.io/v1alpha1  
      kind: Verrazzano  
      metadata:  
          name: admin  
      spec:  
          profile: dev  
      EOF
      ```

1. Wait until the installation is complete:  

      ```console
      kubectl wait \  
          --timeout=20m \  
          --for=condition=InstallComplete \  
          verrazzano/admin
      ```

   This will take a while. In the meantime, let’s install Verrazzano on the managed clusters.  

## Installing Verrazzano on managed clusters

1. Change the context to one of the managed clusters and install the operator again:  

      ```console
      kubectx sydney kubectl apply -f https://github.com/verrazzano/verrazzano/releases/download/v1.0.3/operator.yamlkubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
      ```

1. Repeat the previous command for each of the remaining managed clusters.  
   >**NOTE:** Before running in each managed cluster, ensure that you've changed your context with kubectx `<contextname>` as noted above.  
   {:.alert}

1. Using the same procedure as the Admin region, verify that the Verrazzano operator has been successfully installed.  

1. Using the managed profile, install Verrazzano for each cluster  by changing the context and name accordingly:  

      ```yaml
      apiVersion: install.verrazzano.io/v1alpha1  
      kind: Verrazzano  
      metadata:  
          name: sydney  
      spec:  
          profile: managed-cluster
      ```

## Verifying the Admin cluster and managed clusters

While the managed clusters are being installed, let’s see if we can [access the various consoles](https://verrazzano.io/docs/operations/). First, make sure that you can log in into the Verrazzano and Rancher consoles.  

1. Change the context again and verify:  

      ```console
      kubectx sydney kubectl wait \  
          --timeout=20m \  
          --for=condition=InstallComplete \  
          verrazzano/sydney
      ```

1. Repeat the verification for each managed cluster.

## Registering the managed clusters

1. Verify the the CA certificate type for each managed cluster:

      ```console
      kubectx sydney kubectl -n verrazzano-system get secret system-tls -o jsonpath='{.data.ca\.crt}'
      ```

   If this value is empty, it's actually a good thing. This means that your managed cluster is using certificates signed by a well-known certificate authority and you can generate a secret containing the CA certificate in YAML format. If it’s *not* empty, then the certificate is self-signed and needs to be extracted. Refer to the workflow at the beginning of this article.  

      ```console
      kubectx sydney

      CA_CERT=$(kubectl \  
          get secret system-tls \  
          -n verrazzano-system \  
          -o jsonpath="{.data.ca\.crt}" | base64 --decode)

      kubectl create secret generic "ca-secret-sydney" \  
        -n verrazzano-mc \  
        --from-literal=cacrt="$CA_CERT" \  
        --dry-run=client -o yaml > managedsydney.yaml
      ```

1. Repeat the above for the 2 other regions, replacing the *region/context* and *filenames* accordingly.

1. Create 3 secrets on the Admin cluster that contains the CA certificate for each managed cluster:  

      ```console
      kubectx adminkubectl apply -f managedsydney.yaml  
      kubectl apply -f managedmumbai.yaml  
      kubectl apply -f managedtokyo.yaml
      ```

1. Get the *cluster name* for the Admin Cluster:  

      ```console
      kubectl config get contexts
      ```

   {% imgx aligncenter assets/AHjsVsuj0gcjB0RNKCNVIQ.png 700 132 "Cluster names" "Cluster names" %}

1. Get the *API Server address* for the Admin server:  

      ```console
      kubectx adminexport CLUSTER_NAME="cluster-cillzxw34tq"API_SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
      ```

1. Create a *ConfigMap* that contains the Admin cluster’s API server address:  

      ```console
      kubectx adminkubectl apply -f <<EOF -  
      apiVersion: v1  
      kind: ConfigMap  
      metadata:  
        name: verrazzano-admin-cluster  
        namespace: verrazzano-mc  
      data:  
        server: "${API_SERVER}"  
      EOF
      ```

1. Create the `VerrazzanoManagedCluster` object for each managed cluster:  

      ```console  
      kubectx admin  
      kubectl apply -f <<EOF -  
      apiVersion: clusters.verrazzano.io/v1alpha1  
      kind: VerrazzanoManagedCluster  
      metadata:  
        name: sydney  
        namespace: verrazzano-mc  
      spec:  
        description: "Sydney VerrazzanoManagedCluster object"  
        caSecret: ca-secret-sydney  
      EOFkubectl apply -f <<EOF -  
      apiVersion: clusters.verrazzano.io/v1alpha1  
      kind: VerrazzanoManagedCluster  
      metadata:  
        name: mumbai  
        namespace: verrazzano-mc  
      spec:  
        description: "Mumbai VerrazzanoManagedCluster object"  
        caSecret: ca-secret-mumbai  
      EOFkubectl apply -f <<EOF -  
      apiVersion: clusters.verrazzano.io/v1alpha1  
      kind: VerrazzanoManagedCluster  
      metadata:  
        name: tokyo  
        namespace: verrazzano-mc  
      spec:  
        description: "Tokyo VerrazzanoManagedCluster object"  
        caSecret: ca-secret-tokyo  
      EOF
      ```

1. Wait for the *VerrazzanoManagedCluster* resource to reach the Ready status:  

      ```console
      kubectx adminkubectl wait --for=condition=Ready \  
          vmc sydney -n verrazzano-mckubectl wait --for=condition=Ready \  
          vmc sydney -n verrazzano-mckubectl wait --for=condition=Ready \  
          vmc sydney -n verrazzano-mc
      ```

1. Export a YAML file created to register the managed cluster:  

      ```console
      kubectx adminkubectl get secret verrazzano-cluster-sydney-manifest \  
          -n verrazzano-mc \  
          -o jsonpath={.data.yaml} | base64 --decode > registersydney.yamlkubectl get secret verrazzano-cluster-mumbai-manifest \  
          -n verrazzano-mc \  
          -o jsonpath={.data.yaml} | base64 --decode > registermumbai.yamlkubectl get secret verrazzano-cluster-tokyo-manifest \  
          -n verrazzano-mc \  
          -o jsonpath={.data.yaml} | base64 --decode > registertokyo.yaml
      ```

1. On each managed cluster, apply the registration file:  

      ```console
      kubectx sydney  
      kubectl apply -f registersydney.yamlkubectx mumbai  
      kubectl apply -f registermumbai.yamlkubectx tokyo  
      kubectl apply -f registertokyo.yaml
      ```

1. Verify whether the registration completed successfully:  

      ```console
      kubectx admin  
      kubectl get vmc sydney -n verrazzano-mc -o yaml  
      kubectl get vmc mumbai -n verrazzano-mc -o yaml  
      kubectl get vmc tokyo -n verrazzano-mc -o yaml
      ```

## Additional verifications

### Verrazzano console

Navigate to the Verrazzano console and log in. You should be able to see all 3 clusters:  

{% imgx aligncenter assets/oMn_S0wntkkEmuuPf-3JBw.png 700 403 "Managed clusters in Verrazzano" "Managed clusters in Verrazzano" %}

### Rancher console

Similarly, on the Rancher console, you should be able to see all 4 clusters:  

{% imgx aligncenter assets/v3E0CZxe1nF3Ni80qCB7tg.png 700 173 "Admin and managed clusters in Rancher" "Admin and managed clusters in Rancher" %}

>**NOTE:** "local" is the Admin cluster whereas the others are the managed clusters.
{:.notice}

## Conclusion

This concludes the exercise of connecting OKE clusters deployed in different regions into a multi-cluster Verrazzano deployment. Keep in mind that in this series we never configured things like DNS, Certificates, or the Ingress Controller. Our goal was just to get the multi-cluster configuration going. In a future article, we'll come back to this topic and look at those other things as well.

To explore more information about development with Oracle products:

- [Oracle Developers Portal](https://developer.oracle.com/)
- [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

<!-- Articles -->

[section 2]: 2-deploy-multi-cluster-verrazzano-oke.md
