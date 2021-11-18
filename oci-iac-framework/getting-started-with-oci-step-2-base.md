---
title: Service Delivery Framework
parent: [tutorials,oci-iac-framework]
redirect_from: "/tutorials/7-steps-to-oci/getting-started-with-oci-step-2-base"
tags: [open-source, terraform, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/landing-zone.png
date: 2021-10-29 11:00:00
description: How to deploy a landing zone in OCI
toc: true
author: kubemen
---
{% imgx alignright assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

Oracle Cloud Infrastructure (OCI) is a programable data center, providing dedicated infrastructure in more than 30 locations world wide. The [share-nothing design][ref_sna] allows IT operators to launch [private clouds][ref_nist] on demand and enables enterprises to adopt managed services into an existing operation. This framework is inspired by the [CIS landing zone][oci_landing] and helps ITIL oriented organizations to build and launch private or public cloud services.

Customizing the framework enables application provider to manage multi-tenant services with clients shielded on the network layer. We recommend to study the following material before approaching this tutorial:   
Compartments, Group-, Policy- and User-Templates [Documentation](learn_doc_iam) [Video](learn_video_iam)  
Virtual Cloud Network [Documentation](learn_doc_network) [Video](learn_video_network)  
Key Vault [Documentation](learn_doc_vault) [Video](learn_video_vault)   
Object Store [Documentation](learn_doc_storage)  [Video](learn_video_storage)  

## Code Structure

We employ [Infrastructure as Code][ref_iac] to combine dedicated resources with managed cloud- and orchestration services into [custom resources][ref_logresource]. The code is separated into multipe definiton files that Terraform merges into one deployment plan at the time of execution. The following structure uses [compartments][oci_compartments] to reflect shared service center for independent businesses or business units that are separated on the network layer. 

| Nr. | Domain                  | File               | Resources                                              |          |
|:---:|:---                     |:---                | :---                                                   |:---      |
| 1   | Applications            | app.tf             | Hosts (VM & BM), instance groups and container cluster | optional |
| 2   | Database Infrastructure | db.tf              | CDB or PDB                                             | optional |
| 3   | Network Topology        | net.tf             | Virtual Cloud Network, Layer-3 Gateways                | required |
| 4   | Operations and Security | ops.tf             | Monitoring and management                              | required |
| 5   | Operations and Security | global.tf          | Global variables, datasources and naming conventions   | required |
| 6   | Operations and Security | default.tfvars     | Default parameter for a project                        | required |

In the background we build on a modular code structure that uses terraform modules to employ OCI resources and services. Templates for a predefined network topology and isolated database infrastructure extend the application oriented DevOps processes with customized resources. 

{% imgx aligncenter assets/taxonomy.png "Base Configuration Taxonomy" %}

Using declarative templates, provides operators with the flexibility to adjust their service delivery platform with evolving requirements. Global input parameters help to maintain readability of the code and avoid [repeating definitions][ref_dry]. We use the `~/project/default.tfvars` file to define global input parameter for an entire project. 

```
variable "tenancy_ocid"     { }

variable "organization"            { 
  type        = string
  description =  "provide a string that identifies the commercial owner of a service"
  default     = "org"   # Define a name that identifies the project
  validation {
        condition     = length(regexall("^[A-Za-z][A-Za-z0-9]{1,7}$", var.owner)) > 0
        error_message = "The service_label variable is required and must contain alphanumeric characters only, start with a letter and 5 character max."
  }
}
variable "project"            { 
  type        = string
  description =  "provide a string that refers to a project"
  default     = "name"   # Define a name that identifies the project
  validation {
        condition     = length(regexall("^[A-Za-z][A-Za-z0-9]{1,7}$", var.project)) > 0
        error_message = "The service_label variable is required and must contain alphanumeric characters only, start with a letter and 8 character max."
  }
}
variable "stage"           { 
  type = string
  description = "define the lifecycle status"
  default = "dev"           # Lifecycle stage for the code base
  validation {
        condition     = length(regexall("^[A-Za-z][A-Za-z0-9]{1,7}$", var.stage)) > 0
        error_message = "The service_label variable is required and must contain alphanumeric characters only, start with a letter and 3 character max."
  }
}

variable "region" {
  default = "us-ashburn-1"
  validation {
    condition     = length(trim(var.region,"")) > 0
    error_message = "The region variable is required."
  }
}

variable "owner" { 
  type = object({
    user_ocid                 = string
    api_fingerprint           = string
    api_private_key_path      = string
    private_key_password      = string
  })
  description = "refers to the technical owner of the tenancy"
  default     = {
    "user_ocid"                   : "",
    "api_fingerprint"           : "",
    "api_private_key_path"      : "",
    "private_key_password"      : ""
  }
}
```
The `~/project/global.tf` file contains common datasources and functions that can be utilized throughout the entire stack.

```
provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.root.user_ocid
  fingerprint          = var.root.fingerprint
  private_key_path     = var.root.private_key_path
  private_key_password = var.root.private_key_password
}

provider "oci" {
  alias                = "home"
  region               = local.regions_map[local.home_region_key]
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.root.user_ocid
  fingerprint          = var.root.fingerprint
  private_key_path     = var.root.private_key_path
  private_key_password = var.root.private_key_password
}

## --- data sources ---
data "oci_identity_regions"              "global"  { }                                        # Retrieve a list OCI regions
data "oci_identity_tenancy"              "ocloud"  { tenancy_id     = var.tenancy_ocid }      # Retrieve meta data for tenant
data "oci_identity_availability_domains" "ads"     { compartment_id = var.tenancy_ocid }      # Get a list of Availability Domains
data "oci_identity_compartments"         "root"    { compartment_id = var.tenancy_ocid }      # List root compartments
data "oci_objectstorage_namespace"       "ns"      { compartment_id = var.tenancy_ocid }      # Retrieve object storage namespace
data "oci_cloud_guard_targets"           "root"    { compartment_id = var.tenancy_ocid }
data "template_file" "ad_names"                    {                                          # List AD names in home region 
  count    = length(data.oci_identity_availability_domains.ads.availability_domains)
  template = lookup(data.oci_identity_availability_domains.ads.availability_domains[count.index], "name")
}

## --- input functions ---
# Define the home region identifier
locals {
  # Discovering the home region name and region key.
  regions_map         = {for rgn in data.oci_identity_regions.global.regions : rgn.key => rgn.name} # All regions indexed by region key.
  regions_map_reverse = {for rgn in data.oci_identity_regions.global.regions : rgn.name => rgn.key} # All regions indexed by region name.
  home_region         = data.oci_identity_tenancy.ocloud.home_region_key                            # Home region key obtained from the tenancy data source
  region_key          = lower(local.regions_map_reverse[var.region])                                # Region key obtained from the region name

  # Setting network access parameters
  anywhere                    = "0.0.0.0/0"
  valid_service_gateway_cidrs = ["oci-${local.region_key}-objectstorage", "all-${local.region_key}-services-in-oracle-services-network"]

  # Service label
  dns_label = format("%s%s%s", substr(var.owner, 0, 3), substr(var.project, 0, 5), substr(var.stage, 0, 3))
  display_name  = upper("${var.owner}_${var.project}_${var.stage}")
}

## --- global output parameter ---
output "account"   { value = data.oci_identity_tenancy.ocloud }
output "namespace" { value = data.oci_objectstorage_namespace.ns.namespace }
output "ad_names"  { value = sort(data.template_file.ad_names.*.rendered) } # List of ADs in the selected region
```

### Network Design

Before provisioning any compute or storage resources we need to setup a basic network. Therefore we start with the compartment for network operation. One of the unique features of OCI is the [virtual layer 2 network][oci_l2] design. Compared to the common network overlays in public clouds, this design provides the necessary control to create isolated data center on a shared infrastructure pool. Packet encapsulation shields private traffic on a shared network backbone to the extend of defining overlapping IP ranges. This allows for a multi-tenant design on the infrastructure layer, and prevents developers and operators to rely complex procedures building and maintaining multi-tenant applications. The following diagram exemplifies the topology in a multi data centre region. 

{% imgx assets/topology.png "Physical Network Topology" %}

A Virtual Cloud Network (VCN) contains a private ["Classless Inter-Domain Routing (CIDR)"][ref_cidr] and can be extend with publically addressable IP adresses.

{% imgx assets/segmentation.png "Network Segmentation" %}

Even though we need to distinguish the physical topology of single- and multi-data centre regions, the logical network layer remains the same, because the data center are connected through a close network and packet forwarding relys on [host routing mechanisms][ref_hostrouting]. Regional subnets enable operators to launch multi-data center networks for both, private and public cloud services. Beside the CIDR the VCN definition contains the Dynamic Routing Gateway (DRG) as IP peer and host for network functions like Internet Connectivity, Network Address Translation (NAT) or Private-Public Service Communication.


| CIDR | Subnet Mask     | Total IP      | Usable IP     |
|:---: |:---             |:---           | :---          |
| /32  | 255.255.255.255 | 1             | 1             |
| /31  | 255.255.255.254 | 2             | 0             |
| /30  | 255.255.255.252 | 4             | 2             |
| /29  | 255.255.255.248 | 8             | 6             |
| /28  | 255.255.255.240 | 16            | 14            |
| /27  | 255.255.255.224 | 32            | 30            |
| /26  | 255.255.255.192 | 64            | 62            |
| /25  | 255.255.255.128 | 128           | 126           |
| /24  | 255.255.255.0   | 256           | 254           |
| /23  | 255.255.254.0   | 512           | 510           |
| /22  | 255.255.252.0   | 1024          | 1022          |
| /21  | 255.255.248.0   | 2048          | 2046          |
| /20  | 255.255.240.0   | 4096          | 4094          |
| /19  | 255.255.224.0   | 8192          | 8190          |
| /18  | 255.255.192.0   | 16,384        | 16,382        |
| /17  | 255.255.128.0   | 32,768        | 32,766        |
| /16  | 255.255.0.0     | 65,536        | 65,534        |
| /15  | 255.254.0.0     | 131,072       | 131,070       |
| /14  | 255.252.0.0     | 262,144       | 262,142       |
| /13  | 255.248.0.0     | 524,288       | 524,286       |
| /12  | 255.240.0.0     | 1,048,576     | 1,048,574     |
| /11  | 255.224.0.0     | 2,097,152     | 2,097,150     |
| /10  | 255.192.0.0     | 4,194,304     | 4,194,302     |
| /09  | 255.128.0.0     | 8,388,608     | 8,388,606     |
| /08  | 255.0.0.0       | 16,777,216    | 16,777,214    |
| /07  | 254.0.0.0       | 33,554,432    | 33,554,430    |
| /06  | 252.0.0.0       | 67,108,864    | 67,108,862    |
| /05  | 248.0.0.0       | 134,217,728   | 134,217,726   |
| /04  | 240.0.0.0       | 268,435,456   | 268,435,454   |
| /03  | 224.0.0.0       | 536,870,912   | 536,870,910   |
| /02  | 192.0.0.0       | 1,073,741,824 | 1,073,741,822 |
| /01  | 128.0.0.0       | 2,147,483,648 | 2,147,483,646 |
| /00  | 0.0.0.0         | 4,294,967,296 | 4,294,967,294 |

We start the VCN definition with the network parameter.

```
# VCN parameters
variable "create_net"        { default = false }
variable "cidr"              { default = "10.0.0.0/16" }
variable "enable_routing"    { default = true }
variable "enable_internet"   { default = false }
variable "enable_nat"        { default = true }
variable "private_service"   { default = false }
```

In the sources file we define a valid hostname that refers to the owner and the lifecycle stage of an infrastructure platform.

```
# Create a valid hostname
locals {
  hostname = "${var.project}_${var.stage}"
}
```

We define the following resource blocks file in the *network.tf*. First we define the network compartment. A group and policy block that allows administrators to read all the resources in the tenancy and manage all the networking resources, except security lists, internet gateways, IPSec VPN connections, and customer-premises equipment. For the vcn definition, we rely on a [terraform module][tf_module_vcn] that combines the layer three gateways with the CIDR.

```
# Create a compartment network management
resource "oci_identity_compartment" "net" {
    #Required
    compartment_id  = var.net
    name            = "${var.project}_network"
    description     = "Compartment to manage network for ${var.project}"
    
    #Optional
    enable_delete   = false  // true will cause this compartment to be deleted when running `terrafrom destroy`
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

# Create the network administrator role
resource "oci_identity_group" "netops" {
    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}_netops"
    description     = "Group for the network administrator role"

    #Optional
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

# Define a the administration policies for network administrators
resource "oci_identity_policy" "netops" {
    name            = "netops"
    description     = "Policies for the network administrator role"
    compartment_id  = var.tenancy_ocid

    statements = [
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage vcns IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage subnets IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage route-tables IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage dhcp-options IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage drgs IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage cross-connects IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage cross-connect-groups IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage virtual-circuits IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage vnics IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage vnic-attachments IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to manage load-balancers IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to use virtual-network-family IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.netops.name} to read all-resources IN TENANCY",
    ]
}

# Launch the base network
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "2.2.0"

  # required inputs
  compartment_id               = oci_identity_compartment.net.id
  drg_display_name             = "${var.project}_${var.stage}_DRG"
  region                       = local.home_region
  vcn_dns_project                = local.hostname
  vcn_name                     = "${var.project}_${var.stage}_VCN"
  #internet_gateway_route_rules = list(object({ destination = string destination_type = string network_entity_id = string description = string }))
  #nat_gateway_route_rules      = list(object({ destination = string destination_type = string network_entity_id = string description = string }))

  # optional inputs 
  create_drg               = var.enable_routing
  internet_gateway_enabled = var.enable_internet
  project_stage             = local.hostname
  lockdown_default_seclist = true
  nat_gateway_enabled      = var.enable_nat
  service_gateway_enabled  = var.private_service
  vcn_cidr                 = var.cidr
  tags                     = { "module": "oracle-terraform-modules/vcn/oci", "terraformed": "yes", "budget": 0, "stage": var.stage }
}
```

In the *output.tf* file we add the reference to the module output.

```
# VCN parameter returns
output "vcn_id"         { value = module.vcn.vcn_id }
output "ig_route_id"    { value = module.vcn.ig_route_id }
output "nat_gateway_id" { value = module.vcn.nat_gateway_id }
output "nat_route_id"   { value = module.vcn.nat_route_id }
```

## Service Operation

Compartments denote a demarcation for administrator domains in OCI. A compartment membership determines the privilige to add, change or delete resources. For define our compartment structure with the [ITIL][itil_web] model in mind. The first compartment defines the working environment for [service operators][itil_operation] and enables processes like incident or problem management. While ITIL distinguishes between [technical management services][itil_technical] and [application management services][itil_application], we rely on Infrastructure as a Servce and separate network- and database-manager in distinct compartments. On the application layer we distinguish between application management and application development. The later compromises platform services and allows to define an own code chain, meanwhile application managers receive the necessary rights to deploy and manage binaries. The definitions are captured in the `~/starter/operation.tf` template. 

{% imgx assets/itil_cloud.png "Cloud Operating Model" %}

First, we create a set of roles with priviledged access to operation data and tools. Cloud operators that make sure that services are delivered effectively and efficiently. This includes fulfilling of user requests, resolving service failures, fixing problems, as well as carrying out routine operational tasks. These roles get provisiones in form of groups. Group policies allow to define the different administrator roles on a granular level. Initially we stick to four groups: a cloud account adminstrator, security manager, user manager and "readonly" e.g. for auditors. In HCL we use a [complex variable type][tf_type], a map, to describe the different roles.

```
# the base set of operator roles
variable "operator" {
  type    = map
  default = {
    "cloudops"  = [
        "ALLOW GROUP tenant to read users IN TENANCY",
        "ALLOW GROUP tenant to read groups IN TENANCY",
        "ALLOW GROUP tenant to manage users IN TENANCY",
        "ALLOW GROUP tenant to manage groups IN TENANCY where target.group.name = 'Administrators'",
        "ALLOW GROUP tenant to manage groups IN TENANCY where target.group.name = 'secops'",
    ]
    "iam"   = [
        "ALLOW GROUP userid to read users IN TENANCY",
        "ALLOW GROUP userid to read groups IN TENANCY",
        "ALLOW GROUP userid to manage users IN TENANCY",
        "ALLOW GROUP userid to manage groups IN TENANCY where all {target.group.name ! = 'Administrators', target.group.name ! = 'secops'}",
    ]
    "secops" = [
        "ALLOW GROUP security to manage security-lists IN TENANCY",
        "ALLOW GROUP security to manage internet-gateways IN TENANCY",
        "ALLOW GROUP security to manage cpes IN TENANCY",
        "ALLOW GROUP security to manage ipsec-connections IN TENANCY",
        "ALLOW GROUP security to use virtual-network-family IN TENANCY",
        "ALLOW GROUP security to manage load-balancers IN TENANCY",
        "ALLOW GROUP security to read all-resources IN TENANCY",
    ]
    "readonly" = [
        "ALLOW GROUP read_only to read all-resources IN TENANCY"
    ]
  }
}
```

We modify the group resource to reflect the list of roles. In a later stage we will use an own resource to assign the user accounts to one of these roles. From a terraform perspective we introduce a loop typ. With [count][tf_count] we create an ordered list and we can use the index to refer to the stored value. While \[each.key\] loops through the user list, \[0\] refers to the first group.


```
# Create a service operation compartment
resource "oci_identity_compartment" "operation" {
    provider        = oci.home

    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}${var.stage}_ops"
    description     = "Compartment to manage ${var.project} ${var.stage} services"
    
    #Optional
    enable_delete   = false  // true will cause this compartment to be deleted when running `terrafrom destroy`
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

resource "oci_identity_group" "operators" {
    provider       = oci.home
    for_each       = var.operator

    #Required
    compartment_id  = var.tenancy_ocid
    name            = each.key
    description     = "group for the ${each.key} role"

    #Optional
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

resource "oci_identity_policy" "operation" {
    provider       = oci.home
    for_each       = var.operator

    #Required
    compartment_id = var.tenancy_ocid
    name           = each.key
    description    = "Policies for the ${each.key} operator"
    statements     = each.value
}
```

In the output file we create a map containing the name and respective OCID for the new defined roles.

```
output "operator" {
  value = {
    for operator in oci_identity_group.operators:
    operator.name => operator.id
  }
}
```

#### Key Vault
Vault is a cloud service that allows operators to manage encryption keys that protect data and secret credentials and to secure resource access. Vaults store master encryption keys and secrets that are used in configuration files and/or code. A secret is anything that requires controled access, such as API keys, passwords, certificates, or cryptographic keys.

After that we create the compartments for technical- and application manager. The tree structure is created, using the compartment_id argument. While the "resource" compartments refer to the tenancy_ocid, the service compartments refer to the parent compartment ID. This enables us to use [loops][tf_loop], counts and conditionals. Using lists helps to avoid the creation multiple blocks and allows to adjust the tree compartment structure, without rewriting the code. 

```
// Create a vault to store secrets

output "key_id" {
  value = oci_kms_key.main.id
}

resource "oci_kms_vault" "ops" {
  compartment_id = var.compartment_id

  display_name = "${var.project}ops_vault"
  vault_type   = "DEFAULT"   # or "VIRTUAL_PRIVATE"
}


resource "oci_kms_key" "main" {
  #Required
  compartment_id      = var.compartment_id
  display_name        = "${var.project}_${var.stage}_key"
  management_endpoint = data.oci_kms_vault.ops.management_endpoint

  key_shape {
    #Required
    algorithm = "AES"
    length    = 32
  }
}

// Gets the detail of the vault.
data "oci_kms_vault" "ops" {
  #Required
  vault_id = oci_kms_vault.ops.id
}


data "oci_kms_keys" "ops" {
  #Required
  compartment_id      = var.compartment_id
  management_endpoint = data.oci_kms_vault.ops.management_endpoint

  filter {
    name   = "display_name"
    values = oci_kms_key.main.display_name
  }
}
```

#### Management Bucket

Within the ops compartment we define a storage bucket to store files that need to be accessible to all operators. Examples are log files or terraform state file. We add the following resource blocks to the *ops.tf* template.

```
resource "oci_objectstorage_bucket" "ops" {
    provider       = oci.home
    #Required
    compartment_id = var.tenancy_ocid
    name           = "${var.project}_${stage}_tfstate"
    namespace      = "${var.project}_${stage}_ops"

    #Optional
    access_type   = var.bucket_access_type
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
    kms_key_id      = oci_objectstorage_kms_key.main.id
}
```

The complete [template][code_...] is stored in the code directory. In the compartment structure we break the technical management domain up into network and data management services. In addition, a tree structure for application management services enables operators to integrate multiple in- and external application owner, without giving up control over the main digital assets. 

### Data Management

Next we define the data management domain in order to maintain [data gravity][ref_dgravity] accross the four infrastructure deployment models for application developer and service operator. A [boolean variable][tf_boolean] to enable or dsiable the creation of the "data" compartment. 

```
variable "create_data" { default = false }
```

Initially, the *data.tf* contains only one resource definitions. We use the [count method][tf_count] to en- or disable the compartment creation. 

```
# Create a data management compartment 
resource "oci_identity_compartment" "data" {
    count           = var.create_data ? 1 : 0
    provider        = oci.home

    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}_data_domain"
    description     = "Compartment to manage persistent data for ${var.project}"
    
    #Optional
    enable_delete   = false  // true will cause this compartment to be deleted when running `terrafrom destroy`
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}
```

Admin policies define the tasks that a user can perform. We define groups for database administrators as well as file system manager and [assign policies][tf_data_policies]. Group memberships enable domain administrators to perform the tasks associated with these [policies][tf_policy].

```
# Create a file system administrator role 
resource "oci_identity_group" "fsadmin" {
    provider        = oci.home

    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}_${var.stage}_fs_administrator"
    description     = "Group for manager of network attached storage"

    #Optional
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

# Define a the administration policies for storage administrators
resource "oci_identity_policy" "fsadmin" {
    name            = "${var.project}_${var.stage}_fs_administrator_policy"
    description     = "Policies for manager of network attached storage"
    compartment_id  = var.tenancy_ocid

    statements = [
        "ALLOW GROUP ${oci_identity_group.fsadmin.name} to manage object-family IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.fsadmin.name} to manage volume-family IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.fsadmin.name} to read all-resources IN TENANCY",
    ]
}

# Create the database administrator role
resource "oci_identity_group" "dbadmin" {
    provider        = oci.home

    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}_${var.stage}_database_admin"
    description     = "Group for the network administrator role"

    #Optional
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

# Define a the administration policies for database administrators
resource "oci_identity_policy" "database_admin" {
    name            = "${var.project}_${var.stage}_database_admin_policy"
    description     = "Policies for the database administrator role"
    compartment_id  = var.tenancy_ocid


    statements = [
        "ALLOW GROUP ${oci_identity_group.dbadmin.name} manage database-family IN TENANCY",
        "ALLOW GROUP ${oci_identity_group.dbadmin.name} read all-resources IN TENANCY",
    ]
}
```

A data block that we call "trunk" creates a list of compartments attached to the root compartment.

```
# List root compartments 
data "oci_identity_compartments" "trunk" {
    #Required
    compartment_id             = var.tenancy_ocid

    #Optional
    access_level               = "ANY"              //ANY or ACCESSIBLE
    # applies only when you perform listCompartments on the tenancy
    #compartment_id_in_subtree = "ANY"
}
```

These data blocks are referenced in *output.tf*.

```
# Output compartment details for resource compartments
output "resources" {
    value = data.oci_identity_compartments.resources
}
```

### Application Management

For the application management domain we add a [variable containing list of application domains][tf_list]. 

```
variable "create_app" { default = false }
```

The *app.tf* it contains two resource definitions, one for the main app compartment and one for the sub-compartments. The compartment structure is reflected using a [complex variable type][tf_variable] that enables us to create list of sub-compartments.


```
# Create a main compartment application management (https://wiki.en.it-processmaps.com/index.php/ITIL_Application_Management)
resource "oci_identity_compartment" "app" {
    count           = var.create_app ? 1 : 0
    provider        = oci.home

    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}_applications"
    description     = "Compartment to manage applications for ${var.project}"
    
    #Optional
    enable_delete   = false  // true will cause this compartment to be deleted when running `terrafrom destroy`
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

# Create the system operator role
resource "oci_identity_group" "sysadmin" {
    provider        = oci.home

    #Required
    compartment_id  = var.tenancy_ocid
    name            = "${var.project}_${var.stage}_sysadmin"
    description     = "Group for the system operator role"

    #Optional
    # defined_tags  = {"terraformed": "yes", "budget": 0, "stage": var.stage}
    freeform_tags   = {"source": "/code/setup", "Parent"="root"}
}

resource "oci_identity_policy" "sysadmin" {
    name            = "${var.platform_stage}_${var.environment_stage}_system_administrator_policy"
    description     = "Policies for the system operator role"
    compartment_id  = var.tenancy_ocid

    statements = [
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to manage instance-family IN TENANCY where all {target.compartment.name=/*/, target.compartment.name!=/${var.project}_network/}",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to manage object-family IN TENANCY where all {target.compartment.name=/*/, target.compartment.name!=/${var.project}_network/}",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to manage volume-family IN TENANCY where all {target.compartment.name=/*/ , target.compartment.name!=/${var.project}_network/}",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to use load-balancers IN TENANCY where all {target.compartment.name=/*/ , target.compartment.name!=/${var.project}_network/}",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to use subnets IN TENANCY where target.compartment.name=/${var.project}_network/",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to use vnics IN TENANCY where target.compartment.name=/${var.project}_network/",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to use vnic-attachments IN TENANCY where target.compartment.name=/${var.project}_network/",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to manage compartments in Tenancy where all {target.compartment.name=/*/ , target.compartment.name!=/${var.project}_network/, target.compartment.name!=/${var.project}_applications/}",
        "ALLOW GROUP ${oci_identity_group.sysadmin.name} to read all-resources IN TENANCY",
    ]
}
```

We loop over our platform- and the services block, using the [count method][tf_count]. *Count* refers to keys using the respective index number `[count.index]`. The `${ }` construct allows to use variables inside a string. Freeform tags provide non-harmonized context information. After that we define the data blocks in the *sources.tf* to return the identifier for the compartments that are defined in the deployment plan.

```
# List app compartments 
data "oci_identity_compartments" "apps" {
    #Required
    compartment_id             = oci_identity_compartment.app.id

    #Optional
    access_level               = "ANY"              //ANY or ACCESSIBLE
    # applies only when you perform ListCompartments on the tenancy
    #compartment_id_in_subtree = "ANY"
}
```

These data blocks are referenced in *output.tf*.

```
# Output compartment details for app compartments
output "apps" {
    value = data.oci_identity_compartments.apps
}
```

A complete [compartment.tf][code_compartment] examle file is stored in the code directory. 

## User Management

After defining the compartment structure we create the initial admin users, leveraging the *user.tf* template. with the basic [resource block][tf_user] amd the [user data block][tf_data_users]. We define a variable that represents the admin profile and insert the variable at the top of our template. Information like the name, email and description is captured in a tuple, another [complex variable type][tf_variable]. User profiles allow tenant administrators to manage user information; manage privilege, application, and service access; and grant users self-management for their own accounts and services. 

```
variable "user" {
    description    = "user definition"
    type           = tuple([string, string, string, bool])
    default        = [ "user_name", "ocilabs@mail.com", "ITIL Administrator", true ]
}
```

The oci_identity_user resource block creates the admin users, the oci_identity_ui_password block the password and the oci_identity_user_capabilities_management block sets the user capabilities.

```
resource "oci_identity_user" "user_name" {
    provider       = oci.home

    #Required
    compartment_id = var.tenancy_ocid
    description    = var.user[2]
    name           = var.user[0]

    #Optional
    #defined_tags = {"Operations.CostCenter"= "42"}
    email          = var.user[1]
    freeform_tags  = {"Framework" = "itil"}
}

resource "oci_identity_ui_password" "user_secret" {
    provider       = oci.home
    user_id        = oci_identity_user.user_name.id
}

resource "oci_identity_user_capabilities_management" "user_name" {
  provider                         = oci.home
  user_id                          = oci_identity_user.user_name.id
  can_use_api_keys                 = false
  can_use_auth_tokens              = false
  can_use_console_password         = var.user[3]
  can_use_customer_secret_keys     = false
  can_use_smtp_credentials         = false
}
```

### Assigning Roles

We defined a number of groups to manage the roles and responsibilites. A common definition of roles and responsibilites is provided by the [ITIL framework][itil_roles]. The complete model is pretty broad, our specific concern is service operation and initially created the following administrator roles

| **Group**         | **Permissions**       |
| :---------------- |:----------------------|
| *cloud account* | Manage users. <br> Manage the Administrators and Netsecopss groups. <br><br> **Note**: Oracle creates the Administrators group when you subscribe to Oracle Cloud. The users in this group have full access to all the resources in the tenancy, including managing users and groups. Limit the membership to this group. |
| *security* | Read all the resources in the tenancy. <br> Manage security lists, internet gateways, customer-premises equipment, IPSec VPN connections, and load balancers. <br> Use all the virtual network resources.|
| *user* | Manage users. <br> Manage all the groups except Administrators and Netsecopss.|
| *network* | Read all the resources in the tenancy. <br> Manage all the networking resources, except security lists, internet gateways, IPSec VPN connections, and customer-premises equipment. |
| *system* | Read all the resources in the tenancy. <br> Manage the compute and storage resources. <br> Manage compartments. <br> Use load balancers, subnets, and VNICs. |
| *storage* | Read all the resources in the tenancy. <br> Manage the object storage and block volume resources. |
| *database* | Read all the resources in the tenancy. <br> Manage the database resources. |
| *Auditor (ReadOnly)* | View and inspect the tenancy. This group is for users who aren't expected to create or manage any resources (for example, auditors and trainees). |

```
resource "oci_identity_user_group_membership" "operator" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  for_each       = var.user_names
  user_id        = oci_identity_user.admins[each.key].id
  group_id       = oci_identity_group.itsm[0].id
}
```

With the oci_identity_ui_password data block we retrieve all information related to the password resource before we create the output block for the user details.

```
data "oci_identity_ui_password" "user_name" {
    #Required
    user_id         = oci_identity_user.user_name.id
}

output "user_details" {
    value           = oci_identity_ui_password.user_secret
}
```

The template will return the user details including the UI password. Passwords will be generated and shown at the `terraform apply` stage. When we use the `terraform output` command terraform will not return the passwords. The complete [template][code_user] is stored in the code directory.

[Bookmark this series][home] and check back soon for Database Infrastructure in Step 3.

<!--- Links -->
[home]:       index
[intro]:      getting-started-with-oci-intro.md
[provider]:   getting-started-with-oci-step-1-provider
[base]:       getting-started-with-oci-step-2-base
[db-infra]:   getting-started-with-oci-step-3-database-infrastructure
[app-infra]:  getting-started-with-oci-step-4-app-infrastructure
[workload]:   getting-started-with-oci-step-5-workload-deployment
[governance]: getting-started-with-oci-step-6-governance
[vizualize]:  step7-vizualize

[learn_doc_iam]:        https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm
[learn_doc_network]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm
[learn_doc_compute]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/Concepts/computeoverview.htm#Overview_of_the_Compute_Service
[learn_doc_storage]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm
[learn_doc_database]:   https://docs.cloud.oracle.com/en-us/iaas/Content/Database/Concepts/databaseoverview.htm
[learn_doc_vault]:      https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm
[learn_video_iam]:      https://www.youtube.com/playlist?list=PLKCk3OyNwIzuuA-wq2rVuxUE13rPTvzQZ
[learn_video_network]:  https://www.youtube.com/playlist?list=PLKCk3OyNwIzvHm2E-cGrmoMes-VwanT3P
[learn_video_compute]:  https://www.youtube.com/playlist?list=PLKCk3OyNwIzsAjIaUaVsKdXcfBOy6LASv
[learn_video_storage]:  https://www.youtube.com/playlist?list=PLKCk3OyNwIzu7zNtt_w1dXFOUbAjheMeo
[learn_video_database]: https://www.youtube.com/watch?v=F4-sxIsnbKI&list=PLKCk3OyNwIzsfuB9kj1CTPavjgByJBXGK
[learn_video_vault]:    https://www.youtube.com/watch?v=6OyrVWSL_D4

[oci_identity]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_availability_domains
[oci_l2]:       https://blogs.oracle.com/cloud-infrastructure/first-principles-l2-network-virtualization-for-lift-and-shift
[oci_landing]: https://docs.oracle.com/en/solutions/cis-oci-benchmark/
[oci_regional]: https://medium.com/oracledevs/provision-oracle-cloud-infrastructure-home-region-iam-resources-in-a-multi-region-terraform-f997a00ae7ed
[oci_compartments]: https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Concepts/settinguptenancy.htm#Understa
[oci_reference]:  https://docs.oracle.com/en/solutions/multi-tenant-topology-using-terraform/
[oci_policies]: https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Concepts/commonpolicies.htm
[oci_sdk_tf]: https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm
[oci_variable]: https://upcloud.com/community/tutorials/terraform-variables/#:~:text=Terraform%20variables%20can%20be%20defined,open%20the%20file%20for%20edit

[tf_boolean]:           https://medium.com/swlh/terraform-how-to-use-conditionals-for-dynamic-resources-creation-6a191e041857
[tf_count]:             https://www.terraform.io/docs/configuration/resources.html#count-multiple-resource-instances-by-count
[tf_compartment]:       https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_compartment
[tf_data_compartments]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_compartments
[tf_data_groups]:       https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_groups
[tf_data_policies]:     https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_policies
[tf_data_users]:        https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_users
[tf_doc]:               https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[tf_examples]:          https://github.com/terraform-providers/terraform-provider-oci/tree/master/examples
[tf_expression]:        https://www.terraform.io/docs/configuration/expressions.html
[tf_foreach]:           https://www.terraform.io/docs/configuration/resources.html#for_each-multiple-resource-instances-defined-by-a-map-or-set-of-strings
[tf_group]:             https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_group
[tf_intro]:             https://youtu.be/h970ZBgKINg
[tf_lint]:              https://www.hashicorp.com/blog/announcing-the-terraform-visual-studio-code-extension-v2-0-0
[tf_list]:              https://www.terraform.io/docs/language/values/variables.html#list-lt-type-gt-
[tf_loop]:              https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/
[tf_loop_tricks]:       https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
[tf_parameterize]:      https://build5nines.com/use-terraform-input-variables-to-parameterize-infrastructure-deployments/
[tf_pattern]:           https://www.hashicorp.com/resources/evolving-infrastructure-terraform-opencredo
[tf_policy]:            https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_policy
[tf_provider]:          https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[tf_pwd]:               https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_ui_password
[tf_resource]:          https://www.terraform.io/docs/configuration/resources.html
[tf_script]:            https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
[tf_sequence]:          https://www.terraform.io/docs/configuration/resources.html#create_before_destroy
[tf_ternary]:           https://github.com/hashicorp/terraform/issues/22131
[tf_type]:              https://www.terraform.io/docs/language/expressions/type-constraints.html
[tf_user]:              https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_user
[tf_variable]:          https://www.terraform.io/docs/configuration/variables.html
[tf_module_vcn]:        https://registry.terraform.io/modules/oracle-terraform-modules/vcn/oci/latest

[code_compartment]: ../code/iam/compartment.tf
[code_user]:        ../code/iam/user.tf
[code_group]:       ../code/iam/group.tf
[code_policy]:      ../code/iam/policy.tf
 
[ref_cidr]:          https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing
[ref_cli]:           https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/
[ref_dgravity]:      https://whatis.techtarget.com/definition/data-gravity
[ref_dry]:           https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[ref_hostrouting]:   https://networkencyclopedia.com/host-routing/
[ref_iac]:           https://en.wikipedia.org/wiki/Infrastructure_as_code
[ref_jmespath]:      https://jmespath.org/tutorial.html
[ref_jq]:            https://stedolan.github.io/jq/
[ref_jq_play]:       https://jqplay.org/
[ref_json_validate]: https://jsonlint.com/
[ref_l2]:            http://sherpainthecloud.com/en/blog/why-oci-l2-support-is-a-big-deal
[ref_logresource]:   https://pubs.opengroup.org/architecture/togaf9-doc/arch/apdxa.html
[ref_nist]:          https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-145.pdf
[ref_sna]:           https://en.wikipedia.org/wiki/Shared-nothing_architecture
[ref_vsc]:           https://code.visualstudio.com/
[ref_vdc]:           https://www.techopedia.com/7/31109/technology-trends/virtualization/what-is-the-difference-between-a-private-cloud-and-a-virtualized-data-center

[itil_application]: https://wiki.en.it-processmaps.com/index.php/ITIL_Application_Management
[itil_operation]:   https://wiki.en.it-processmaps.com/index.php/ITIL_Service_Operation
[itil_roles]:       https://wiki.en.it-processmaps.com/index.php/ITIL_Roles
[itil_technical]:   https://wiki.en.it-processmaps.com/index.php/ITIL_Technical_Management
[itil_web]:         https://www.axelos.com/best-practice-solutions/itil
