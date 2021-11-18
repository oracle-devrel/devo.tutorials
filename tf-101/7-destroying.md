---
title: Destroying resources with Terraform
parent: [tutorials, tf-101]
sidebar: series
tags:
- open-source
- terraform
- iac
- devops
- beginner
categories:
- iac
- opensource
thumbnail: assets/terraform-101.png
date: 2021-11-01 08:02
description: How to keep things neat and tidy with Terraform.
toc: true
author: tim-clegg
redirect_from: "/collections/tutorials/7-destroying/"
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

So far we've had some fun creating and changing OCI resources.  Our tutorial is coming to a close, so it's time to remove the resources we've added and clean-up after ourselves.  Terraform makes this amazingly easy.  Let's explore this now.

## Removing a Resource

The `stage` Subnet will be removed.  To do this, remove its resource definition (the following code snippet) from the `main.tf` file:

```terraform
resource "oci_core_subnet" "stage" {
  vcn_id                      = oci_core_vcn.tf_101.id
  cidr_block                  = "172.16.2.0/24"
  compartment_id              = "<your_compartment_OCID_here>"
  display_name                = "Staging subnet"
  prohibit_public_ip_on_vnic  = true
  dns_label                   = "stage"
}
```

Look at the Terraform plan to make sure it's correct:

```console
$ terraform plan
oci_core_subnet.stage: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_vcn.tf101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # oci_core_subnet.stage will be destroyed
  - resource "oci_core_subnet" "stage" {
      - cidr_block                 = "172.16.2.0/24" -> null
      - compartment_id             = "ocid1.compartment.oc1..<sanitized>" -> null
      - defined_tags               = {} -> null
      - dhcp_options_id            = "ocid1.dhcpoptions.oc1.phx.<sanitized>" -> null
      - display_name               = "Staging subnet" -> null
      - dns_label                  = "stage" -> null
      - freeform_tags              = {} -> null
      - id                         = "ocid1.subnet.oc1.phx.<sanitized>" -> null
      - prohibit_public_ip_on_vnic = true -> null
      - route_table_id             = "ocid1.routetable.oc1.phx.<sanitized>" -> null
      - security_list_ids          = [
          - "ocid1.securitylist.oc1.phx.<sanitized>",
        ] -> null
      - state                      = "AVAILABLE" -> null
      - subnet_domain_name         = "stage.example.oraclevcn.com" -> null
      - time_created               = "2021-02-09 20:22:37.634 +0000 UTC" -> null
      - vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>" -> null
      - virtual_router_ip          = "172.16.2.1" -> null
      - virtual_router_mac         = "00:11:...:22:33" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

> **NOTE:** It might feel redundant to keep looking at the output from `terraform plan` when the same output is given when you run `terraform apply` (before telling it to continue).  It's a good habit to always review proposed changes *before* making them.  By running plan and then apply, it forces you to closely look at what's going to happen to the environment (before it happens), giving you valuable time to stop or change what's going to take place.
{:.notice}

The minus sign (`-`) in front of the oci_core_subnet.stage is how Terraform indicates it will be removing the resource from the environment ("terminated" in OCI speak).  Proceed with applying it:

```console
$ terraform apply

# ...

Plan: 0 to add, 0 to change, 1 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_subnet.stage: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.stage: Destruction complete after 4s

Apply complete! Resources: 0 added, 0 changed, 1 destroyed.
```

With the `stage` Subnet removed, the environment is a bit cleaner.

### Deleting and Re-creating a Resource

We chose to permanently delete the `stage` Subnet.  In situations where a single resource should be destroyed and then re-created, there are a couple of options (rather than modify the Terraform code):

* `terraform destroy` command
* Taint a resource

The `terraform destroy -target=type.name` command is handy.  Instead of deleting the stage Subnet in your code and running `terraform apply`, you could have run `terraform destroy -target=oci_core_subnet.stage`.  Of course, if you don't remove (or comment out) the code for the stage Subnet, the next time you run `terraform apply`, it would want to re-create the stage Subnet.

When a resource is "tainted," it will be deleted and re-created.  The command `terraform taint type.name` is how a resource is tainted.  Here's an example of how the staging subnet could've been tainted: `terraform taint oci_core_subnet.stage` (followed by `terraform plan` and `terraform apply`).  The next time Terraform applies, it will delete and re-create the resource.  Look at the [Terraform taint command documentation](https://www.terraform.io/docs/cli/commands/taint.html) for more information.

## Removing All Resources

When it's time to fully terminate (destroy) an environment, Terraform has a single command that can accomplish this.

While this could be accomplished by removing resource definitions from the `main.tf` (Terraform code) file, that isn't ideal.  What if the environment needs to be provisioned in the future?  Keep the Terraform code and use the `terraform destroy` command to clean-up (terminate/destroy) the environment:

```console
$ terraform destroy

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # oci_core_subnet.dev will be destroyed
  - resource "oci_core_subnet" "dev" {
      - cidr_block                 = "172.16.0.0/24" -> null
      - compartment_id             = "ocid1.compartment.oc1..<sanitized>" -> null
      - defined_tags               = {} -> null
      - dhcp_options_id            = "ocid1.dhcpoptions.oc1.phx.<sanitized>" -> null
      - display_name               = "Dev subnet" -> null
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

  # oci_core_subnet.test will be destroyed
  - resource "oci_core_subnet" "test" {
      - cidr_block                 = "172.16.1.0/24" -> null
      - compartment_id             = "ocid1.compartment.oc1..<sanitized>" -> null
      - defined_tags               = {} -> null
      - dhcp_options_id            = "ocid1.dhcpoptions.oc1.phx.<sanitized>" -> null
      - display_name               = "Testing subnet" -> null
      - dns_label                  = "test" -> null
      - freeform_tags              = {} -> null
      - id                         = "ocid1.subnet.oc1.phx.<sanitized>" -> null
      - prohibit_public_ip_on_vnic = true -> null
      - route_table_id             = "ocid1.routetable.oc1.phx.<sanitized>" -> null
      - security_list_ids          = [
          - "ocid1.securitylist.oc1.phx.<sanitized>",
        ] -> null
      - state                      = "AVAILABLE" -> null
      - subnet_domain_name         = "test.example.oraclevcn.com" -> null
      - time_created               = "2021-02-09 20:22:38.097 +0000 UTC" -> null
      - vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>" -> null
      - virtual_router_ip          = "172.16.1.1" -> null
      - virtual_router_mac         = "00:11:...:22:33" -> null
    }

  # oci_core_vcn.tf_101 will be destroyed
  - resource "oci_core_vcn" "example" {
      - cidr_block               = "172.16.0.0/20" -> null
      - cidr_blocks              = [
          - "172.16.0.0/20",
        ] -> null
      - compartment_id           = "ocid1.compartment.oc1..<sanitized>" -> null
      - default_dhcp_options_id  = "ocid1.dhcpoptions.oc1.phx.<sanitized>" -> null
      - default_route_table_id   = "ocid1.routetable.oc1.phx.<sanitized>" -> null
      - default_security_list_id = "ocid1.securitylist.oc1.phx.<sanitized>" -> null
      - defined_tags             = {} -> null
      - display_name             = "tf_101" -> null
      - dns_label                = "tf101" -> null
      - freeform_tags            = {} -> null
      - id                       = "ocid1.vcn.oc1.phx.<sanitized>" -> null
      - state                    = "AVAILABLE" -> null
      - time_created             = "2021-02-09 20:20:05.841 +0000 UTC" -> null
      - vcn_domain_name          = "tf101.oraclevcn.com" -> null
    }

Plan: 0 to add, 0 to change, 3 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

oci_core_subnet.test: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.test: Destruction complete after 3s
oci_core_subnet.dev: Destruction complete after 4s
oci_core_vcn.tf_101: Destroying... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_vcn.tf_101: Destruction complete after 1s

Destroy complete! Resources: 3 destroyed.
```

Much like the apply command, the destroy command alerts you as to what it intends to do, prompting you to authorize it before continuing.

Things are now really cleaned up.  The Subnets and VCN is gone.  Speaking of being gone, did you notice how Terraform removed the OCI resources in the order of their dependency?  It didn't try to remove the VCN first (which would've failed because of the presence of the Subnets), but instead destroyed the two Subnets first, then destroyed the VCN.  That's part of the graph logic that Terraform applies to make managing your environment easy.  Pretty slick, right?

We've had a great time together, but this tutorial is coming to a close.  Before we part, make sure to check out some of the [resources offered in the next section](8-resources).
{% endslides %}
