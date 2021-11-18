---
title: Understanding The Basics Of Terraform
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
date: 2021-10-14 08:13
description: Let's go through some of the foundational concepts you should understand
  when working with Terraform.
author: tim-clegg
published: true
redirect_from: "/collections/tutorials/3-understanding-terraform-basics/"
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

In our [first lesson](1-why-iac), we covered why you should care about IaC.  We also touched on just a few of the many tools in this space.  Finally, we've decided to narrow our focus down to Terraform.  The [last lesson](2-experiencing-terraform) took you through a really quick and simple scenario using Terraform.  It was short but powerful, and hopefully helped you understand a bit of why Terraform (and IaC) is so cool.  This lesson will take you through some of the basic concepts you should know to effectively work with Terraform.

## Major Terraform Components

In the IaC world, resources are defined using code.  Terraform follows a *declarative* language model, meaning that you tell it where you want to be after it executes and it figures out what's needed to get there. Terraform doesn't need to be told "do this, then do this, then finish with this", as is common with many procedural languages. You simply tell it where you want it to end and it'll map out the path.  Most of the time it's able to figure out the right steps.  Occasionally it'll need some help, but we'll talk a little about that in another tutorial.

Terraform has a couple of core components that you should know about:

* Terraform executable
* Terraform provider(s)
* Terraform code
* Terraform state

## Terraform executable

The Terraform executable can be easily downloaded and installed on many different platforms.  Check out the [Terraform downloads page](https://www.terraform.io/downloads.html) for the Terraform CLI binaries for different platforms.

If you're using Linux, it's possible that Terraform might exist in your favorite package manager (look at `yum install terraform` or `apt-get install terraform`). Oracle Linux makes it super simple to install Terraform (check out the [Oracle docs](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraforminstallation.htm) for more info).  Using Oracle Linux is super easy (just use Yum). If you're not using Oracle Linux, you'll likely need to configure your package manager (see [RHEL/Fedora Yum docs](https://www.terraform.io/docs/cli/install/yum.html) or [Debian/Ubuntu APT docs](https://www.terraform.io/docs/cli/install/apt.html)).

On MacOS, simply download the binary and place it somewhere in your path.  So long as `terraform -v` works from a terminal, you should be ready to go! You can also use [homebrew](https://brew.sh), which makes it as easy as `brew install terraform`.

There are many different commands that Terraform accepts.  Here are some of the more common ones frequently used:

`terraform init`
: This must be run at least once for a Terraform project.  This is when Terraform downloads any needed providers, sets up the state (if it doesn't already exist), etc.

`terraform plan`
: Prompts Terraform to do a dry run, to determine what it would do if it was to apply.  No changes are made.  It simply tells you what it thinks should be done.  It's a good idea to always run `terraform plan` and review the output (before applying), to make sure that you fully understand what Terraform is saying must be done.

`terraform apply`
: Changes are made with this command.  It'll by default show you the same output as `terraform plan`, asking you if you'd like to continue.  There are ways to short-circuit this and always apply, but when running Terraform by hand, it's a good idea to always review what things it plans to do (before it does them).

`terraform console`
: Gives you an interactive console where you can enter different Terraform commands. Particularly useful for building and testing logic in Terraform code.

## Terraform provider(s)

Providers allow Terraform to interact with different platforms.  This is what bridges the gap between the Terraform code and a given platform (such as OCI).  One or more providers can be used at any time.  The OCI provider translates the Terraform code to how Terraform needs to interact with the OCI API, for instance.  Many clouds have Terraform providers, allowing you to define resources that are specific to a cloud using a standard format, tool and language.

Check out [the OCI Terraform provider documentation](https://registry.terraform.io/providers/hashicorp/oci/latest/docs) for an idea of the different kinds of resources that can be managed with it.  We'll walk through a really simple example at the end of this tutorial, so don't sweat it if this seems a little overwhelming!  Hang in there and it'll be worth it (it'll come together).

You will need to tell Terraform about which providers you'll be using in your code.  Providers are typically referenced in `terraform` and `provider` blocks.

> **NOTE:** A block of Terraform code is something that's including multiple lines of code enclosed within an opening (`{`) and closing (`}`) curly brackets.
{:.notice}

Let's look at how to tell Terraform we want to use the OCI provider:

```terraform
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.39.0"
    }
  }
}

provider "oci" {
  region = var.region
  auth   = "InstancePrincipal"
}
```

The first `terraform` block is telling Terraform to download and include specific providers (those within the `required_providers` block).  In this case, we're including the `oci` provider, specifically version `4.39.0` or greater.

> **NOTE:** The `required_providers` portion of the `terraform` block is optional but nice to include as it allows you to constrain the version and source of a given provider.
{:.notice}

The OCI provider block contains information that's specific to the provider.  In this case, we're telling the OCI provider which region to use and asking it to authenticate against the OCI API using [Instance Principals](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm).

> **NOTE:** The `auth` line in the OCI provider block is optional. It's one way of authenticating (using [Instance Principals](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm)), but certainly not the only way.
{:.notice}

Although it's possible to manually download and install Terraform providers, by default Terraform will automatically download and install (manage) providers for you.  This is accomplished by running the `terraform init` command from the directory containing your Terraform code.

> **NOTE:** Managed Terraform services such as [OCI Resource Manager (ORM)](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/home.htm) do not require you to go through any Terraform initialization process.  This is managed for you by ORM.  This step is needed when running Terraform from your own computer (or server).
{:.notice}

## Terraform Code

Terraform uses a proprietary [configuration language](https://www.terraform.io/docs/language/index.html).  Like any language, it's reasonable to expect a slight learning curve when you're first starting out, but once you gain some familiarity and experience with it, expect it to grow on you.

It's highly recommended to at least skim the [Terraform configuration language documentation](https://www.terraform.io/docs/language/index.html), gaining some familiarity with the basic concepts, structural components, and functions available in the language.

> **NOTE:** Terraform has undergone some significant changes to the Terraform configuration language over the past several years.  If you see code that is written for Terraform v0.11 (or earlier), you'll likely need to update it to a more recent version.
{:.notice}

In the code, you'll likely define a combination of variables (user provided input), locals (local variables), outputs (values shown as output after running Terraform), providers, and resources.  Most all of the other code elements are engineered to support the management of resources.  This is really what gets changed in OCI (or another environment, depending on the providers you're using and the resources you're managing) when Terraform is run.  Whether declaring a single resource or iteratively creating many resources via a loop construct, resources are typically what we're trying to manage with Terraform.

## A Terraform Project

A typical Terraform project can be broken into familiar constructs typical to many applications:

  * Inputs
  * Outputs
  * Logic

### Inputs

Terraform receives input via the usage of variables.  Variables may be set via command-line parameters, static files or environment variables.  There are a lot of facets to mastering the usage of variables, so we'll cover these in greater detail in [another lesson](4-variables).  For now, know that each variable must be given a name (defined with a variable block) and value (set to a value), like the following simple example:

```terraform
variable "region" {}
```

The above variable example is the most simplistic variable definition. They can get more complex, though.  If you want to jump ahead, feel free to look ahead to the [lesson on variables](4-variables) and check out the [Terraform variable documentation]((https://www.terraform.io/docs/language/values/variables.html)).

Where should you place your variables (in which `.tf` file)?  Variables are most often defined in a file called `variables.tf`.  Pretty self-explanatory, right?  This isn't required, but is good form and common practice for all but really small projects.  Most of the time it's a good idea to make the filename specific to the type of resources defined in it.

To dig in deeper, check out the excellent [Terraform variables documentation](https://www.terraform.io/docs/language/values/variables.html).

### Outputs

There are times when Terraform needs to provide data about the environment back to the display.  For example, when a compute instance is deployed, a private IP address may be specified.  If it's not specified, OCI will pick an IP address for us (from the Subnet the instance is being deployed in).  Wouldn't it be nice to be able to see this private IP address?  Many different attributes are exported by Terraform resources, allowing you to easily examine them via the usage of outputs.

Outputs are technically called "output variables."  These are shown at the end of running `terraform apply` (running `terraform plan` won't show outputs).  Here's an example of an output:

```terraform
output "vcn_state" {
  description = "The state of the VCN."
  value       = oci_core_vcn.tf_101.state
}
```

Outputs can be defined in any Terraform code file (`*.tf`). However, it’s a good idea to get into the practice of separating Terraform code into logical files so the code base is easier to navigate.  It's recommended to use the file `outputs.tf` for this purpose (keeps it logical).

The value of an output can be any programmatic calculation supported in Terraform code.  See this at work with the following example:

```terraform
output "two_plus_two" {
  value       = 2+2
}
```

This is super simple - just adding two numbers together.  You can use many  [functions in Terraform](https://www.terraform.io/docs/language/functions/index.html); let your mind wander a bit around what you might be able to do.  String substitutions, merging, changes, calculating hashes, etc.  The world's your oyster!

Coercing outputs can be particularly valuable when using Terraform in automated pipelines as well as when running it manually (so users can see useful data).

### Logic

Terraform provides many different functions which allow you to embed logic and perform some rather complex computations.  Need to loop (iterate) through a list or map?  You're covered!  How about concatenating strings (or many other kind of string manipulations)?  Got it.  If-then-else logic?  Yep, it's there.  Need to do some CIDR calculations?  There are functions for that.  Check out the [Terraform functions](https://www.terraform.io/docs/language/functions/index.html), [Terraform conditional expressions](https://www.terraform.io/docs/language/expressions/conditionals.html) and [Terraform `for` expressions](https://www.terraform.io/docs/language/expressions/for.html) for more information.  It's well worth skimming through, even if just to gain some basic familiarity with some of what's available and possible.

## Terraform State

When interacting with an environment, there are three main components Terraform needs (in addition to the Terraform binary):

1. Terraform code
2. Terraform state
3. Environment being managed

Terraform uses a lot of intelligence to map out relationships between managed resources.  Many applications rely on a local database to store information needed by the application.  Terraform's no different, and is very transparent in how it manages its application content, storing what's needed in a local JSON file (by default).

The state is where Terraform caches a copy of what it knows about the environment.  Details about the managed resources are stored here, in verbose form.  Inputs (variable values) are also cached here.  State files should be carefully guarded as it's possible to have secrets or other sensitive data stored in them.  Even though a variable might be marked as sensitive, Terraform can store the contents in the state file.  Although it might not show via `terraform apply`, it might be there "in the open" in the state file.

When Terraform runs, it will update the state (with what actually exists in the environment being managed) and compare the state against the code.  Any deltas (variances between the code and state) will be marked as requiring a remediation (change that must be made to bring the current resource state to where the code is asking for it).

It's important to always use the latest copy of the state, as `terraform apply` might update the state file.  This is particularly important when sharing the management responsibilities for a single environment among multiple people.  Each environment has a *single* state file.  If the state file becomes corrupted or out-of-sync, Terraform can do weird and unexpected things.  It's really not good --- carefully guard your state file!

The state is stored locally within the project directory by default (`terraform.tfstate`).  Backends may be defined which would tell Terraform to store the state in a different location.  Many different kinds of backends are supported - check out the [backend documentation](https://www.terraform.io/docs/language/settings/backends/index.html) for more information.  For this tutorial, we'll be sticking with keeping the state local.  For production deployments, many customers will find the use of [OCI Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/home.htm) of benefit, as it maintains the Terraform state file for each stack automatically.  Others might leverage OCI Object Storage as a backend, while some might prefer using git.

## Moving Forward

Now that you understand some of the basic components used in a Terraform project, let's dive into [variables in the next lesson](4-variables).
{% endslides %}
