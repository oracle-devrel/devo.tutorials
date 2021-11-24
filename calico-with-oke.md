---
title: Installing and using Calico on Oracle Container Engine (OKE)
parent: [tutorials]
tags: [oke, devops]
categories: [cloudapps, opensource]
thumbnail: assets/calico-on-oracle-graph.png
date: 2021-11-24 13:16
description: Ali walks you through configuring OKE with Calico, an open-source networking tool for Kubernetes.
author: ali-mukadam
---
There are many [cluster networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model) options for Kubernetes. Two of the most popular are:

 * [Flannel](https://github.com/flannel-io/flannel)
 * [Calico](https://www.tigera.io/project-calico/)

{% imgx assets/calico-on-oracle-graph.png  "Graph: Software-Defined Networking Ideas with Kubernetes" %}

Flannel is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes. It is also used by default by [Oracle Container Services for use with Kubernetes](https://docs.oracle.com/en/operating-systems/oracle-linux/kubernetes/) (aka Kubernetes on Oracle Linux) and by Oracle Container Engine (OKE).

Calico provides both a layer 3 networking and a network policy engine. Its policy engine can also be used together with Flannel.

In this post, we'll deploy Calico for network pod policy.

## Manually installing Calico

If you have manually created the OKE Cluster using the cli or the Oracle Cloud Infrastructure (OCI) console, [obtain the kubeconfig file](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm) and setup your `KUBECONFIG` environment variable:

```console
export KUBECONFIG=/path/to/kubeconfig
```

Download the Calico policy-only manifest for the Kubernetes API datastore:

```console
curl \
https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/policy-only/1.7/calico.yaml \
-O
```

By default, the pod CIDR block on OKE is `10.244.0.0/16`. Set this as an environment variable:

```console
export POD_CID="10.244.0.0/16"
```

Then replace the default pod CIDR block value (`192.168.0.0/16`) in the calico.yaml. You can skip this step if your pod CIDR block is `192.168.0.0/16`.

```console
sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" calico.yaml
```

If your cluster consists of more than 50 worker nodes, then you need to do one additional step:

```console
sed -i -e 's/typha_service_name:\s"none"/typha_service_name: calico-typha/g' calico.yaml
```

Apply the manifest:

```console
kubectl apply -f calico.yaml
```

Calico also recommends a minimum of 3 replicas in production environment and 1 replica per every 200 nodes:

```console
kubectl -n kube-system scale --current-replicas=1 --replicas=3 deployment/calico-typha
```

The installation steps and other recommendations can be viewed on the [Calico website](https://docs.projectcalico.org/getting-started/kubernetes/).

## Installing Calico when provisioning with terraform-oci-oke module

If you are provisioning your cluster with the terraform-oci-oke module, there is an option to automate its installation. Set the following variables in your terraform.tfvars file

```console
create_bastion = "true"
install_calico = "true"
```

Run Terraform apply again:

```console
terraform apply -auto-approve
```

The Calico installation script in terraform-oci-oke also handles the cases when you have more than 50 nodes in your cluster and and the number of replicas needed are calculated and scaled to accordingly.

## Testing Calico

If you want to test Calico as a network pod policy engine, there are some [very excellent recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes). You should be able to take them all for a spin.

Alternatively, you can also try the [tutorials](https://docs.projectcalico.org/security/) on the Calico website.
