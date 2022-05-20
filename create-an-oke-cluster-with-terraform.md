---
title: One does not simply deploy Kubernetes to the cloud
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
thumbnail:
date: 2021-09-22 15:30
description: How to create an OKE cluster with Terraform
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
{% imgx alignright assets/create-oke-1.png 400 400 "Boromir" %}


Creating an Oracle Container Engine (OKE) cluster manually can be a time consuming task. At a minimum, you need to create the following:

- A VCN, an Internet Gateway, a NAT gateway if you want to a private worker node deployment
- Worker subnets with security list and a set of security rules or NSGs (Network Security Groups). These rules will vary depending on whether your worker nodes are public or private.
- Load balancer subnets with security list and a set of security rules or NSGs (Network Security Groups). Similar to the worker nodes, these rules will vary depending on whether your load balancers are public or private.

All of this is very well documented [here](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm).

Assuming you have done everything correctly, you can now create a cluster and node pools.

If you need a cluster quickly, say for an experiment or a demo, you can also use the Quick Create option in the OCI console. But for real implementation, it is better to use Infrastructure as Code and Terraform (or similar) to provision the clusters. For a more in-depth tutorial on Terraform with OCI, please refer to the [Terraform series] (https://cool.devo.build/tutorials/tf-101/).

## Introducing terraform-oci-oke
We recently released v4.0 of the [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke) project. The project is a reusable Terraform module that you can use to provision an entire cluster. It will create the following:

- Basic networking requirements such as VCN, gateways, route tables, subnets, security lists, NSGs
- An optional bastion host that you can use to access private computes
- An optional operator host that you can use to perform deployment or other admin duties
- Support for mixed workloads variable and configurable number and shapes of worker node pools
- Quite a few extras such as ServiceAccount for the purpose of CI/CD, Secrets for using OCIR, encryption of the etcd and enforcement of signed images among many others

Let’s take it for a spin. Below is an example of what you can create with the terraform-oci-oke scripts.

{% imgx alignright assets/create-oke-2.png 400 400 "OKE Cluster with Bastion, Operator and 1 node pool" %}

I’ll be assuming that you have 

- already configured your OCI account to use Terraform such as creating private keys etc.
- created the necessary policy and access rights to create an OKE cluster. If not, follow [these instructions](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/main/docs/prerequisites.adoc) first.

1. First, clone the repo:

```
git clone https://github.com/oracle-terraform-modules/terraform-oci-oke.git tfoke
cd tfoke
``

2. Copy the terraform.tfvars.example to terraform.tfvars and edit the terraform.tfvars:

```
cp terraform.tfvars.example terraform.tfvars
```

3. Enter the following information in the terraform.tfvars file:

- api_fingerprint
- api_private_key_path
- home_region (this is your tenancy's home region)
- region (this is the OCI region where you want to create the OKE cluster)
- tenancy_id
- user_id
- compartment_id
- ssh_private_key_path
- ssh_public_key_path

4. Create 2 providers:

```
provider "oci" {
  fingerprint      = var.api_fingerprint
  private_key_path = var.api_private_key_path
  region           = var.region
  tenancy_ocid     = var.tenancy_id
  user_ocid        = var.user_id
}

provider "oci" {
  fingerprint      = var.api_fingerprint
  private_key_path = var.api_private_key_path
  region           = var.home_region
  tenancy_ocid     = var.tenancy_id
  user_ocid        = var.user_id
  alias            = "home"
}
```

Note that all the terraform options are fully documented [here](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/main/docs/terraformoptions.adoc).

5. You can now run terraform plan and apply:

```
terraform plan
terraform apply -auto-approve
```

6. By default, a cluster of with 2 nodepools consisting of 1 worker node each will be created for you unless you changed the ```node_pools``` parameter.

7. When Terraform has completed, it will print the following for you:

```
bastion_public_ips = xyz.xyz.xyz.xyz
kubeconfig = export KUBECONFIG=generated/kubeconfig
ocirtoken = sensitive
ssh_to_bastion = "ssh -i ~/.ssh/id_rsa opc@xyz.xyz.xyz.xyz"
ssh_to_operator = "ssh -i ~/.ssh/id_rsa -J opc@xyz.xyz.xyz.xyz opc@abc.abc.abc.abc"
```

The kubeconfig file will also be created under the generated directory so you can just set your KUBECONFIG environment variable and start using kubectl:

```
export KUBECONFIG=generated/kubeconfig
```
And verify that you can interact with the cluster:

```
kubectl get nodes
NAME        STATUS   ROLES   AGE   VERSION                                                                                                                                  
10.0.13.2   Ready    node    20h   v1.20.11                                                                                                                                  
10.0.23.2   Ready    node    20h   v1.20.11                                                                                                                                  
```

## Using the operator host
The operator host is pre-installed with oci-cli, kubectl and helm as well as helpful aliases ('k' and 'h' for kubectl and helm respectively). Just login and start interacting with your cluster:

```
ssh -i ~/.ssh/id_rsa -J opc@xyz.xyz.xyz.xyz opc@abc.abc.abc.abc
```

Use kubectl:

```
kubectl get nodes
NAME        STATUS   ROLES   AGE   VERSION                                                                                                                                  
10.0.13.2   Ready    node    20h   v1.20.11                                                                                                                                  
10.0.23.2   Ready    node    20h   v1.20.11                                                                                                                                  
```

You can turn on/off the bastion and operator hosts anytime without any impact on the OKE cluster.

There are plenty of other features that we have added to the project to make the life of an OCI and Kubernetes administrator more enjoyable. Please take the time to explore them. 

If you have an idea, we would love to hear from you. Send us an issue or a pull request.