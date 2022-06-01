---
title: Deploying A Multi-Cluster Verrazzano On Oracle Container Engine for Kubernetes
  (OKE) Part 1
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
xredirect: https://developer.oracle.com/tutorials/multi-cluster-verrazzano-oke/2-deploy-multi-cluster-verrazzano-oke/
---
{% imgx alignright assets/verrazzano-logo.png 400 400 "Verrazzano Logo" %}

In the [previous article](1-deploying-verrazzano-on-oke), we were introduced to Verrazzano and took it for a quick spin on an Oracle Container Engine for Kubernetes (OKE). As promised, in this article, we're going to deploy a multi-cluster Verrazzano on OKE. And just to make things a little more interesting, we'll also do that using different Oracle Cloud Infrastructure (OCI) regions.

But first, we'll make a small digression into WebLogic and Kubernetes to set the stage for how we'll be handling this in each of the next two tutorials.

Key topics covered in this tutorial:  

* An introduction to WebLogic and Kubernetes
* A discussion about infrastructure
* Creating Verrazzano clusters

For additional information, see:  

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)
* [Getting started with Terraform](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformgettingstarted.htm)

## Getting started

### From WebLogic to Kubernetes to Verrazzano

To better frame our understanding of what Kubernetes is and how it fits in with Verrazzano, let's take a step back and apply some simple analogies to its components.

A good touchstone for us is the WebLogic space, and we can draw from a lot of familiar concepts to help with our understanding here.  

{% imgx aligncenter assets/SumRnmK8ZrOCVzWwaAETC3Q.png 1200 401 "WebLogic and Kubernetes analogy" "WebLogic and Kubernetes analogy" %}

In WebLogic, a cluster consists of an Admin Server and a group of Managed Servers. In this set up, the Admin Server handles the administration, deployment, and other less silky but nevertheless important tasks, while Managed Servers are utilized for deploying and running the applications, as well as responding to requests.  This allows you to run your applications either across your entire cluster or on specific Managed Servers.  

> **NOTE:** You could always run your applications on the single Admin Server (in a way that's somewhat equivalent to [taints and tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) of the master nodes), but it's not recommended.
{:.alert}

Under this set up, if your application is deployed to the cluster and a Managed Server in the cluster fails (JVM, host, reboot, etc.), other Managed Servers in the cluster will automatically handle the job.  

But, what if the Managed Server where your singleton service is running fails? WebLogic has you covered with Automatic Service Migration (ASM). For a more detailed read on ASM, check out the [WebLogic ASM guide](https://www.oracle.com/technetwork/middleware/weblogic/weblogic-automatic-service-migratio-133948.pdf).  

Now that we have a better sense of the basic cluster infrastructure, let's start connecting this back to Kubernetes. What's the best equivalent in Kubernetes? Essentially, ASM is a bit like a `ReplicaSet`. Initially, applications on Kubernetes were stateless until the addition of StatefulSets, but now you can also run stateful applications across the entire cluster.  

### Geographically distributed clusters

What if, for the purpose of high availability, you needed to run your Kubernetes applications in geographically distributed clusters. You could try your luck with [kubefed](https://github.com/kubernetes-sigs/kubefed), although it's currently still in beta and has admittedly been experiencing some growing pains. Or, you could try deploying the same applications to different clusters, implement a kind of global health check, and then use an [intelligent load balancer](https://docs.oracle.com/en-us/iaas/Content/TrafficManagement/Concepts/overview.htm) to switch the traffic from one cluster to another. All these approaches are valid, but still fairly limited, error-prone, and risky.  

Enter Verrazzano multi-clustering.  

How did Verrazzano make our lives a whole lot better? It took the concept of Admin and Managed Servers in WebLogic and applied it to Kubernetes clusters:  

{% imgx aligncenter assets/5i_215fK15AiaYSz.png 535 413 "Verrazzano multi-cluster" "Verrazzano multi-cluster" %}

Where you previously had a single Admin Server for WebLogic, you now have a single Admin *cluster* based on Kubernetes for Verrazzano. And where your applications were deployed on managed servers, your Verrazzano workloads are deployed on managed Kubernetes clusters, possibly closer to your users.

### Infrastructure Planning

In order to achieve this, Verrazzano-managed clusters (i.e., Kubernetes clusters administered and managed by the Verrazzano container platform) need to be able to communicate with the Verrazzano Admin cluster and vice-versa. In WebLogic, the Managed Servers would usually be part of the same network (unless you were using [stretch clusters](https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/wlcag/active-active-stretch-cluster-active-passive-database-tier.html#GUID-66D13F44-200A-45AB-9676-2BF18610554D)) and this administration would be fairly straightforward.  

Our ultimate goal though, is to deploy the different Verrazzano clusters in different cloud regions on OCI, so we need to start thinking about our plan for networking and security.  

> **NOTE:**  You can also use Verrazzano to manage clusters deployed in other clouds or on-premises, but the networking and security configurations would vary (VPN/FastConnect etc).
{:.alert}

Below is a map of OCI regions to help us pick a set of regions:  

{% imgx aligncenter assets/syLSX57E1bT7_EzYZU_qLGg.png 1200 508 "Map of OCI regions" "Map of OCI regions" %}

We'll use our newly-minted Singapore region for the Admin cluster and then Mumbai, Tokyo, and Sydney as managed clusters in a star architecture:  

{% imgx aligncenter assets/rnXSnetqM6oAOJk6bfkyQ.png 671 549 "Verrazzano Clusters spread across OCI Asia Pacific regions" "Verrazzano Clusters spread across OCI Asia Pacific regions" %}

### Networking Infrastructure

{% imgx aligncenter assets/bF77x66gHN42zsW_2_9Dxw.png 695 554 "Remote Peering with different regions" "Remote Peering with different regions" %}

We need the clusters to communicate securely using the OCI Backbone, so this means we need to set up DRGs in each region, attach them to their respective VCNs, and then use remote peering. Since the VCNs and the clusters will eventually be connected, we also need to ensure that their respective IP address ranges (VCN, pod, and service) do not overlap.

## Creating the Verrazzano clusters

We're going to the use [terraform-oci-oke module](https://github.com/oracle-terraform-modules/terraform-oci-oke) to create our clusters. We could create them individually by cloning the module 4 times and then changing the region parameters, but there's now a much simpler way to do it. You'll be pleased to know that one of the things we improved in the 4.0 release of the module is *reusability*. We'll take advantage of this!

### Create a new Terraform project

1. **Create project**
   Let's create a new Terraform project and define our variables as follows:  

      ```JSON
      # Copyright 2017, 2021 Oracle Corporation and/or affiliates.  All rights reserved.
      # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

      # OCI Provider parameters
      variable "api_fingerprint" {
        default     = ""
        description = "Fingerprint of the API private key to use with OCI API."
        type        = string
      }

      variable "api_private_key_path" {
        default     = ""
        description = "The path to the OCI API private key."
        type        = string
      }

      variable "verrazzano_regions" {
        # List of regions: https://docs.cloud.oracle.com/iaas/Content/General/Concepts/regions.htm#ServiceAvailabilityAcrossRegions
        description = "A map Verrazzano regions."
        type        = map(string)
      }

      variable "tenancy_id" {
        description = "The tenancy id of the OCI Cloud Account in which to create the resources."
        type        = string
      }

      variable "user_id" {
        description = "The id of the user that terraform will use to create the resources."
        type        = string
        default     = ""
      }

      # General OCI parameters
      variable "compartment_id" {
        description = "The compartment id where to create all resources."
        type        = string
      }

      variable "label_prefix" {
        default     = "none"
        description = "A string that will be prepended to all resources."
        type        = string
      }
      ```

1. **Define regions**
   In `terraform.tfvars`, along with the identity parameters, let's define our regions:  

      ```JSON
      verrazzano_regions = {  
        home  = "your-tenancy-home-region" #replace with your tenancy's home region  
        admin = "ap-singapore-1"  
        syd   = "ap-sydney-1"  
        mum   = "ap-mumbai-1"  
        tok   = "ap-tokyo-1"  
      }
      ```

1. **Define providers**
   In `provider.tf`, let's define the providers for the different regions using aliases:  

      ```JSON
      provider "oci" {
        fingerprint      = var.api_fingerprint
        private_key_path = var.api_private_key_path
        region           = var.verrazzano_regions["admin"]
        tenancy_ocid     = var.tenancy_id
        user_ocid        = var.user_id
        alias            = "admin"
      }

      provider "oci" {
        fingerprint      = var.api_fingerprint
        private_key_path = var.api_private_key_path
        region           = var.verrazzano_regions["home"]
        tenancy_ocid     = var.tenancy_id
        user_ocid        = var.user_id
        alias            = "home"
      }

      provider "oci" {
        fingerprint      = var.api_fingerprint
        private_key_path = var.api_private_key_path
        region           = var.verrazzano_regions["syd"]
        tenancy_ocid     = var.tenancy_id
        user_ocid        = var.user_id
        alias            = "syd"
      }

      provider "oci" {
        fingerprint      = var.api_fingerprint
        private_key_path = var.api_private_key_path
        region           = var.verrazzano_regions["mum"]
        tenancy_ocid     = var.tenancy_id
        user_ocid        = var.user_id
        alias            = "mum"
      }

      provider "oci" {
        fingerprint      = var.api_fingerprint
        private_key_path = var.api_private_key_path
        region           = var.verrazzano_regions["tok"]
        tenancy_ocid     = var.tenancy_id
        user_ocid        = var.user_id
        alias            = "tok"
      }
      ```

1. **Create clusters**
   In `main.tf`, we'll create the different clusters (note that some of the parameters here have the same values, and you could use the default ones, but it's definitely possible to configure these by regions too):  

      ```JSON
      module "vadmin" {
        source  = "oracle-terraform-modules/oke/oci"
        version = "4.0.1"

        home_region = var.verrazzano_regions["home"]
        region      = var.verrazzano_regions["admin"]

        tenancy_id = var.tenancy_id

        # general oci parameters
        compartment_id = var.compartment_id
        label_prefix   = "v8o"

        # ssh keys
        ssh_private_key_path = "~/.ssh/id_rsa"
        ssh_public_key_path  = "~/.ssh/id_rsa.pub"

        # networking
        create_drg                   = true
        internet_gateway_route_rules = []
        nat_gateway_route_rules = [
          {
            destination       = "10.1.0.0/16"
            destination_type  = "CIDR_BLOCK"
            network_entity_id = "drg"
            description       = "To Sydney"
          },
          {
            destination       = "10.2.0.0/16"
            destination_type  = "CIDR_BLOCK"
            network_entity_id = "drg"
            description       = "To Mumbai"
          },
          {
            destination       = "10.3.0.0/16"
            destination_type  = "CIDR_BLOCK"
            network_entity_id = "drg"
            description       = "To Tokyo"
          },
        ]

        vcn_cidrs     = ["10.0.0.0/16"]
        vcn_dns_label = "admin"
        vcn_name      = "admin"

        # bastion host
        create_bastion_host = true
        upgrade_bastion     = false

        # operator host
        create_operator                    = true
        enable_operator_instance_principal = true
        upgrade_operator                   = false

        # oke cluster options
        cluster_name                = "admin"
        control_plane_type          = "private"
        control_plane_allowed_cidrs = ["0.0.0.0/0"]
        kubernetes_version          = "v1.20.11"
        pods_cidr                   = "10.244.0.0/16"
        services_cidr               = "10.96.0.0/16"

        # node pools
        node_pools = {
          np1 = { shape = "VM.Standard.E4.Flex", ocpus = 2, memory = 32, node_pool_size = 2, boot_volume_size = 150, label = { app = "frontend", pool = "np1" } }
        }
        node_pool_name_prefix = "np-admin"

        # oke load balancers
        load_balancers          = "both"
        preferred_load_balancer = "public"
        public_lb_allowed_cidrs = ["0.0.0.0/0"]
        public_lb_allowed_ports = [80, 443]

        # freeform_tags
        freeform_tags = {
          vcn = {
            verrazzano = "admin"
          }
          bastion = {
            access     = "public",
            role       = "bastion",
            security   = "high"
            verrazzano = "admin"
          }
          operator = {
            access     = "restricted",
            role       = "operator",
            security   = "high"
            verrazzano = "admin"
          }
        }

        providers = {
          oci      = oci.admin
          oci.home = oci.home
        }
      }

      module "vsyd" {
        source  = "oracle-terraform-modules/oke/oci"
        version = "4.0.1"

        home_region = var.verrazzano_regions["home"]
        region      = var.verrazzano_regions["syd"]

        tenancy_id = var.tenancy_id

        # general oci parameters
        compartment_id = var.compartment_id
        label_prefix   = "v8o"

        # ssh keys
        ssh_private_key_path = "~/.ssh/id_rsa"
        ssh_public_key_path  = "~/.ssh/id_rsa.pub"

        # networking
        create_drg                   = true
        internet_gateway_route_rules = []
        nat_gateway_route_rules = [
          {
            destination       = "10.0.0.0/16"
            destination_type  = "CIDR_BLOCK"
            network_entity_id = "drg"
            description       = "To Admin"
          }
        ]

        vcn_cidrs     = ["10.1.0.0/16"]
        vcn_dns_label = "syd"
        vcn_name      = "syd"

        # bastion host
        create_bastion_host = false
        upgrade_bastion     = false

        # operator host
        create_operator                    = false
        enable_operator_instance_principal = true
        upgrade_operator                   = false

        # oke cluster options
        cluster_name                = "syd"
        control_plane_type          = "private"
        control_plane_allowed_cidrs = ["0.0.0.0/0"]
        kubernetes_version          = "v1.20.11"
        pods_cidr                   = "10.245.0.0/16"
        services_cidr               = "10.97.0.0/16"

        # node pools
        node_pools = {
          np1 = { shape = "VM.Standard.E4.Flex", ocpus = 2, memory = 32, node_pool_size = 2, boot_volume_size = 150 }
        }

        # oke load balancers
        load_balancers          = "both"
        preferred_load_balancer = "public"
        public_lb_allowed_cidrs = ["0.0.0.0/0"]
        public_lb_allowed_ports = [80, 443]

        # freeform_tags
        freeform_tags = {
          vcn = {
            verrazzano = "syd"
          }
          bastion = {
            access     = "public",
            role       = "bastion",
            security   = "high"
            verrazzano = "syd"
          }
          operator = {
            access     = "restricted",
            role       = "operator",
            security   = "high"
            verrazzano = "syd"
          }
        }

        providers = {
          oci      = oci.syd
          oci.home = oci.home
        }
      }

      module "vmum" {
        source  = "oracle-terraform-modules/oke/oci"
        version = "4.0.1"

        home_region = var.verrazzano_regions["home"]
        region      = var.verrazzano_regions["mum"]

        tenancy_id = var.tenancy_id

        # general oci parameters
        compartment_id = var.compartment_id
        label_prefix   = "v8o"

        # ssh keys
        ssh_private_key_path = "~/.ssh/id_rsa"
        ssh_public_key_path  = "~/.ssh/id_rsa.pub"

        # networking
        create_drg                   = true
        internet_gateway_route_rules = []
        nat_gateway_route_rules = [
          {
            destination       = "10.0.0.0/16"
            destination_type  = "CIDR_BLOCK"
            network_entity_id = "drg"
            description       = "To Admin"
          }
        ]

        vcn_cidrs     = ["10.2.0.0/16"]
        vcn_dns_label = "mum"
        vcn_name      = "mum"

        # bastion host
        create_bastion_host = false
        upgrade_bastion     = false

        # operator host
        create_operator                    = false
        enable_operator_instance_principal = true
        upgrade_operator                   = false

        # oke cluster options
        cluster_name                = "mum"
        control_plane_type          = "private"
        control_plane_allowed_cidrs = ["0.0.0.0/0"]
        kubernetes_version          = "v1.20.11"
        pods_cidr                   = "10.246.0.0/16"
        services_cidr               = "10.98.0.0/16"

        # node pools
        node_pools = {
          np1 = { shape = "VM.Standard.E4.Flex", ocpus = 2, memory = 32, node_pool_size = 2, boot_volume_size = 150 }
        }

        # oke load balancers
        load_balancers          = "both"
        preferred_load_balancer = "public"
        public_lb_allowed_cidrs = ["0.0.0.0/0"]
        public_lb_allowed_ports = [80, 443]

        # freeform_tags
        freeform_tags = {
          vcn = {
            verrazzano = "mum"
          }
          bastion = {
            access     = "public",
            role       = "bastion",
            security   = "high"
            verrazzano = "mum"
          }
          operator = {
            access     = "restricted",
            role       = "operator",
            security   = "high"
            verrazzano = "mum"
          }
        }

        providers = {
          oci      = oci.mum
          oci.home = oci.home
        }
      }

      module "vtok" {
        source  = "oracle-terraform-modules/oke/oci"
        version = "4.0.1"

        home_region = var.verrazzano_regions["home"]
        region      = var.verrazzano_regions["tok"]

        tenancy_id = var.tenancy_id

        # general oci parameters
        compartment_id = var.compartment_id
        label_prefix   = "v8o"

        # ssh keys
        ssh_private_key_path = "~/.ssh/id_rsa"
        ssh_public_key_path  = "~/.ssh/id_rsa.pub"

        # networking
        create_drg                   = true
        internet_gateway_route_rules = []
        nat_gateway_route_rules = [
          {
            destination       = "10.0.0.0/16"
            destination_type  = "CIDR_BLOCK"
            network_entity_id = "drg"
            description       = "To Admin"
          }
        ]

        vcn_cidrs     = ["10.3.0.0/16"]
        vcn_dns_label = "tok"
        vcn_name      = "tok"

        # bastion host
        create_bastion_host = false
        upgrade_bastion     = false

        # operator host
        create_operator                    = false
        enable_operator_instance_principal = true
        upgrade_operator                   = false

        # oke cluster options
        cluster_name                = "tok"
        control_plane_type          = "private"
        control_plane_allowed_cidrs = ["0.0.0.0/0"]
        kubernetes_version          = "v1.20.11"
        pods_cidr                   = "10.247.0.0/16"
        services_cidr               = "10.99.0.0/16"

        # node pools
        node_pools = {
          np1 = { shape = "VM.Standard.E4.Flex", ocpus = 2, memory = 32, node_pool_size = 2, boot_volume_size = 150 }
        }

        # oke load balancers
        load_balancers          = "both"
        preferred_load_balancer = "public"
        public_lb_allowed_cidrs = ["0.0.0.0/0"]
        public_lb_allowed_ports = [80, 443]

        # freeform_tags
        freeform_tags = {
          vcn = {
            verrazzano = "tok"
          }
          bastion = {
            access     = "public",
            role       = "bastion",
            security   = "high"
            verrazzano = "tok"
          }
          operator = {
            access     = "restricted",
            role       = "operator",
            security   = "high"
            verrazzano = "tok"
          }
        }

        providers = {
          oci      = oci.tok
          oci.home = oci.home
        }
      }
      ```

1. **Display operators**
   For convenience, let's display the operator host in each region:  

      ```JSON
      output "ssh_to_admin_operator" {
        description = "convenient command to ssh to the Admin operator host"
        value       = module.vadmin.ssh_to_operator
      }

      output "ssh_to_au_operator" {
        description = "convenient command to ssh to the Sydney operator host"
        value       = module.vsyd.ssh_to_operator
      }

      output "ssh_to_in_operator" {
        description = "convenient command to ssh to the Mumbai operator host"
        value       = module.vmum.ssh_to_operator
      }

      output "ssh_to_jp_operator" {
        description = "convenient command to ssh to the Tokyo operator host"
        value       = module.vtok.ssh_to_operator
      }
      ```

### Create OKE clusters

1. Run `terraform init` and then `terraform plan`.
   The output of *plan* should indicate the following:  

      ```console
      Plan: 292 to add, 0 to change, 0 to destroy.Changes to Outputs:  
      + ssh_to_admin_operator = (known after apply)  
      + ssh_to_au_operator    = "ssh -i ~/.ssh/id_rsa -J opc@ opc@"  
      + ssh_to_in_operator    = "ssh -i ~/.ssh/id_rsa -J opc@ opc@"  
      + ssh_to_jp_operator    = "ssh -i ~/.ssh/id_rsa -J opc@ opc@"
      ```

1. Run `terraform apply` and then `terraform relax`.
   Shortly after, you should see the following:  

   {% imgx aligncenter assets/Eeiu_1isUl47wVZAAd1eoA.png 975 88 "Simultaneous creation of 4 OKE clusters in different regions" "Simultaneous creation of 4 OKE clusters in different regions" %}

   This means that our four OKE Clusters are being simultaneously created in 4 different OCI regions. In about 15 minutes, you'll have all four clusters created:  

   {% imgx aligncenter assets/1vdOhprGm48QCzDjYBkUQQ.png 855 183 "Showing outputs after creating clusters" %}  

   >**NOTE:** The ssh commands to the various operator hosts will also be printed.
   {:.notice}

### Establish connections

1. **Create remote peering connections**
   1. Navigate to the DRGs in ***each*** **managed cluster's** region (Mumbai, Tokyo, and Sydney).
   2. Select **Remote Peering Attachment** and create a **Remote Peering Connection** (call it *rpc_to_admin*).
   3. In the **Admin region** (*Singapore* in our selected region), create 3 **Remote Peering Connections**:  

      {% imgx aligncenter assets/sub6pYSaRFEQumzQLQdDxwg.png 1200 339 "3 RPCs in the Admin region" "3 RPCs in the Admin region" %}  

      Now, we need to peer them.

1. **Peer the connections**
   1. Select **rpc_to_syd**.
   1. Open a new tab in your browser and access the *OCI Console*.
   1. Change the region to *Sydney*.
   1. Navigate to the DRG and then to **rpc_to_syd** page.
   1. Copy the RPC's OCID (not the DRG), switch to the **Admin** tab, and then select **Establish Connection**:  

      {% imgx aligncenter assets/2g_Oih2j9NBRy_cUoUW9Eg.png 619 216 "Establishing RPC" "Establishing RPC" %}  

1. **Establish connection**
    1. Once you've provided the *RPC ID* and the *region* as above, select **Establish Connection** to perform the peering.
    2. Repeat the same procedure for the Tokyo and Mumbai regions until all the managed cluster regions are peered with the Admin region. When the peering is performed and completed, you will see its status will change to “Pending” and eventually “Peered”:  

       {% imgx aligncenter assets/DX7Nv3MRwczRYbmc5aXzlA.png 1200 405 "RPCs in Pending state" "RPCs in Pending state" %}

       {% imgx aligncenter assets/TSN09Afrj1KwHSEjFeYQ.png 1110 471 "RPCs in Peered state" "RPCs in Peered state" %}

### Configure

At this point, our VCNs are peered but there are three more things we need to do:  

1. Configure routing tables so that the Verrazzano managed clusters can communicate to the Admin cluster and vice-versa
1. Configure NSGs for the control plane CIDRs to accept requests from Admin VCN
1. Merge the `kubeconfigs`

In the first step, we're asked to configure the routing table. Previously, you would have had to manually configure rules, but now, they're automagically done for you! "How," you ask? Well, one of the [features](https://github.com/oracle-terraform-modules/terraform-oci-oke/releases) we've added is the [ability to configure and update routing tables](https://github.com/oracle-terraform-modules/terraform-oci-oke/issues/279).  

Let's explore this in a little more detail. In your `main.tf`, take a look in the the Admin cluster module. Usually, the `nat_gateway_route_rules`  parameter is an empty list:  

```JSON
nat_gateway_route_rules = []
```

However, in our Admin module definition, notice that we had already changed this to:  

```JSON
nat_gateway_route_rules = [
{
  destination       = "10.1.0.0/16"
  destination_type  = "CIDR_BLOCK"
  network_entity_id = "drg"       
  description       = "To Sydney"
},
{
  destination       = "10.2.0.0/16"
  destination_type  = "CIDR_BLOCK"
  network_entity_id = "drg"       
  description       = "To Mumbai"
},
{
  destination       = "10.3.0.0/16"
  destination_type  = "CIDR_BLOCK"
  network_entity_id = "drg"       
  description       = "To Tokyo"
},
]
```

Similarly, in the managed cluster definitions, we had also set the routing rules to reach the Admin cluster in Singapore:  

```JSON
nat_gateway_route_rules = [  
  {  
    destination       = "10.0.0.0/16"  
    destination_type  = "CIDR_BLOCK"  
    network_entity_id = "drg"  
    description       = "To Admin"  
  }  
]
```

>**NOTE:** You can always update these rules later.
{:.notice}

**Example - updating routing rules:**

Let's say you add another managed region in Hyderabad (VCN CIDR: 10.4.0.0). There's a couple of things you'll need to do to have this region recognized.

1. **Add new rule**
   In the routing rules for Admin, you'll need to add an additional entry to route traffic to this new region:

      ```JSON
      nat_gateway_route_rules = [  
      {  
        destination       = "10.4.0.0/16"  
        destination_type  = "CIDR_BLOCK"  
        network_entity_id = "drg"  
        description       = "To Hyderabad"  
      }  
      ]
      ```

1. **Update**
   After updating the custom rules, run `terraform apply` again and the routing rules in the Admin region will be updated.

1. **Check rules**
   Navigate to the **Network Visualizer** page to check your connectivity and routing rules:  

   {% imgx aligncenter assets/oS_bZ4lnAounnM_lgBGELg.png 1200 390 "Network connectivity across regions" "Network connectivity across regions" %}

1. **TCP requests**
   Next, in *each* region-managed VCN's control plane NSG, add an ingress to accept TCP requests from source CIDR 10.0.0.0/16 (Admin) and destination port 6443. This is so that the Admin cluster can be able to communicate with the Managed Cluster's control plane.  

   {% imgx aligncenter assets/UbwGSoe2twNSHayNM4YfRg.png 1200 359 "Additional ingress security rule in each managed cluster's control plane NSG" "Additional ingress security rule in each managed cluster's control plane NSG" %}

## Operational Convenience

For convenience, we'd like to be able to execute most of our operations from the Admin operator host. To do this, we first need to obtain the `kubeconfig` of each cluster and then merge them together on the Admin operator. At the moment, this step isn't quite so convenient itself, since you'll have to perform it manually, but we're working to improve this in the future.  

### Obtain `kubeconfigs`

1. Navigate to *each* managed cluster's page and select **Access cluster**.
1. Copy the second command which allows you get the `kubeconfig` for that cluster:  

      ```console
      oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.... --file $HOME/.kube/configsyd --region ap-sydney-1 --token-version 2.0.0  --kube-endpoint PRIVATE_ENDPOINT

      oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.... --file $HOME/.kube/configmum --region ap-mumbai-1 --token-version 2.0.0  --kube-endpoint PRIVATE_ENDPOINT

      oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.... --file $HOME/.kube/configtok --region ap-tokyo-1 --token-version 2.0.0  --kube-endpoint PRIVATE_ENDPOINT
      ```

   >**NOTE:** You also have to rename the file so it won't overwrite the existing config for the Admin region. In our example above, that would be configsyd, configmum, and configtok.
   {:.alert}

1. Run the commands to get the managed cluster's respective `kubeconfigs`. You should have four `kubeconfigs`:  

      ```console
      $ ls -al .kube  
      total 16  
      drwxrwxr-x. 2 opc opc   71 Nov 10 11:40 .  
      drwx------. 4 opc opc  159 Nov 10 11:15 ..  
      -rw--w----. 1 opc opc 2398 Nov 10 11:15 config  
      -rw-rw-r--. 1 opc opc 2364 Nov 10 11:40 configmum  
      -rw-rw-r--. 1 opc opc 2364 Nov 10 11:40 configsyd  
      -rw-rw-r--. 1 opc opc 2362 Nov 10 11:40 configtok
      ```

   We can check access to the clusters from the Admin operator host:

      ```console
      cd .kubefor cluster in config configsyd configmum configtok; do  
        KUBECONFIG=$CLUSTER kubectl get nodes  
      done
      ```

   This will return us the list of nodes in each cluster:  

   {% imgx aligncenter assets/Wbt9jmrz8pJxxZliPssYBw.png 818 310 "List of nodes in each cluster" "List of nodes in each cluster" %}

### Rename cluster content

Again for convenience, another thing we'll want to do is rename each cluster's context. That way, we'll know which region we're dealing with.  

In this exercise, we want 1 context to equate to a Verrazzano cluster.  

1. Let's rename all the `kubeconfig` files first:

   * config -> admin
   * configmum -> mumbai
   * configsyd -> sydney
   * configtok -> tokyo

1. Now, let's rename their respective contexts:

      ```bash
      for cluster in admin sydney mumbai tokyo; do  
        current=$(KUBECONFIG=$cluster kubectl config current-context)  
        KUBECONFIG=$cluster kubectl config rename-context $current $cluster  
      done
      ```

### Merge

We're now ready to merge!

To merge the files, run:  

```bash
KUBECONFIG=./admin:./sydney:./mumbai:./tokyo kubectl config view --flatten > ./config
```

#### List contexts

To get a list of the contexts, run:

```console
kubectl config get-contexts
```

This will return the following:  

```console
CURRENT   NAME     CLUSTER               AUTHINFO           NAMESPACE
*         admin    cluster-cillzxw34tq   user-cillzxw34tqmumbai
mumbai    cluster-cuvo2ifxe2a   user-cuvo2ifxe2asydney   
sydney    cluster-cmgb37morjq   user-cmgb37morjqtokyo    
tokyo     cluster-coxskjynjra   user-coxskjynjra
```

Now, this is all rather verbose. Fortunately, there's a way to get nice, succinct output through [kubectx](https://github.com/ahmetb/kubectx). But generating clean output isn't all this tool can do. It can also be used to rename the contexts as well. In the next section, we'll explore this alternative a little further.

#### Install and run `kubectx`

First, let's install `kubectx`:  

```console
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx
chmod +x kubectx  
sudo mv kubectx /usr/local/bin
```

Now, run `kubectx`:

{% imgx aligncenter assets/DPsupx6c_ADhdwE0TwS-Zw.png 397 113 "Using kubectx" "Using kubectx" %}

The current context (i.e., the current Verrazzano cluster), is highlighted in yellow. We can also easily change contexts in order to perform Verrazzano installations and other operations. For example:  

{% imgx aligncenter assets/nCSAOCAmUaD-AYTnUDhDpA.png 390 160 "Changing context to Sydney" "Changing context to Sydney" %}

## What's next

We made it through a lot of material in this article. Let's review everything we covered:  

* Learned how to set up OKE, networking connectivity, and routing.
* Discovered operational convenience to run multi-cluster Verrazzano in different regions.
* Got started with `kubectx`

[//]:# (Do we need to include this following line?)

With this, I would like to thank my colleague and friend Shaun Levey for his ever perceptive insights into the intricacies of OCI Networking.

Our exploration continues in [Part 2](3-deploy-multi-cluster-verrazzano-oke), where we'll take a look at how to install Verrazzano in a multi-cluster configuration.

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
