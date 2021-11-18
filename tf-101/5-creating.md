---
title: Creating Resources with Terraform
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
date: 2021-09-30 17:50
description: How to create resources using Terraform.
toc: true
author: tim-clegg
redirect_from: "/collections/tutorials/5-creating/"
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

The next few lessons in this tutorial will take you through an adventure where resources are created, modified, and then finally destroyed using Terraform.  While you got a little taste for this in the [Experiencing Terraform lesson](2-experiencing-terraform.md), we'll cover the topics in greater detail here, pointing out more details along the way.

Let's start using Terraform on Oracle Cloud Infrastructure (OCI) by deploying a Virtual Cloud Network (VCN), a foundational OCI resource in which you can deploy other OCI resources to.

## Prerequisites

You should have an Oracle Cloud Infrastructure (OCI) account setup.  [Click here]({{ site.urls.alwaysfree }}) to create a new cloud account.

We'll be using the [OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm) in this tutorial, as it provides a great platform for quickly working with Terraform (as well as many other OCI interfaces and tools), having many of these pre-installed and ready-to-go.

## Terraform code

Terraform describes the resources it manages via Terraform code (also sometimes called the Terraform configuration).  These are plain-text files with a `.tf` extension.  All of the `.tf` files for a given project reside in a single directory.  When Terraform is run, it'll read the `.tf` files in the current directory.  Each Terraform project should have its own directory.

This gives you a great deal of flexibility as to how you structure your Terraform code.  You could place all of your code in a single file, or multiple files.  When a single file is used, usually it's called `main.tf`.  This is fine for small projects, but can be a bit difficult and tedious to navigate in large environments with many resources.

When spreading the code across many different files, resources are usually grouped in a logical manner.  This could be by an arbitrary category of resources, though one favorite technique is to utilize a file name that shares the resource name and place all of the given type of resources in it.  For example, all compartments could be defined in `compartments.tf`, all Security Lists be defined in `security_lists.tf`, etc.  A key takeaway here is to think about your environment and try to identify a logical way to represent the code itself.  It should be intuitive and fairly easy to navigate (find resources within the project).

## Start a new project

Since this will be a new project, we'll start off by creating a new directory for this project:

```console
cd ~
mkdir tf-101
cd tf-101
```

For simplicity, we'll use just a single file called `main.tf`.  This isn't recommended beyond a super simple environment, but that's what we'll be doing now, so will work just fine.

While Terraform doesn't require any specific filename to be used for its code (beyond having a `.tf` or `.tfvars` extension), it’s common to see `main.tf` used when there are only a few resources.  For any non-trivial environment (often with many resources), different files will be used for different types or groups of resources, which makes it easier to navigate and manage the environment.  We took the approach of separating resources into their own files in the [Experiencing Terraform tutorial](2-experiencing-terraform.md).

From within your Cloud Shell session, edit `main.tf` (which will also create it, as it doesn't yet exist in this new directory):

```console
nano main.tf
```

> **NOTE:** `nano` is being used as the text editor in this tutorial as it's a simple editor to use, but feel free to use `vi`, `vim`, or your favorite editor instead!
{:.notice}

Place the following within `main.tf`:

```terraform
terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }
  }
}

provider "oci" {
region           = "us-phoenix-1"
}

resource "oci_core_vcn" "tf_101" {
  dns_label             = "tf101"
  cidr_block            = "172.16.0.0/20"
  compartment_id        = "<your_compartment_OCID_here>"
  display_name          = "tf_101"
}
```

Make sure to update the `compartment_id` attributes to values you would like to use.  For the most basic implementation, use your tenancy OCID (to get it, follow the directions found in the [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)).

In the above sample, the provider region is configured to use `us-phoenix-1`.  Update this to the OCI region you want to deploy the VCN to.  You can find a list of available OCI regions in the [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm).

Let's pick apart what we've just done.

### Terraform block

Terraform is built to be extensible and modular, providing a single tool for managing many different platforms.  Providers increase the flexibility and power of Terraform, allowing Terraform to adapt to many different platforms that might be managed by Terraform.

A provider defines a Terraform interface that is used to manage a given platform, eliminating the need for you to interact with the platform API directly.  Providers translate between the Terraform interface and the underlying platform API.

The `terraform {}` block tells Terraform which provider(s) to download from the [Terraform Registry](https://registry.terraform.io/).  In this case, Terraform is being instructed to download the OCI provider (`hashicorp/oci`, which is short for `registry.terraform.io/hashicorp/oci`).  Terraform by default uses the [public Terraform Registry](https://registry.terraform.io/), while also supporting the use of local (private) registries (something we won't be going into in this tutorial series).

The version is not required, but is a best practice to include, as functionality might differ from one provider version to another.  See the [Terraform provider documentation](https://www.terraform.io/docs/language/providers/requirements.html) for more information.

### Provider

Terraform uses this configuration to locate the OCI provider from the [Terraform Registry](https://registry.terraform.io/providers/hashicorp/oci/latest). The provider uses API Key --- the default method --- to authenticate to OCI.  Refer to the [OCI provider documentation](https://registry.terraform.io/providers/hashicorp/oci/latest/docs#authentication) for additional authentication methods.

As mentioned previously, make sure that you specify the correct region you wish to deploy resources into.  This example is using the `us-phoenix-1` region, however you might need to modify this for your needs.  See the [OCI regions documentation](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm) for more information.

### Resource definition

A Virtual Cloud Network (VCN) is an OCI resource that is required by many other OCI services.  It’s a core, foundational resource in many OCI cloud environments, providing a logical network definition.  Because it’s needed before you can deploy Subnets, Compute Instances, Load Balancers, etc. you'll start with creating a VCN.  As a bonus, VCNs don’t cost a penny in OCI, so this minimizes your chances of incurring charges as you experiment with Terraform on OCI.

To manage the VCN, the [oci_core_vcn Terraform resource](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_vcn) is used.  The example configuration creates a `oci_core_vcn` resource named `tf_101`, in the compartment you provide (you'll need to make sure to use your compartment OCID), with a CIDR block of `172.16.0.0/20`, a DNS label of `tf101` and a `display_name` of `tf_101`.  Note that the Terraform resource name does not need to match the OCI display name - however it's a good idea to keep them the same, so that no matter what interface (API, OCI Console, Terraform, etc.) you're dealing with the same familiar name(s).

Make sure to set the the `compartment_id` value to the OCID of the compartment you wish to use!

## Setting up OCI Authentication

If we were using Terraform outside of OCI Cloud Shell, we'd need to worry about how Terraform will authenticate with the OCI API.  By running it inside of Cloud Shell, we don't need to worry about these details - it'll be authenticated automatically for us!

## Initialize configuration

Terraform needs different files to be able to be able to properly function reliably.  This is largely hidden out of view so that you don’t need to be mired down in the nitty-gritty details.  It’s still a good idea to have a high-level idea of what’s going on, so let's touch on a few things that Terraform needs.

Terraform doesn’t ship with any providers, so one of the first things that Terraform does is to examine any referenced providers and then download them as needed.  In this case, we've told Terraform to use the OCI Terraform provider, but it doesn’t have this provider – yet.  This is taken care of during the Terraform initialization process.

Terraform uses a state file to cache the state of resources.  It compares the state file against the Terraform code base (what you want implemented) and what’s actually configured in OCI.   Looking at the differences between the three sources, Terraform maps out a plan of attack around how to get the as-built (what exists in OCI) to what you want (what’s in your code).  The Terraform initialization process checks for a state file.  If it does not find one, it goes ahead and creates it.

Let's go ahead and initialize Terraform now for this project:

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

Terraform downloaded the OCI provider and created a new state file for the environment.

## Format and validate the configuration

When you first created the `main.tf` Terraform file, it was just a plain-text file.  Terraform code is just plain text!  It’s easy to create and manage Terraform code from virtually anywhere.

Most languages have text formatting requirements.  Though Terraform is pretty lenient around many formatting preferences, it's best to keep your code consistently formatted - particularly the line indentations.  A good text editor can help minimize this burden, but it’s still something that can be a challenge to manage (especially when working with a team of developers).

Here's what your provider section looks like:

```terraform
provider "oci" {
region           = "us-phoenix-1"
}
```

Notice how the region attribute isn’t nicely indented?  This could be modified by hand, but instead let's use Terraform’s built-in formatting command to clean-up the code:

```console
$ terraform fmt
main.tf
```

Look at the `main.tf` file now.  See how it's nicely indented now?

```console
$ cat main.tf

# ...

provider "oci" {
  region           = "us-phoenix-1"
}

# ...
```

Although there are plenty of ways to programmatically generate Terraform code, Terraform code is often created and managed by people.  People make mistakes, which can be disastrous.  An easy way to look for egregious Terraform code syntax violations is to use the validation built into Terraform.  To see this in action, run `terraform validate`.

```console
$ terraform validate
Success! The configuration is valid.
```

This will tell you about syntax errors in your Terraform code.  Keep in mind if you do something silly like using the wrong CIDR, incorrect name, etc. this validation won’t help you.  Terraform validation will have no idea that you’ve made a mistake like that... but it is a great way to lint the Terraform code, looking for bad syntax.  It’s another check in your release process that’s worth having in your release process (ideally using automated pipelines).

## View Terraform plan

Terraform has what it needs (OCI provider, state file, etc.), your code looks nicely formatted and you have a high level of confidence that your code is "good".  There’s one more step you can take to safeguard your work.  Ask Terraform what it thinks should be done to deploy the environment.  This is accomplished by running Terraform plan:

```console
$ terraform plan

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # oci_core_vcn.example will be created
  + resource "oci_core_vcn" "tf101" {
      + cidr_block               = "172.16.0.0/20"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "tf101"
      + dns_label                = "tf101"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_block           = (known after apply)
      + ipv6public_cidr_block    = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

$
```

Looking at the output, Terraform provides exactly what it proposes be done based on the current state of the OCI tenancy and the Terraform code you’ve provided.

The `+` means it’ll be adding a VCN resource, which is we expect to see!  While it seems like a bit much for this simple example (creating one VCN), it’s a good habit to get into checking what Terraform proposes be done *before* it makes any changes.

## Create infrastructure

Run `terraform apply` to create the VCN you defined in `main.tf`:

```console
$ terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # oci_core_vcn.example will be created
  + resource "oci_core_vcn" "tf101" {
      + cidr_block               = "172.16.0.0/20"
      + cidr_blocks              = (known after apply)
      + compartment_id           = "ocid1.compartment.oc1..<sanitized>"
      + default_dhcp_options_id  = (known after apply)
      + default_route_table_id   = (known after apply)
      + default_security_list_id = (known after apply)
      + defined_tags             = (known after apply)
      + display_name             = "tf101"
      + dns_label                = "tf101"
      + freeform_tags            = (known after apply)
      + id                       = (known after apply)
      + ipv6cidr_block           = (known after apply)
      + ipv6public_cidr_block    = (known after apply)
      + is_ipv6enabled           = (known after apply)
      + state                    = (known after apply)
      + time_created             = (known after apply)
      + vcn_domain_name          = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Terraform will prompt you before creating the infrastructure.  Type `yes` to confirm.

```console
# ...

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_vcn.example: Creating...
oci_core_vcn.example: Creation complete after 5s [id=ocid1.vcn.oc1.phx.<sanitized>]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Terraform shows essentially what we just saw when running `terraform plan`, plus it prompts you as to whether you want to proceed or not (give you a chance to have a final review before making the changes).

Voila!  That’s it.  With no errors given, everything deployed successfully.

### Looking at the State

Terraform tracks the state of each resource in the state file, including attributes that weren't defined in the Terraform configuration. Run `terraform show` to view your VCN's state.

```console
$ terraform show
# oci_core_vcn.example:
resource "oci_core_vcn" "tf101" {
    cidr_block               = "172.16.0.0/20"
    cidr_blocks              = [
        "172.16.0.0/20",
    ]
    compartment_id           = "ocid1.compartment.oc1..<sanitized>"
    default_dhcp_options_id  = "ocid1.dhcpoptions.oc1.phx.<sanitized>"
    default_route_table_id   = "ocid1.routetable.oc1.phx.<sanitized>"
    default_security_list_id = "ocid1.securitylist.oc1.phx.<sanitized>"
    defined_tags             = {}
    display_name             = "tf101"
    dns_label                = "tf101"
    freeform_tags            = {}
    id                       = "ocid1.vcn.oc1.phx.<sanitized>"
    state                    = "AVAILABLE"
    time_created             = "2021-02-09 00:08:46.373 +0000 UTC"
    vcn_domain_name          = "tf101.oraclevcn.com"
}
$
```

There's more info shown here than we'd specified in the Terraform code.  For example, OCI assigns an OCI Identifier (OCID) to a VCN when it’s created.  The VCN OCID appears in your state file as the `id` attribute, even though you did not define it in your configuration.

Terraform provides some mechanisms to add or remove elements in the state file, but it should not be modified directly.

## Troubleshooting

If `terraform validate` was successful and your apply still failed, you may be encountering a common error.  Refer to the following troubleshooting steps to resolve your issue.

### Invalid Region

If you're see the following error when you run `terraform apply`, you may have used an invalid (non-existent) region name.

```console
oci_core_vcn.tf_101: Creating...
Error: Post https://iaas.us-does-not-exist-1.oraclecloud.com/20160918/vcns: x509: certificate signed by unknown authority
  on main.tf line 18, in resource "oci_core_vcn" "tf_101":
  18: resource "oci_core_vcn" "tf_101" {
```

Please verify you are using a valid region. You can find a list of available OCI regions in the [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm).

### Unsubscribed Region

The following error might occur if you're trying to use a valid region, but one that your tenancy is not subscribed to.

```console
$ terraform apply

# ...

oci_core_vcn.tf_101: Creating...

Error: Service error:NotAuthenticated. The required information to complete authentication was not provided or was incorrect.. http status code: 401. Opc request id: <sanitized>, The service for this resource encountered an error. Please contact support for help with that service

  on main.tf line 18, in resource "oci_core_vcn" "tf_101":
  18: resource "oci_core_vcn" "tf_101" {
```

You aren’t told that it’s an invalid region. However, OCI is unable to authenticate you properly (because you’re trying to talk to a region that you're not subscribed to).

### Bad Resource Attribute(s)

This scenario might occur when trying to set an attribute to an invalid value.

```console
$ terraform apply

# ...

oci_core_vcn.tf_101: Creating...

Error: Service error:InvalidParameter. The requested CIDR 172.16.300.0/20 is invalid: unable to parse.. http status code: 400. Opc request id: <sanitized>

  on main.tf line 18, in resource "oci_core_vcn" "tf_101":
  18: resource "oci_core_vcn" "tf_101" {
```

It caught the problem and returned back a meaningful message!  Notice how the plan (portion before saying yes) didn’t catch this?  It’s possible to have an invalid attribute value being set, but to not have it get caught until it's applied (planning might not be of help here).

## Next Steps

You've had a chance to look at how to create new OCI resources with Terraform.  Next up you’ll learn about how to modify OCI infrastructure using Terraform.

### Helpful Resources

- [Terraform OCI Provider Documentation](https://registry.terraform.io/providers/hashicorp/oci/latest/docs)
- [Official OCI Terraform Documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm)
- [Terraform Registry – OCI Modules](https://registry.terraform.io/browse/modules?provider=oci)
- [Oracle (Terraform) Quick Start](https://github.com/oracle-quickstart/)
- [Oracle Terraform Modules (GitHub)](https://github.com/oracle-terraform-modules/)
{% endslides %}
