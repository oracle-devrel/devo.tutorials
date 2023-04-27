---
title: Terraform Modules
parent: tf-201
tags: [open-source, terraform, iac, devops, intermediate]
categories: [iac, opensource]
thumbnail: assets/terraform-201.png
date: 2021-10-12 14:44
description: Learn how to wield the power of Terraform modules in your environment!
toc: true
author: tim-clegg
---
{% img aligncenter assets/terraform-201.png 400 400 "Terraform 201" "Terraform 201 Tutorial Series" %}

Terraform supports the ability to define a series of "building blocks" (so to speak), that can be easily deployed.  This modularity is achieved through the use of... drum roll, please... modules.

## What is a module?
Modules are made of "normal" Terraform code and consist of what you're already familiar with: inputs (variables/locals), outputs and resource definitions.  The key difference is that a module is designed to be used (invoked or "instantiated" in traditional programming speak) from within a Terraform project.  They're not designed to operate independently by themselves, but rather to be used as one part of a broader Terraform project (the project using/instantiating the module).

Most of the time, modules are purpose-built for a specific task/aspect/component of an environment.  Due to the extreme flexibility, how purpose-built you decide to go is entirely up to you!

For instance, some modules are designed from the perspective of a very small aspect of the environment (such as managing a Subnet and its Route Table, Security Lists, DHCP Options, etc.), others comprise *lots* of resources (VCN, Subnets, compute instances, block volumes, object storage buckets, etc.).  Here are some of the different ways that modules can be designed around:

* Resource(s)
* Components within an environment
* Role
* Entire environment

There's really no limit or one-size-fits-all approach to carving out modules for your environment.  It's a good idea to sit down and think through how your organization operates, as well as the type of resources that will be managed.  For some organizations, maintaining a clear separation of duty might impact how modules are created and used (more focused/finite in scope), while others might take a "flatter" approach (one module to manage all resources).

It's possible to construct projects based on nested modules, which can get a bit complex, but can also be powerful.

> **NOTE:** Nested modules can be very powerful, but can also significantly increase the complexity and difficulty in building/maintaining the environment.  Nesting modules is not for the faint of heart!
{:.notice}

## Module design
A module offers the ability to provide a new, different, abstracted interface for a given use-case.  This sounds a bit confusing, right?  Whether you're deploying a single resource or many resources, encapsulating this into a Terraform module allows *you* to specify what kind of user interface consumers of the module will experience.

You control the inputs (variables) as well as the outputs that users consuming the module interacts with.  This is pretty powerful, as you can provide a really abstracted, simplified user interface (UI) for very complex and involved topologies (if you want to).  Or you can expose every nerd-knob possible.  The choice is yours.

It's important to realize the benefits and drawbacks of having abstracted interfaces.

**Benefits**
* It's easy to deliver a purpose-built, clean UI.
* Can greatly simplify (DRY) up the UI, by simplifying and distilling the inputs.
* Using "sane defaults" for optional variables, complexity can still be exposed, with some variables being left as optional.
* Great way to create and organization/environment-wide naming/standards, embedding them into the modules, which users use to create/manage their environment.

**Drawbacks**
* Requires consumers (people using the module) to learn/understand a new UI.  Usually they need to know/understand the underlying cloud platform/Terraform provider UIs.  Having an abstracted module interface requires yet another UI for consumers to learn/understand to effectively leverage the module(s).
* To simplify things, some level of rigidity can occur in the module UI (out of necessity).
* With rigidity comes lack of usability (unapplicable outside of the narrow, intended use-case the module is designed for).

## Building your first module
Enough talk, let's get to building a module!  From within your Cloud Shell session, run the following:

```console
cd ~
mkdir tf-modules
cd tf-modules
```

This gives us a brand-new directory for us to work in.

### Defining the module scope
Let's start by scoping out what the module will do:

* Deploy a VCN and two Subnets (dev and test).

### Module UI - inputs
Now let's think about the UI.  We're going to keep this really simple and ask for just a few pieces of information:

| Input | Type | Description |
|-------|------|-------------|
| Tenancy OCID | String | We'll need to know the tenancy OCID to know which tenancy to deploy against. |
| Region | String | We must know which region to deploy to. |
| Compartment OCID | String | Support specifying the compartment to deploy resources into. |
| Environment name | String | We'll have a default value, but will let the user override it if they'd like. |
| Environment CIDR block | String | We'll default to 192.168.0.0/20, but allow the user to specify their own CIDR block if they'd like a different one. |

Now let's take it a step further and fill-in a few details that we'll need for the actual Terraform code.  Let's add the variables and default values to the list:

| Input | Type | Description | Default Value | Variable name |
|-------|------|-------------|---------------|---------------|
| Tenancy OCID | String | We'll need to know the tenancy OCID to know which tenancy to deploy against. | None - this is required | `tenancy_ocid` |
| Region | String | We must know which region to deploy to. | None - this is required | `region` |
| Compartment OCID | String | Support specifying the compartment to deploy resources into. | None - this is required | `compartment_ocid` |
| Environment name | String | We'll have a default value, but will let the user override it if they'd like. | `awesome_env` | `env_name` |
| Environment CIDR block | String | We'll default to 192.168.0.0/20, but allow the user to specify their own CIDR block if they'd like a different one. | `192.168.0.0/20` | `env_cidr` |

This is a great start!  It's simple, with only the `tenancy_ocid` variable being required (the others have "sane defaults" which make them optional).

### Module UI - outputs
The last part of our module UI design focuses on the outputs for the module.  What might module consumers need *from* this module?  A lot of this really comes down to how the environment will be managed.  Here are some questions we consider before proceeding:

* Do we want users to be able to add discrete Subnets to the VCN that will be created, or should this largely be a static, fixed environment?
  * This will help determine if we need to export the VCN OCID (or other VCN details).
* Will compute instances be provisioned as part of this module in the future?
  * If users will provision Compute instances a-la-carte, we need to export the Subnet OCIDs.
* Since we'll be dynamically determining the Subnet CIDRs, we'll want to provide these values to the user.

The above are just a few considerations we ponder as we determine the output interface for the module.  We'll go with the most flexible approach, giving both the VCN and Subnet OCIDs as outputs, along with the Subnet CIDRs:

| Name | Value |
|------|-------|
| `vcn_id` | The VCN OCID. |
| `subnet_dev_id` | The OCID of the Development/Dev Subnet. |
| `subnet_dev_cidr` | The dynamically-allocated CIDR block used for the Development Subnet. |
| `subnet_test_id` | The OCID of the Test Subnet. |
| `subnet_test_cidr` | The dynamically-allocated CIDR block used for the Test Subnet. |

### Coding it
Funny thing, a module is largely just a normal piece of TF code, designed in such a way that it can be used in a generic fashion (called/used many times).

We'll follow the KISS principle (Keep It Super Simple) and use a local directory for the module:

```console
mkdir net-mod
cd net-mod
```

Now that we're in our "network module" (`net-mod`) directory, let's get busy coding.  First we'll put our inputs in the `variables.tf` file:

```terraform
variable "tenancy_ocid" {
  type = string
  description = "The tenancy OCID"
}
variable "region" {
  type = string
  description = "The region to deploy to"
}
variable "compartment_ocid" {
  type = string
  description = "The OCID of the compartment to deploy resources in."
}
variable "env_name" {
  type = string
  default = "awesome_env"
  description = "The name for the environment"
}
variable "env_cidr" {
  type = string
  default = "192.168.0.0/20"
  description = "The CIDR block to use for the environment."
}
```

Let's add some "meat" to this module, giving it something to do.  Let's go ahead and add the following to `vcn.tf`:

```terraform
resource oci_core_vcn "this" {
  cidr_block     = var.env_cidr
  compartment_id = var.compartment_ocid
  display_name   = var.env_name
  dns_label      = replace(var.env_name, "/[^A-Za-z0-9]+/", "")
}
```

We did a bit of fancy footwork for the `dns_label` attribute.  We're essentially stripping out any non-alpha-numeric characters, using the [`replace` Terraform function](https://www.terraform.io/docs/language/functions/replace.html).

Let's make life simple, by computing the Subnet CIDRs in separate locals.  Add this to the `locals.tf` file:

```terraform
locals {
  dev_cidr = cidrsubnets(var.env_cidr, 1, 1)[0]
  test_cidr = cidrsubnets(var.env_cidr, 1, 1)[1]
}
```

Add the following to `subnets.tf`:

```terraform
resource oci_core_subnet dev {
  cidr_block     = local.dev_cidr
  compartment_id = var.compartment_ocid
  display_name    = "dev"
  dns_label       = "dev"
  prohibit_public_ip_on_vnic = "true"
  vcn_id = oci_core_vcn.this.id
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
}

resource oci_core_subnet test {
  cidr_block     = local.test_cidr
  compartment_id = var.compartment_ocid
  display_name    = "test"
  dns_label       = "test"
  prohibit_public_ip_on_vnic = "true"
  vcn_id = oci_core_vcn.this.id
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
}
```

And just like that, we have a VCN along with two subnets.  The neat thing here is that we're dynamically determining the Subnet CIDRs (based off of the `env_cidr` variable that the user can provide).

We need to configure the module outputs, so put the following in `outputs.tf`:

```terraform
output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "subnet_dev_id" {
  value = oci_core_subnet.dev.id
}
output "subnet_dev_cidr" {
  value = local.dev_cidr
}

output "subnet_test_id" {
  value = oci_core_subnet.test.id
}
output "subnet_test_cidr" {
  value = local.test_cidr
}
```

The next step is to actually *use* our new module...

## Invoking (instantiating) modules
Modules can be called from a lot of [sources](https://www.terraform.io/docs/language/modules/sources.html) including local directories, git repos or from the [public Terraform Module Registry](https://registry.terraform.io/browse/modules) (to name just a few).  Check out the [Terraform module source documentation](https://www.terraform.io/docs/language/modules/sources.html) for more info.

> **NOTE:** If you're creating modules that are generic and can be used by most anybody, it's a nice idea to share the goodness and publish them on the [public Terraform Module Registry](https://registry.terraform.io/browse/modules) so others can re-use your awesome work!  Check out the directions in the [Terraform documentation](https://www.terraform.io/docs/language/modules/develop/publish.html) for more info on how to do this.

In our example, we're going to be showing how easy it is to "cookie cutter" roll-out several different environments, side-by-side, using the module we've just created.

Let's move to our `tf-modules` directory:

```console
cd ~/tf-modules
```

Now place the following in `provider.tf`:

```terraform
terraform {
  required_version = ">= 1.0.0"
}

provider "oci" {
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
}
```

Now we'll place the following in `main.tf` to keep things simple:

```terraform
module "env_1" {
  source = "./net-mod"
  
  region = var.region
  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.tenancy_ocid
}
```

> If you're wanting to use a specific Compartment, make sure to set the `compartment_ocid` attribute to the compartment OCID you wish to use (instead of `var.tenancy_ocid`).
{:.notice}

Lastly, let's define a few of the variables we'll be using in the Terraform *project* itself.  We'll end up having variables declared for the Terraform project as well as in the module(s) we use.  Place the following in `variables.tf`:

```terraform
variable "tenancy_ocid" {
  type = string
  description = "The tenancy OCID"
}
variable "region" {
  type = string
  description = "The region to deploy to"
}
```

In case this seems a bit confusing, here are the files that we should have at this point:

```
.
├── main.tf
├── provider.tf
├── variables.tf
└── net-mod
    ├── locals.tf
    ├── outputs.tf
    ├── subnets.tf
    ├── variables.tf
    └── vcn.tf
```

Remember, the module is completely self-contained, with its own definition of inputs/outputs, as well as resources it'll be managing.  The Terraform project that consumes the module has its own set of inputs/outputs and other potential resources (in addition to the module).

Move forward by initializing the Terraform environment:

```console
terraform init
```

Since we're using the OCI Cloud Shell, the tenancy OCID and region is pre-populated, but we need to put these values in environment variables that Terraform is expecting:

```console
declare -x TF_VAR_tenancy_ocid=`echo $OCI_TENANCY`
declare -x TF_VAR_region=`echo $OCI_REGION`
```

> **NOTE:** If you're prompted to enter a value for the `region` or `tenancy_ocid` variables, it's likely that the environment variables (above) need to be set.  Each time you connect to your OCI Cloud Shell session, you'll need to set these.
{:notice}

Now check what Terraform proposes be done:

```console
terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.env_1.oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "192.168.0.0/21"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "dev"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.env_1.oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "192.168.8.0/21"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "test"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.env_1.oci_core_vcn.this will be created
  + resource "oci_core_vcn" "this" {
      + cidr_block               = "192.168.0.0/20"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.tenancy.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "awesome_env"
      + dns_label                = "awesomeenv"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply"
now.
$
```

Let's go ahead and deploy these resources:

```console
terraform apply

<snip>
Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.env_1.oci_core_vcn.this: Creating...
module.env_1.oci_core_vcn.this: Creation complete after 1s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.test: Creating...
module.env_1.oci_core_subnet.dev: Creating...
module.env_1.oci_core_subnet.test: Still creating... [10s elapsed]
module.env_1.oci_core_subnet.dev: Still creating... [10s elapsed]
module.env_1.oci_core_subnet.test: Creation complete after 15s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.dev: Creation complete after 16s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

That's it!  Ok, so far, we've not saved much time.  In fact, this seems like we've added a bit of complexity (using modules) and wasted time.  Let's see why this is so great...

Go back into `main.tf` and add a few more environments:

```terraform
module "env_2" {
  source = "./net-mod"
  
  region = var.region
  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.tenancy_ocid
  env_cidr = "10.0.0.0/24"
  env_name = "Another env"
}

module "env_3" {
  source = "./net-mod"
  
  region = var.region
  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.tenancy_ocid
  env_cidr = "172.16.2.0/24"
  env_name = "Env 3"
}
```

Now re-initialize Terraform (this is needed because we're calling the module again):

```console
$ terraform init
Initializing modules...
- env_2 in net-mod
- env_3 in net-mod

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/oci from the dependency lock file
- Using previously-installed hashicorp/oci v4.46.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
$ 
```

> **NOTE:** Any time you have a new module definition, or update the module code, you should re-initialize Terraform (`terraform init`).  If you don't do this, when trying to call a new module definition, you'll get an error like the following:
> ```
$ terraform apply
╷
│ Error: Module not installed
│ 
│   on main.tf line 9:
│    9: module "env_2" {
│ 
│ This module is not yet installed. Run "terraform init" to install all modules required by this configuration.
╵
╷
│ Error: Module not installed
│ 
│   on main.tf line 19:
│   19: module "env_3" {
│ 
│ This module is not yet installed. Run "terraform init" to install all modules required by this configuration.
╵
$ 
```
{:notice}

Now apply it (yes, we're taking a shortcut here, bypassing running `terraform plan`):

```console
$ terraform apply
module.env_1.oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.env_2.oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.0.0.0/25"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "dev"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.env_2.oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.0.0.128/25"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "test"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.env_2.oci_core_vcn.this will be created
  + resource "oci_core_vcn" "this" {
      + cidr_block               = "10.0.0.0/24"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "Another env"
      + dns_label                = "Anotherenv"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

  # module.env_3.oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.2.0/25"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "dev"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.env_3.oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.2.128/25"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "test"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.env_3.oci_core_vcn.this will be created
  + resource "oci_core_vcn" "this" {
      + cidr_block               = "172.16.2.0/24"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "Env 3"
      + dns_label                = "Env3"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

Plan: 6 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.env_3.oci_core_vcn.this: Creating...
module.env_2.oci_core_vcn.this: Creating...
module.env_3.oci_core_vcn.this: Creation complete after 2s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.test: Creating...
module.env_3.oci_core_subnet.dev: Creating...
module.env_2.oci_core_vcn.this: Creation complete after 1s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.test: Creating...
module.env_2.oci_core_subnet.dev: Creating...
module.env_3.oci_core_subnet.dev: Creation complete after 4s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.dev: Creation complete after 5s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.test: Creation complete after 5s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.test: Creation complete after 5s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
$ 
```

Ok, now we're able to see the value of modules!  By simply adding a few lines of code, we were able to create multiple environments.  Each new environment would involve adding a few lines of code (referencing the module we created).  It's that easy!  The value increases as you have modules that manage more resources.

### Reading values from modules
So far we've seen how to create modules as well as how to "call" them.  I'd like to see the Subnet CIDRs it's selected, wouldn't you?  Let's do this now!  Add the following to `outputs.tf` (this will be a new file at this point):

```terraform
output "env_1_dev_cidr" {
  value = module.env_1.subnet_dev_cidr
}
output "env_1_test_cidr" {
  value = module.env_1.subnet_test_cidr
}

output "env_2_dev_cidr" {
  value = module.env_2.subnet_dev_cidr
}
output "env_2_test_cidr" {
  value = module.env_2.subnet_test_cidr
}

output "env_3_dev_cidr" {
  value = module.env_3.subnet_dev_cidr
}
output "env_3_test_cidr" {
  value = module.env_3.subnet_test_cidr
}
```

See these values by re-running `terraform apply`:

```console
$ terraform apply -auto-approve
module.env_1.oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_2.oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_3.oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

Changes to Outputs:
  + env_1_dev_cidr  = "192.168.0.0/21"
  + env_1_test_cidr = "192.168.8.0/21"
  + env_2_dev_cidr  = "10.0.0.0/25"
  + env_2_test_cidr = "10.0.0.128/25"
  + env_3_dev_cidr  = "172.16.2.0/25"
  + env_3_test_cidr = "172.16.2.128/25"

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

env_1_dev_cidr = "192.168.0.0/21"
env_1_test_cidr = "192.168.8.0/21"
env_2_dev_cidr = "10.0.0.0/25"
env_2_test_cidr = "10.0.0.128/25"
env_3_dev_cidr = "172.16.2.0/25"
env_3_test_cidr = "172.16.2.128/25"
$
```

> **NOTE:** We used the `-auto-approve` parameter above, as a shortcut.  This argument tells Terraform to *not* prompt you to continue - it just runs, no questions asked.  This is great for automated pipelines (where user input cannot be obtained), but can be dangerous.  Use it with care.  I used it here as the only change we made was the outputs, otherwise it wouldn't be safe to use this parameter.
{:alert}

The `outputs` area is what we're looking for.  Sure enough, there are the Subnet CIDRs that our module decided upon!  We'd likewise be able to get the Subnet (and VCN) OCIDs if we so desire.

## Iterating modules
So far we've only called a single module.  It is possible to instantiate several modules at one time, iterating through them.  Terraform supports using the [`count`](https://www.terraform.io/docs/language/meta-arguments/count.html) and [`for_each`](https://www.terraform.io/docs/language/meta-arguments/for_each.html) arguments in module definitions.

Here's how we might use the `for_each` attribute in our scenario.  Before we proceed, let's go ahead and destroy all of the existing resources:

```console
$ terraform destroy

<snip>

Plan: 0 to add, 0 to change, 9 to destroy.

Changes to Outputs:
  - env_1_dev_cidr  = "192.168.0.0/21" -> null
  - env_1_test_cidr = "192.168.8.0/21" -> null
  - env_2_dev_cidr  = "10.0.0.0/25" -> null
  - env_2_test_cidr = "10.0.0.128/25" -> null
  - env_3_dev_cidr  = "172.16.2.0/25" -> null
  - env_3_test_cidr = "172.16.2.128/25" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

module.env_2.oci_core_subnet.test: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.dev: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.dev: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.test: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.test: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_1.oci_core_subnet.dev: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.env_3.oci_core_subnet.dev: Destruction complete after 1s
module.env_2.oci_core_subnet.test: Destruction complete after 2s
module.env_1.oci_core_subnet.dev: Destruction complete after 1s
module.env_3.oci_core_subnet.test: Destruction complete after 1s
module.env_3.oci_core_vcn.this: Destroying... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_2.oci_core_subnet.dev: Destruction complete after 2s
module.env_2.oci_core_vcn.this: Destroying... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_3.oci_core_vcn.this: Destruction complete after 0s
module.env_1.oci_core_subnet.test: Destruction complete after 1s
module.env_1.oci_core_vcn.this: Destroying... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.env_2.oci_core_vcn.this: Destruction complete after 1s
module.env_1.oci_core_vcn.this: Destruction complete after 1s

Destroy complete! Resources: 9 destroyed.
$
```

Let's modify things a bit, making `main.tf` look like the following:

```terraform
locals {
  envs = {
    "awesome_1" = "10.0.0.0/20",
    "env_2"     = "192.168.10.0/24",
    "team_3"    = "10.10.10.0/25"
  }
}
module "envs" {
  for_each = local.envs
  source   = "./net-mod"
  
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  env_name         = each.key
  env_cidr         = each.value
}
```

Modify the contents of `outputs.tf` to look like:

```terraform
output "env_1_dev_cidr" {
  value = module.envs[keys(local.envs)[0]].subnet_dev_cidr
}
output "env_1_test_cidr" {
  value = module.envs[keys(local.envs)[0]].subnet_test_cidr
}

output "env_2_dev_cidr" {
  value = module.envs[keys(local.envs)[1]].subnet_dev_cidr
}
output "env_2_test_cidr" {
  value = module.envs[keys(local.envs)[1]].subnet_test_cidr
}

output "env_3_dev_cidr" {
  value = module.envs[keys(local.envs)[2]].subnet_dev_cidr
}
output "env_3_test_cidr" {
  value = module.envs[keys(local.envs)[2]].subnet_test_cidr
}
```

Re-initialize Terraform (this is needed anytime we add/remove a module to a Terraform project):

```console
$ terraform init

<snip>
```

Look at the plan:

```console
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.envs["awesome_1"].oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.0.0.0/21"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "dev"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.envs["awesome_1"].oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.0.8.0/21"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "test"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.envs["awesome_1"].oci_core_vcn.this will be created
  + resource "oci_core_vcn" "this" {
      + cidr_block               = "10.0.0.0/20"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "awesome_1"
      + dns_label                = "awesome1"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

  # module.envs["env_2"].oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "192.168.10.0/25"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "dev"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.envs["env_2"].oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "192.168.10.128/25"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "test"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.envs["env_2"].oci_core_vcn.this will be created
  + resource "oci_core_vcn" "this" {
      + cidr_block               = "192.168.10.0/24"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "env_2"
      + dns_label                = "env2"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

  # module.envs["team_3"].oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.10.10.0/26"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "dev"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.envs["team_3"].oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.10.10.64/26"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "test"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # module.envs["team_3"].oci_core_vcn.this will be created
  + resource "oci_core_vcn" "this" {
      + cidr_block               = "10.10.10.0/25"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "team_3"
      + dns_label                = "team3"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

Plan: 9 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + env_1_dev_cidr  = "10.0.0.0/21"
  + env_1_test_cidr = "10.0.8.0/21"
  + env_2_dev_cidr  = "192.168.10.0/25"
  + env_2_test_cidr = "192.168.10.128/25"
  + env_3_dev_cidr  = "10.10.10.0/26"
  + env_3_test_cidr = "10.10.10.64/26"

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply"
now.
$
```

This looks *really* good!  Talk about compressing the amount of Terraform code we have to write and maintain now!!!  Wow - we've found a way to scale to many environments with just a few lines of code.  It almost seems too good to be true.

Let's apply it:

```console
$ terraform apply

<snip>

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.envs["team_3"].oci_core_vcn.this: Creating...
module.envs["env_2"].oci_core_vcn.this: Creating...
module.envs["awesome_1"].oci_core_vcn.this: Creating...
module.envs["env_2"].oci_core_vcn.this: Creation complete after 1s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_subnet.dev: Creating...
module.envs["env_2"].oci_core_subnet.test: Creating...
module.envs["team_3"].oci_core_vcn.this: Creation complete after 1s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.test: Creating...
module.envs["team_3"].oci_core_subnet.dev: Creating...
module.envs["awesome_1"].oci_core_vcn.this: Creation complete after 1s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.test: Creating...
module.envs["awesome_1"].oci_core_subnet.dev: Creating...
module.envs["env_2"].oci_core_subnet.dev: Creation complete after 4s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_subnet.test: Creation complete after 4s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.test: Creation complete after 7s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.dev: Creation complete after 8s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.test: Still creating... [10s elapsed]
module.envs["team_3"].oci_core_subnet.dev: Still creating... [10s elapsed]
module.envs["team_3"].oci_core_subnet.test: Still creating... [20s elapsed]
module.envs["team_3"].oci_core_subnet.dev: Still creating... [20s elapsed]
module.envs["team_3"].oci_core_subnet.test: Still creating... [30s elapsed]
module.envs["team_3"].oci_core_subnet.dev: Still creating... [30s elapsed]
module.envs["team_3"].oci_core_subnet.test: Still creating... [40s elapsed]
module.envs["team_3"].oci_core_subnet.dev: Still creating... [40s elapsed]
module.envs["team_3"].oci_core_subnet.test: Creation complete after 45s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.dev: Creation complete after 45s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

env_1_dev_cidr = "10.0.0.0/21"
env_1_test_cidr = "10.0.8.0/21"
env_2_dev_cidr = "192.168.10.0/25"
env_2_test_cidr = "192.168.10.128/25"
env_3_dev_cidr = "10.10.10.0/26"
env_3_test_cidr = "10.10.10.64/26"
$ 
```

Let's refactor the outputs a bit further, making `outputs.tf` look like the following:

```terraform
output "env_cidrs" {
  value = join("\n", concat(
    [
      for k,v in local.envs:
        join("\n", [
          "${k} dev CIDR: ${module.envs[k].subnet_dev_cidr}",
          "${k} test CIDR: ${module.envs[k].subnet_test_cidr}"
        ])
    ]
  ))
}
```

Let's re-apply to see how this looks now:

```console
$ terraform apply -auto-approve
module.envs["awesome_1"].oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

Changes to Outputs:
  + env_cidrs = <<-EOT
        awesome_1 dev CIDR: 10.0.0.0/21
        awesome_1 test CIDR: 10.0.8.0/21
        env_2 dev CIDR: 192.168.10.0/25
        env_2 test CIDR: 192.168.10.128/25
        team_3 dev CIDR: 10.10.10.0/26
        team_3 test CIDR: 10.10.10.64/26
    EOT

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

env_1_dev_cidr = "10.0.0.0/21"
env_1_test_cidr = "10.0.8.0/21"
env_2_dev_cidr = "192.168.10.0/25"
env_2_test_cidr = "192.168.10.128/25"
env_3_dev_cidr = "10.10.10.0/26"
env_3_test_cidr = "10.10.10.64/26"
env_cidrs = <<EOT
awesome_1 dev CIDR: 10.0.0.0/21
awesome_1 test CIDR: 10.0.8.0/21
env_2 dev CIDR: 192.168.10.0/25
env_2 test CIDR: 192.168.10.128/25
team_3 dev CIDR: 10.10.10.0/26
team_3 test CIDR: 10.10.10.64/26
EOT
tim_clegg@cloudshell:tf-modules (us-phoenix-1)$ nano outputs.tf 
tim_clegg@cloudshell:tf-modules (us-phoenix-1)$ nano outputs.tf 
tim_clegg@cloudshell:tf-modules (us-phoenix-1)$ terraform apply -auto-approve
module.envs["team_3"].oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_vcn.this: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["env_2"].oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["team_3"].oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["awesome_1"].oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

Changes to Outputs:
  - env_1_dev_cidr  = "10.0.0.0/21" -> null
  - env_1_test_cidr = "10.0.8.0/21" -> null
  - env_2_dev_cidr  = "192.168.10.0/25" -> null
  - env_2_test_cidr = "192.168.10.128/25" -> null
  - env_3_dev_cidr  = "10.10.10.0/26" -> null
  - env_3_test_cidr = "10.10.10.64/26" -> null

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

env_cidrs = <<EOT
awesome_1 dev CIDR: 10.0.0.0/21
awesome_1 test CIDR: 10.0.8.0/21
env_2 dev CIDR: 192.168.10.0/25
env_2 test CIDR: 192.168.10.128/25
team_3 dev CIDR: 10.10.10.0/26
team_3 test CIDR: 10.10.10.64/26
EOT
$
```

With this code, it's super easy to add another environment, by simply adding an entry to `local.envs`.  Try this now, making your `main.tf` look like the following:

```terraform
locals {
  envs = {
    "awesome_1" = "10.0.0.0/20",
    "env_2" = "192.168.10.0/24",
    "team_3" = "10.10.10.0/25",
    "env_4" = "10.1.2.0/24"
  }
}
module "envs" {
  for_each = local.envs
  source = "./net-mod"

  region = var.region
  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.tenancy_ocid
  env_name = each.key
  env_cidr = each.value
}
```

Re-apply it now:

```console
$ terraform apply

<snip>

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ env_cidrs = <<-EOT
        awesome_1 dev CIDR: 10.0.0.0/21
        awesome_1 test CIDR: 10.0.8.0/21
        env_2 dev CIDR: 192.168.10.0/25
        env_2 test CIDR: 192.168.10.128/25
      + env_4 dev CIDR: 10.1.2.0/25
      + env_4 test CIDR: 10.1.2.128/25
        team_3 dev CIDR: 10.10.10.0/26
        team_3 test CIDR: 10.10.10.64/26
    EOT

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.envs["env_4"].oci_core_vcn.this: Creating...
module.envs["env_4"].oci_core_vcn.this: Creation complete after 1s [id=ocid1.vcn.oc1.phx.<sanitized>]
module.envs["env_4"].oci_core_subnet.test: Creating...
module.envs["env_4"].oci_core_subnet.dev: Creating...
module.envs["env_4"].oci_core_subnet.test: Creation complete after 5s [id=ocid1.subnet.oc1.phx.<sanitized>]
module.envs["env_4"].oci_core_subnet.dev: Creation complete after 6s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

env_cidrs = <<EOT
awesome_1 dev CIDR: 10.0.0.0/21
awesome_1 test CIDR: 10.0.8.0/21
env_2 dev CIDR: 192.168.10.0/25
env_2 test CIDR: 192.168.10.128/25
env_4 dev CIDR: 10.1.2.0/25
env_4 test CIDR: 10.1.2.128/25
team_3 dev CIDR: 10.10.10.0/26
team_3 test CIDR: 10.10.10.64/26
EOT
$
```

How awesome is that!  A single line allowed us to create a new VCN and pair of Subnets, along with outputs.  With just a single line.  Yeah... that's pretty cool.

This is just one simple example... but you get an idea of the power of how modules can really scale your efforts!

## Conclusion
We've been able to get a taste of some of the power of modules in this lesson.  They're not for the faint of heart, but are valuable for many use-cases.  When building cookie-cutter resource definitions (such as standardized/"golden" configurations), modules can be key to achieving consistency and ease-of-use for the people managing your OCI resources.

There are many pre-made modules ready for you to use.  It's well worth taking a look at what's out there before you build a new one, to try to avoid re-building the wheel.  Here are some spots to check for Terraform modules purpose-built for OCI:

* [Public Terraform Module Registry](https://registry.terraform.io/browse/modules?provider=oci)
* [Oracle Developer Relations on GitHub](https://github.com/oracle-devrel)
* [Oracle Terraform Modules on GitHub](https://github.com/oracle-terraform-modules/)
* [Oracle Quick Start on GitHub](https://github.com/oracle-quickstart)

To further your learning, be sure to check out the [Terraform documentation on modules](https://www.terraform.io/docs/language/modules/index.html).  Have fun experimenting with modules!
