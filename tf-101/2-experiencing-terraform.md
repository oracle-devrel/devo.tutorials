---
title: Experiencing Terraform
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
date: 2021-10-08 08:15
description: Experience the power of Terraform through a short project.
toc: true
author: tim-clegg
redirect_from: "/collections/tutorials/2-experiencing-terraform/"
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

This short project will let you experience the power of Terraform.

* Create some Terraform code files
* Learn how to examine what Terraform proposes be done
* Let Terraform create a VCN and Subnet
* Organize your Terraform code
* Get a taste of OCI Cloud Shell

## Prerequisites

You should have an Oracle Cloud Infrastructure (OCI) account setup.  [Click here]({{ site.urls.always_free }}) to create a new cloud account.

We'll be using the [OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm) in this tutorial, as it provides a great platform for quickly working with Terraform (as well as many other OCI interfaces and tools), having many of these tools pre-installed and ready-to-go.

[Click here](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellgettingstarted.htm) for directions on how to open up the OCI Cloud Shell.  You'll need to have this open during this particular portion of the Terraform 101 tutorial series.

## Setting up the project

Terraform is incredibly easy to use.  Here's what we're going to do in this lesson:

* Create a VCN
* Create a Subnet in the VCN

Follow the step-by-step directions, to see how easy/fast it is, then in subsequent lessons we'll go into greater detail around how to use Terraform.

> NOTE: All commands will be used within OCI Cloud Shell.  If you haven't opened it up yet, now's the time to [open your own Cloud Shell session](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellgettingstarted.htm)!
{:.notice}

## Setup the OCI provider

Create a new directory for this project:

```console
mkdir experiencing-tf
cd experiencing-tf
```

The `experiencing-tf` directory will have our Terraform files, as well as our Terraform state.  This will be our project directory.

Using your favorite editor (`nano`, `vi`, etc.) add the following to `provider.tf` (`nano provider.tf`):

```terraform
terraform {
  required_version = ">= 1.0.0"
}

provider "oci" {
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
}
```

Let's start by creating a VCN.  To do so, edit `vcn.tf` (`nano vcn.tf`, note that this file doesn't exist yet - so it'll be a new file according to your text editor) and place the following contents in it:

```terraform
resource oci_core_vcn "tf_101" {
  cidr_block     = "192.168.1.0/24"
  compartment_id = var.tenancy_ocid
  display_name   = "tf-101"
  dns_label      = "tf101"
}
```

The above tells Terraform that we want a VCN with a name of `tf-101`, using a CIDR block of `192.168.1.0/24`, deployed into the root (tenancy) compartment.

> NOTE: To keep things simple, this example uses the tenancy (root) compartment, which is often times locked down in many tenancies.  If you're using a tenancy with limited permissions (one in which you cannot deploy to the root compartment), you'll need to put in your compartment OCID in place of the `var.tenancy_ocid` above.  Something like `compartment_id = "PUT_YOUR_COMPARTMENT_OCID_HERE"` should do the trick for now!
{:.notice}

## Set up a subnet

Next we'll create a subnet within our VCN.  To do this, go ahead and add the following to a new file called `subnets.tf` (`nano subnets.tf`):

```terraform
resource oci_core_subnet "vlan1" {
  cidr_block      = "192.168.1.0/24"
  compartment_id  = var.tenancy_ocid
  display_name    = "vlan1"
  dns_label       = "vlan1"
  prohibit_public_ip_on_vnic = true
  vcn_id = oci_core_vcn.tf_101.id
}
```

This will tell Terraform to manage a Subnet that lives within the VCN we've previously defined, using the entire CIDR space.  We've prohibited the use of public IPs in this Subnet and have decided to give it the amazingly original name of `vlan1`.

Up to this point, we've referenced a couple of variables in our resource definitions above: `var.region` and `var.tenancy_ocid`.  We need to go ahead and define these in Terraform code.  To do so, edit `variables.tf` (`nano variables.tf`) and place the following in it:

```terraform
variable "tenancy_ocid" {
  type = string
}
variable "region" {
  type = string
}
```

## Set up an output

Now that our inputs are defined, let's go ahead and setup an output, which will be the status of the VCN.  To do this, modify `outputs.tf` (`nano outputs.tf`) and place the following in it:

```terraform
output "vcn_state" {
  description = "The state of the VCN."
  value       = oci_core_vcn.tf_101.state
}
```

Save the file and exit your text editor.  

The OCI Cloud Shell session is prepopulated with lots of good values that make life super simple.  We need to put this in a format that Terraform cac easily use.  The following commands will setup a few environment variables that Terraform will be using:

```console
declare -x TF_VAR_tenancy_ocid=`echo $OCI_TENANCY`
declare -x TF_VAR_region=`echo $OCI_REGION`
```

## Action!

Now it's time to see this all work!  Initialize Terraform by running:

```console
terraform init
```

It looks something like:

```console
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/oci...
- Installing hashicorp/oci v4.45.0...
- Installed hashicorp/oci v4.45.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
$ 
```

At this point Terraform is ready for us to give it directions on what OCI resources we want it to manage.  Let's look at the plan that Terraform proposes:

```console
$ terraform plan
```

The output will be something similar to the following:

```console
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # oci_core_subnet.vlan1 will be created
  + resource "oci_core_subnet" "vlan1" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "192.168.1.0/24"
      + compartment_id             = "ocid1.tenancy.oc1..<sanitized>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = "vlan1"
      + dns_label                  = "vlan1"
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

  # oci_core_vcn.tf_101 will be created
  + resource "oci_core_vcn" "tf_101" {
      + cidr_block               = "192.168.1.0/24"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.tenancy.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "tf-101"
      + dns_label                = "tf101"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_blocks          = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + vcn_state = (known after apply)

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply"
now.
$ 
```

What we're able to see here is that Terraform is proposing to create two new resources: a VCN and a Subnet.  Both of these are expected and things appear to be in order, so we'll go ahead and apply it (tell Terraform to make the changes), by running:

```console
$ terraform apply
```

We'll see something like what we saw for plan, but have a prompt asking if we'd like to continue:

```console
<snip>
Changes to Outputs:
  + vcn_state = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

Once we accept the proposed changes, we'll see something like:

```console
<snip>
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_vcn.tf_101: Creating...
oci_core_vcn.tf_101: Creation complete after 2s [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.vlan1: Creating...
oci_core_subnet.vlan1: Creation complete after 2s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

vcn_state = "AVAILABLE"
$ 
```

Wow, that was easy!  One command to set up multiple resources... terrific!  

## Cleaning Up

Since we're at the end of this short session, we want to clean up after ourselves.  Let's go ahead and remove the VCN and Subnet.  This could be multiple clicks on the OCI Console, however since we're using Terraform, one command is all we need to run:

```console
$ terraform destroy
```

You'll see something like the following:

```console
$ terraform destroy
oci_core_vcn.tf_101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.vlan1: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # oci_core_subnet.vlan1 will be destroyed
  - resource "oci_core_subnet" "vlan1" {
      - cidr_block                 = "192.168.1.0/24" -> null
      - compartment_id             = "ocid1.compartment.oc1..<sanitized>" -> null
      - defined_tags               = {
          - "Oracle-Tags.CreatedBy" = "<sanitized>"
          - "Oracle-Tags.CreatedOn" = "2021-09-30T19:44:47.597Z"
        } -> null
      - dhcp_options_id            = "ocid1.dhcpoptions.oc1.phx.<sanitized>" -> null
      - display_name               = "vlan1" -> null
      - dns_label                  = "vlan1" -> null
      - freeform_tags              = {} -> null
      - id                         = "ocid1.subnet.oc1.phx.<sanitized>" -> null
      - prohibit_internet_ingress  = true -> null
      - prohibit_public_ip_on_vnic = true -> null
      - route_table_id             = "ocid1.routetable.oc1.phx.<sanitized>" -> null
      - security_list_ids          = [
          - "ocid1.securitylist.oc1.phx.<sanitized>",
        ] -> null
      - state                      = "AVAILABLE" -> null
      - subnet_domain_name         = "vlan1.tf101.oraclevcn.com" -> null
      - time_created               = "2021-09-30 19:44:47.659 +0000 UTC" -> null
      - vcn_id                     = "ocid1.vcn.oc1.phx.<sanitized>" -> null
      - virtual_router_ip          = "192.168.1.1" -> null
      - virtual_router_mac         = "00:00:17:28:74:9C" -> null
    }

  # oci_core_vcn.tf_101 will be destroyed
  - resource "oci_core_vcn" "tf_101" {
      - cidr_block               = "192.168.1.0/24" -> null
      - cidr_blocks              = [
          - "192.168.1.0/24",
        ] -> null
      - compartment_id           = "ocid1.compartment.oc1..<sanitized>" -> null
      - default_dhcp_options_id  = "ocid1.dhcpoptions.oc1.phx.<saanitized>" -> null
      - default_route_table_id   = "ocid1.routetable.oc1.phx.<sanitized>" -> null
      - default_security_list_id = "ocid1.securitylist.oc1.phx.<sanitized>" -> null
      - defined_tags             = {
          - "Oracle-Tags.CreatedBy" = "<sanitized>"
          - "Oracle-Tags.CreatedOn" = "2021-09-30T19:44:46.481Z"
        } -> null
      - display_name             = "tf-101" -> null
      - dns_label                = "tf101" -> null
      - freeform_tags            = {} -> null
      - id                       = "ocid1.vcn.oc1.phx.<sanitized>" -> null
      - ipv6cidr_blocks          = [] -> null
      - is_ipv6enabled           = false -> null
      - state                    = "AVAILABLE" -> null
      - time_created             = "2021-09-30 19:44:46.736 +0000 UTC" -> null
      - vcn_domain_name          = "tf101.oraclevcn.com" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Changes to Outputs:
  - vcn_state = "AVAILABLE" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: 
```

After entering `yes` in the prompt, Terraform will destroy the resources for us:

```console
<snip>
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

oci_core_subnet.vlan1: Destroying... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.vlan1: Destruction complete after 1s
oci_core_vcn.tf_101: Destroying... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_vcn.tf_101: Destruction complete after 1s

Destroy complete! Resources: 2 destroyed.
$
```

## Summary

If this was your first time using Terraform, that was a *LOT* to take in!  It was worth it, as we got a lot done:

* Created five (5) Terraform code files that defined our inputs, outputs and resources we want Terraform to manage
* Learned how to examine what Terraform proposes be done (`terraform plan`)
* Let Terraform create a VCN and Subnet for us (very quickly)
* Fun facts: It took Terraform under 10 seconds to provision a VCN and Subnet (try it yourself by running `time terraform apply -auto-approve`) and under 7 seconds to destroy (try it yourself by running `time terraform destroy -auto-approve`) those same resources.  Try to beat that doing it by hand in the OCI Console!
* Organized our Terraform code into logical files (so it's easy to navigate the code)
* Got a taste for how handy and easy it is to use the OCI Cloud Shell

Hopefully this short tutorial gave you a glimpse into the basic flow around using Terraform and how powerful it can be.  This was a super simple example, but was a solid first start at using Terraform.  The [next lesson](3-understanding-terraform-basics.md) digs into some of the core concepts and components in a Terraform project.
{% endslides %}
