---
title: Making changes using Terraform
parent: [tutorials, tf-101]
sidebar: series
tags:
- open-source
- terraform
- iac
- devops
- beginner
- get-started
categories:
- iac
- opensource
thumbnail: assets/terraform-101.png
date: 2021-09-30 20:22
description: Time to make changes to our tutorial environment using Terraform.  But
  how?!
toc: true
author: tim-clegg
redirect_from: "/collections/tutorials/6-changing/"
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

Most environments tend to change on a regular basis.  These changes can be easily managed in a reliable, scalable way using Terraform.  Let's try this out now.

## Prerequisites

It's assumed that you're building off of the environment built in the [Creating Resources with Terraform tutorial](5-creating).

## Managing Change

When managing an environment with Terraform, there are largely three data sources that Terraform relies on:

* Terraform Code
* Terraform State
* Environment As-Built

### Terraform Code
The Terraform code is where you tell Terraform what you want it to manage.  As you've already seen, the Terraform code is just plain-text files with a `.tf` extension.

Many teams find it beneficial to commit their Terraform source code to a version control system (VCS) such as a git repository.  The VCS allows for limiting access to the source code (which can effectively contain your Oracle Cloud Infrastructure (OCI) topology, assuming it's defined in Terraform code).  Another benefit to using a VCS is having a natural audit trail of what has transpired in the environment (who-did-what-and-when).

### Terraform State
The Terraform state is a critical piece of information that Terraform will use upon each execution, cross-referencing what is deployed against the code and against what is cached in the state.  Additional resource data points are stored in the state, such as the OCID for a resource (after it's been created) as well as many other attributes that might not be explicitly set in the Terraform code.

When working as a team, it's important that each team member have a current, up-to-date copy of the Terraform state.  To keep things consistent, only one member of the team should make changes to the environment at any single point in time.

By default, the Terraform state is stored in the `terraform.tfstate` file located in the working directory.  There are several options for managing the Terraform State, but for now we'll be using the [local backend](https://www.terraform.io/docs/language/settings/backends/local.html) (which happens to be the default).

### Environment As-Built
The actual OCI (or other environment) resources that are present (or missing).  While this isn't really part of the Terraform configuration, managing resources is the reason that Terraform is being used.  Each run, Terraform will check the current as-built state of the environment, comparing it against the Terraform State and the code that is provided, to determine what might need to take place to bring the actual environment configuration into alignment with the desired end-state configuration given in the Terraform code.

## Adding a Resource
To start, let's add three new Subnets to the Virtual Cloud Network (VCN) that was created in the [previous tutorial](5-creating).  Add the following to your `main.tf` file:

```terraform
resource "oci_core_subnet" "dev_1" {
  vcn_id                      = oci_core_vcn.tf_101.id
  cidr_block                  = "172.16.0.0/24"
  compartment_id              = "<your_compartment_OCID_here>"
  display_name                = "Dev subnet 1"
  prohibit_public_ip_on_vnic  = true
  dns_label                   = "dev"
}

resource "oci_core_subnet" "test" {
  vcn_id                      = oci_core_vcn.tf_101.id
  cidr_block                  = "172.16.1.0/24"
  compartment_id              = "<your_compartment_OCID_here>"
  display_name                = "Testing subnet"
  prohibit_public_ip_on_vnic  = true
  dns_label                   = "test"
}

resource "oci_core_subnet" "stage" {
  vcn_id                      = oci_core_vcn.tf_101.id
  cidr_block                  = "172.16.2.0/24"
  compartment_id              = "<your_compartment_OCID_here>"
  display_name                = "Staging subnet"
  prohibit_public_ip_on_vnic  = true
  dns_label                   = "stage"
}
```

> **NOTE:** Make sure to use the compartment_id you wish to use.
{:.notice}

The above code adds three new subnets: one development Subnet, one testing Subnet and, one staging Subnet.  Each of these is placed in the compartment specified, within the VCN that was created in the [previous tutorial](5-creating).  Each has a unique IPv4 CIDR block which falls within the broader VCN IPv4 CIDR block.  None of the subnets permits public IPs to be used (they're prohibited).

Confirm that this will do what is intended by examining the Terraform plan:

```console
$ terraform plan
oci_core_vcn.tf_101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # oci_core_subnet.dev_1 will be created
  + resource "oci_core_subnet" "dev_1" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.0.0/24"
      + compartment_id             = "ocid1.compartment.oc1.<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Dev subnet 1"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>"
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_subnet.stage will be created
  + resource "oci_core_subnet" "stage" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.2.0/24"
      + compartment_id             = "ocid1.compartment.oc1.<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Staging subnet"
      + dns_label                  = "stage"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>"
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.1.0/24"
      + compartment_id             = "ocid1.compartment.oc1.<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Testing subnet"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>"
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

The plus sign (+) next to the three subnets listed in the above output means that Terraform is going to add three Subnet resources to your environment.  The existing VCN resource will remain unchanged. 

Being satisfied with this plan, apply it (to implement it).

```console
$ terraform apply
oci_core_vcn.tf_101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # oci_core_subnet.dev_1 will be created
  + resource "oci_core_subnet" "dev_1" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.0.0/24"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Dev subnet 1"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>"
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_subnet.stage will be created
  + resource "oci_core_subnet" "stage" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.2.0/24"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Staging subnet"
      + dns_label                  = "stage"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>"
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_subnet.test will be created
  + resource "oci_core_subnet" "test" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.1.0/24"
      + compartment_id             = "ocid1.compartment.oc1.<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Testing subnet"
      + dns_label                  = "test"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>"
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_subnet.stage: Creating...
oci_core_subnet.test: Creating...
oci_core_subnet.dev_1: Creating...
oci_core_subnet.stage: Creation complete after 7s [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.test: Creation complete after 8s [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev_1: Still creating... [10s elapsed]
oci_core_subnet.dev_1: Creation complete after 12s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Voila!  Your VCN now has three subnets in it.  This was a really easy way to add OCI resources to the VCN: add to the Terraform code in `main.tf` and ask Terraform to apply it!

## Modifying a Resource

As your fictitious environment is coming together, it's realized that the name of the development subnet isn't ideal.  Rather than calling it `dev_1`, this should be changed to just `dev`.

Because Terraform uses Infrastructure-as-Code (IaC), this can be done with a few minor changes to the `main.tf` file and then ask Terraform to apply it.  It's that easy!

Modify the existing the `oci_core_subnet.dev_1` resource definition in your `main.tf` to match the following:

```terraform
resource "oci_core_vcn" "tf_101" {
  dns_label             = "tf101"
  cidr_block            = "172.16.0.0/20"
  compartment_id        = "<your_compartment_OCID_here>"
  display_name          = "tf_101"
}

resource "oci_core_subnet" "dev" {
  vcn_id                      = oci_core_vcn.tf_101.id
  cidr_block                  = "172.16.0.0/24"
  compartment_id              = "<your_compartment_OCID_here>"
  display_name                = "Dev subnet"
  prohibit_public_ip_on_vnic  = true
  dns_label                   = "dev"
}

resource "oci_core_subnet" "test" {
  vcn_id                      = oci_core_vcn.tf_101.id
  cidr_block                  = "172.16.1.0/24"
  compartment_id              = "<your_compartment_OCID_here>"
  display_name                = "testing subnet"
  prohibit_public_ip_on_vnic  = true
  dns_label                   = "test"
}
```

Now look at the Terraform plan:

```console
$ terraform plan
oci_core_vcn.tf_101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.dev_1: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.stage: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
  - destroy

Terraform will perform the following actions:

  # oci_core_subnet.dev will be created
  + resource "oci_core_subnet" "dev" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "172.16.0.0/24"
      + compartment_id             = "ocid1.compartment.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "Dev subnet"
      + dns_label                  = "dev"
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6public_cidr_block      = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>“
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_subnet.dev_1 will be destroyed
  - resource "oci_core_subnet" "dev_1" {
      - cidr_block                 = "172.16.0.0/24" -> null
      - compartment_id             = "ocid1.compartment.oc1..<sanitized>" -> null
      - defined_tags               = {} -> null
      - dhcp_options_id            = "ocid1.dhcpoptions.oc1.phx.<sanitized>" -> null
      - display_name               = "Dev subnet 1" -> null
      - dns_label                  = "dev" -> null
      - freeform_tags              = {} -> null
      - id                         = "ocid1.subnet.oc1.phx.<sanitized>" -> null
      - prohibit_public_ip_on_vnic = true -> null
      - route_table_id             = "ocid1.routetable.oc1.phx.<sanitized>" -> null
      - security_list_ids          = [
          - "ocid1.securitylist.oc1.phx.<sanitized>",
        ] -> null
      - state                      = "AVAILABLE" -> null
      - subnet_domain_name         = "dev.example.oraclevcn.com" -> null
      - time_created               = "2021-02-09 20:22:38.422 +0000 UTC" -> null
      - vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>" -> null
      - virtual_router_ip          = "172.16.0.1" -> null
      - virtual_router_mac         = "00:11:...:22:33" -> null
    }

Plan: 1 to add, 0 to change, 1 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

Oh, no --- it looks like something has gone terribly awry! Terraform wants to destroy the `dev_1` Subnet and create a new `dev` subnet.

### Why is a Resource Being Deleted-and-Re-Created?

There are two primary reasons why a resource might be destroyed and re-created:

*	Platform (cloud) constraints
*	Renaming a resource name

In OCI, many changes are non-disruptive, however there are some resource changes that might be disruptive.  Take for instance the dns_label attribute.  According to the [OCI provider documentation for the Subnet resource](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_subnet#dns_label), the dns_label cannot be changed.  This would mean that if you wanted to change it on an existing OCI Subnet, you could see this delete-and-re-create behavior.  Terraform is smart enough to know that if an attribute cannot be updated in-place, then it must delete and re-create the resource.

The second situation occurs when you totally change the name of a resource in the Terraform code and don't ask Terraform to update the Terraform state.  From Terraform's perspective, it looks like you want to delete the old resource (which is present in the Terraform state, but does not exist in the code) and create a net-new resource (because your code refers to a resource that's non-existent in the Terraform state).

This can be a common mistake and be troublesome, but it can be easily resolved.  Rename the resource name in the Terraform state from the old name to the new name.  Terraform will then move forward as expected.  Do this now with the `terraform state mv` command:

```console
$ terraform state mv oci_core_subnet.dev_1 oci_core_subnet.dev
Move "oci_core_subnet.dev_1" to "oci_core_subnet.dev"
Successfully moved 1 object(s).
```

The above command asks Terraform to rename (move) the old resource name to a new resource name in the Terraform State.  Take a look at the [Terraform documentation](https://www.terraform.io/docs/cli/commands/state/mv.html) for more information.

> **NOTE:** When referencing resources in Terraform, the type of resource and its name must be used.  This is why in the above command, `oci_core_subnet.dev_1` was used instead of `dev_1`.
> The same name may be used multiple times, as long as it's used for different types of resources.  For instance, an OCI Route Table called `dev_1` could also exist without problem (referenced as `oci_core_route_table.dev_1`).
> When choosing names for your resources, it's unnecessary (and a bad idea) to include the type of resource in its name, because the resource type will always prefix the name when referencing it.
> For example, instead of using `oci_core_subnet.subnet_dev_1`, consider using `oci_core_subnet.dev_1`. It's clearly visible that this is referencing a Subnet, however the second version is a lot shorter and easier to read!
{:.notice}

Look at the Terraform plan again:

```console
$ terraform plan
oci_core_vcn.tf_101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.stage: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # oci_core_subnet.dev will be updated in-place
  ~ resource "oci_core_subnet" "dev" {
      ~ display_name               = "Dev subnet 1" -> "Dev subnet"
        id                         = "ocid1.subnet.oc1.phx.<sanitized>"
        # (15 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

The tilde (`~`) indicates an in-place change, which is what is expected for the display_name.  Proceed with applying the change:

```console
$ terraform apply

# ...

Terraform will perform the following actions:

  # oci_core_subnet.dev will be updated in-place
  ~ resource "oci_core_subnet" "dev" {
      ~ display_name               = "Dev subnet 1" -> "Dev subnet"
        id                         = "ocid1.subnet.oc1.phx.<sanitized>"
        # (15 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_subnet.dev: Modifying... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev: Modifications complete after 3s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

This tutorial took a slight detour, highlighting a scenario where a resource had to be renamed in the Terraform State to achieve the desired outcome.  Your OCI environment now has a VCN with three Subnets in it.

We've had fun creating new OCI resources and then making modifications to the environment.  It's now time to clean things up.  We'll explore destroying resources in the [next lesson](7-destroying).
{% endslides %}
