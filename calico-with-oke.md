---
title: Installing and using Calico on Oracle Container Engine (OKE)
parent:
- tutorials
tags:
- oke
- devops
categories:
- cloudapps
- opensource
thumbnail: assets/calico-on-oracle-graph.png
date: 2021-11-24 13:16
description: Ali walks you through configuring OKE with Calico, an open-source networking
  tool for Kubernetes.
author: ali-mukadam
mrm: WWMK211125P00010
xredirect: https://developer.oracle.com/tutorials/calico-with-oke/
---

## Introduction

There are many [cluster networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model) options for Kubernetes. Two of the most popular are: [Flannel](https://github.com/flannel-io/flannel) and [Calico](https://www.tigera.io/project-calico/).

Flannel is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes. It is also used by default by [Oracle Container Services for use with Kubernetes](https://docs.oracle.com/en/operating-systems/oracle-linux/kubernetes/) (aka Kubernetes on Oracle Linux) and by Oracle Container Engine (OKE).

Calico provides both a layer 3 networking and a network policy engine. Its policy engine can also be used together with Flannel.

## What we'll cover

This tutorial will focus on Calico. In this tutorial, you'll install Calico for network pod policy on your OKE Cluster. You will then test your new installation.

For additional information, see:

- [Creating a Kubernetes Cluster using Terraform](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-cluster/01-summary.htm)

- [Terraform execution environment](https://docs.oracle.com/en/solutions/multi-tenant-topology-using-terraform/configure-terraform-execution-environment1.html#GUID-17AE60F0-FB45-4028-8BF5-71E149AA6C21)

- [Additional resources for getting started with Kubernetes](https://projectcalico.docs.tigera.io/getting-started/kubernetes/)  

## Before You Begin

To successfully complete this tutorial, you must have the following:

### Requirements

- An Oracle Cloud Infrastructure account (required for use with Terraform).
See [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm).
  
- A MacOS, Linux, or Windows computer with `ssh` support installed.

## Installing Calico

There are two routes available to you depending on how you've created your OKE cluster. If you've used Terraform in the past, you can follow the section on [installing with Terraform](#installing-calico-when-provisioning-with-terraform) below. Or, if you've previously used the cli or the Oracle Cloud Infrastructure (OCI) console, you can continue with the section on [manual installation](#manually-installing-calico).

### Installing Calico when provisioning with Terraform

If you're provisioning your cluster with the terraform-oci-oke module, there is an option to automate its installation.

The Calico installation script in terraform-oci-oke also handles the cases when you have more than 50 nodes in your cluster and and the number of replicas needed are calculated and scaled to accordingly.

To install Calico using Terraform:

1. Set the following variables in your `terraform.tfvars` file:

   ```console
   create_bastion = "true"
   install_calico = "true"
   ```

1. Run `terraform apply`:

   ```console
   terraform apply -auto-approve
   ```

Calico is now installed. Next, [test your Calico installation](#testing-calico).

### Manually installing Calico

If you've manually created the OKE Cluster using the cli or the Oracle Cloud Infrastructure (OCI) console, you can use the following procedure:

1. [Obtain the kubeconfig file](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm).  

2. Set up your `KUBECONFIG` environment variable:

   ```console
   export KUBECONFIG=/path/to/kubeconfig
   ```

3. Download the Calico policy-only manifest for the Kubernetes API datastore:

   ```console
   curl \
   https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/policy-only/1.7/calico.yaml \
   -O
   ```

4. Set a POD_CID environment varible. By default, the pod CIDR block on OKE is `10.244.0.0/16`. To set this as an environment variable, use:

   ```console
   export POD_CID="10.244.0.0/16"
   ```

5. Replace the default pod CIDR block value (`192.168.0.0/16`) in the `calico.yaml` file.  
   You can skip this step if your pod CIDR block is already set to `192.168.0.0/16`.

   ```console
   sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" calico.yaml
   ```

6. **[ OKE cluster with more than 50 worker nodes only ]** If your cluster consists of more than 50 worker nodes, then you need to do one additional step:

   ```console
   sed -i -e 's/typha_service_name:\s"none"/typha_service_name: calico-typha/g' calico.yaml
   ```

7. Apply the manifest:

   ```console
   kubectl apply -f calico.yaml
   ```

8. **[ Recommended ]** Calico also recommends a minimum of 3 replicas in production environment and 1 replica per every 200 nodes:

   ```console
   kubectl -n kube-system scale --current-replicas=1 --replicas=3 deployment/calico-typha
   ```

   The installation steps and other recommendations can be viewed on the [Calico website](https://docs.projectcalico.org/getting-started/kubernetes/).

## Testing Calico

If you want to dive right in and test Calico as a network pod policy engine, there are some [excellent recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes) ready and available for you. You should be able to take any of these for a spin.

Alternatively, if you'd prefer a more directed approach, you can always try the [security tutorials](https://docs.projectcalico.org/security/) on the Calico website.

## What's next  

Congratulations! You've successfully installed Calico on your OKE Cluster.

To explore more information about development with Oracle products:

- [Oracle Developers Portal](https://developer.oracle.com/)

- [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
