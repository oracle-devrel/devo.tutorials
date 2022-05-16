---
title: Understanding The Basics Of Terraform
parent:
- tutorials
- tf-101
sidebar: series
tags:
- open-source
- terraform
- iac
- devops
- get-started
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
mrm: WWMK211117P00010
redirect: https://developer.oracle.com/tutorials/tf-101/3-understanding-terraform-basics/
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

In our [first lesson](1-why-iac), we covered why you should care about Infrastructure as Code (IaC).  We also touched on a few of the many tools in this space, and finally, we decided to narrow our focus down to Terraform.  

The [last lesson](2-experiencing-terraform) took you through a really quick and simple scenario using Terraform, setting up a virtual cloud network (VCN) and a subnet.  It was short but powerful, and hopefully helped you understand a bit of why Terraform (and IaC) is such a great tool.  
This lesson will dive a little deeper and take you through some of the basic concepts you'll need to effectively work with Terraform.

Key topics covered in this tutorial:

* Learning about some of the major Terraform components (executables, providers, code, and states)
* Discovering some of the basic Terraform commands (*init*, *plan*, *apply*, and *console*)
* Setting up a Terraform project (inputs, outputs, and logic)

For additional information, see:

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)
* [Getting started with Terraform](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformgettingstarted.htm)
* [Getting started with OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm)

## Prerequisites

To successfully complete this tutorial, you will need to have the following:

* An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* Terraform CLI
* [OCI Cloud Shell]((https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm))

## Major Terraform Components

In the IaC world, resources are defined using code.  Terraform follows a *declarative* language model, meaning that you tell it where you want to be after it executes and it figures out what's needed to get there. Terraform doesn't need to be told "do this, then that, then finish with this," as is common with many procedural languages. You simply tell it where you want it to end up and it'll map out the path to get there.  Most of the time, Terraform is able to figure out the right steps on its own.  Occasionally, it'll need some help, but we'll talk a little more about that in a later tutorial in this series.

Terraform has several core components that you should become familiar with:

* [Terraform executable](#terraform-executable)
* [Terraform providers](#terraform-providers)
* [Terraform code](#terraform-code)
* [Terraform state](#terraform-state)

### Terraform executable

The Terraform executable can be easily downloaded and installed on a variety of different platforms.  Check out [Terraform's download page](https://www.terraform.io/downloads.html) to locate the Terraform CLI binaries for your system.

#### Linux

If you're using Linux, it's possible that Terraform might exist in your favorite package manager (look at `yum install terraform` or `apt-get install terraform`). Oracle Linux makes it simple and painless to [install Terraform](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraforminstallation.htm). If you're Using Oracle Linux, just use Yum for the best experience.  

However, if you're not using Oracle Linux, you'll likely need to configure your package manager (see: [RHEL/Fedora Yum docs](https://www.terraform.io/docs/cli/install/yum.html) or [Debian/Ubuntu APT docs](https://www.terraform.io/docs/cli/install/apt.html)).

#### MacOS

In MacOS, simply download the binary and place it somewhere in your path.  To verify that your system can locate the executable and confirm that Terraform is up and running, just run `terraform -v` in a terminal window. If it echoes the current Terraform version number, you should be good to go!  

If you like, you can also use [Homebrew](https://brew.sh) to get things going with Terraform. All you need to do is run `brew install terraform` in a terminal window.

### Terraform providers

Providers allow Terraform to interact with different platforms.  This is the component that bridges the gap between the Terraform code and a specific platform such as OCI. For instance, the OCI provider translates the Terraform code to a form Terraform requires to interact with the OCI API directly.  

However, Terraform isn't limited to a single provider. At any given time, one or more providers can be in use. Many clouds have Terraform providers, allowing you to define resources that are specific to a cloud using a standard format, tool, and language.

When you have a moment, take a look at [the OCI Terraform provider documentation](https://registry.terraform.io/providers/hashicorp/oci/latest/docs) to get a better sense of the different kinds of resources that can be managed with it.  At the end of this tutorial, we'll walk through a really simple example, so don't sweat the details now.  Just hang in there and it'll all come together!

#### Getting started with providers

In order to start using providers with Terraform, you'll first need to tell Terraform exactly which providers you'll be using in your code.  Providers are typically referenced in `terraform` and `provider` blocks.

> **NOTE:** A block of Terraform code is anything enclosed within curly brackets.
{:.notice}

#### Set up Terraform to use the OCI provider

Let's look at an example of how to tell Terraform we want to use the OCI provider:

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

Zooming in a little closer, the first `terraform` block instructs Terraform to download and include specific providers (those within the `required_providers` block).  In this case, we're including the `oci` provider, specifically version `4.39.0` or greater.

> **NOTE:** The `required_providers` portion of the `terraform` block is optional, but it's nice to have in there since it allows you to constrain the version and source of a given provider.
{:.notice}

Next up, the OCI provider block contains information that's specific to the provider.  In this case, we're telling the OCI provider which region to use and asking it to authenticate against the OCI API using [Instance Principals](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm).

> **NOTE:** The `auth` line in the OCI provider block is **optional**. It's one way of authenticating (using [Instance Principals](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm)), but certainly not the only way.
{:.notice}

#### Managing Terraform providers

Although it's possible to manually download and install Terraform providers, by default, Terraform will automatically download and install (manage) providers for you.  This is accomplished by running the `terraform init` command from the directory containing your Terraform code.

> **NOTE:** Managed Terraform services such as [OCI Resource Manager (ORM)](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/home.htm) do not require you to go through any Terraform initialization process.  This is managed for you by ORM.  This step is needed when running Terraform from your own computer (or server).
{:.notice}

## Terraform code

Terraform uses a proprietary [configuration language](https://www.terraform.io/docs/language/index.html). Like any language, it's reasonable to expect a slight learning curve when you're first starting out, but it's ease and versatility will grow on you as you gain some familiarity with it.

It's highly recommended that you at least skim the [Terraform configuration language documentation](https://www.terraform.io/docs/language/index.html) to get some familiarity with its basic concepts, structural components, and functions.

> **NOTE:** Terraform's configuration language has undergone some significant changes over the past several years.  If you come across code that was written for Terraform v0.11 (or earlier), you'll likely need to update it to a more recent version.
{:.notice}

Within the code, you'll likely define a combination of variables (user-provided input), locals (local variables), outputs (values shown as output after running Terraform), providers, and resources.  Most of the other code elements are engineered to support the management of resources.  These remaining elements are really the parts that get changed in OCI (or another environment, depending on the providers you're using and the resources you're managing) when Terraform is run. When you get down to it, resources are the beating heart of Terraform.  Whether you're declaring a single resource or many, resources are typically what we're trying to manage with Terraform.

## Terraform commands

Terraform has a broad set of capabilities, and as you might imagine, there are many different commands that it accepts.  Here are some of the most common ones that you'll find yourself using:

`terraform init`
: **This must be run at least once for a Terraform project.**  During the init process, Terraform downloads any needed providers, sets up the state (if it doesn't already exist), and performs any other necessary start-up tasks.

`terraform plan`
: Prompts Terraform to do a dry run, non-destructively determining what it would do if it was to apply the configuration settings.  Terraform simply tells you what it thinks *should* be done and lets you review the outcomes without any changes being made.  
It's always a good idea to run `terraform plan` and review the output before applying. This way you can make sure that you fully understand what Terraform is intending to do.

`terraform apply`
: **Changes are made with this command.**  By default, it will show you the same output as `terraform plan`, but will additionally prompt you to enact the proposed changes.  
There are ways you can short-circuit this process and automatically accept all of the changes, but it's generally a good idea to review the recommendations before applying them, especially when you're running Terraform manually.

`terraform console`
: Gives you an interactive console where you can enter different Terraform commands. This is particularly useful for building and testing logic in Terraform code.

## A Terraform project

In this section, we'll take a look at the various parts of a Terraform project. In general, a typical Terraform project can be broken down into familiar constructs common to many other applications:

* Inputs
* Outputs
* Logic

### Inputs

Terraform receives input through variables.  Variables may be set via command-line parameters, static files, or environment variables.  There are a lot of facets to mastering the usage of variables, so we'll cover these in greater detail in a [separate lesson](4-variables).  For now, know that each variable must be given a unique name and value, like in the following example:

```terraform
variable "region" {}
```

The above example is the most basic variable definition. They definitely can get more complex, though.  If you want to jump ahead, feel free to look ahead to the [lesson on variables](4-variables) and check out the [Terraform variable documentation]((https://www.terraform.io/docs/language/values/variables.html)).

#### Variable definitions file

At this point, you're probably wondering where you should place your variables.  Most often, variables are defined in a file called `variables.tf`.  Pretty straightforward, right?  This isn't required, but it's good form and common practice for everything but really small projects.  Most of the time, it's a good idea to make the filename specific to the type of resources defined in it.

To dig in deeper, check out the excellent [Terraform variables documentation](https://www.terraform.io/docs/language/values/variables.html).

### Outputs

There are times when Terraform needs to direct data about the environment back to the display. For example, when a compute instance is deployed, a private IP address may be specified.  If it's not specified, OCI will pick an IP address for us from the subnet the instance is being deployed in.  Wouldn't it be nice to be able to see this private IP address? Outputs provide a way to make that information visible to you. Many different attributes are exported by Terraform resources, allowing you to easily examine them through the use of outputs.

In Terraform, outputs are technically referred to as "output variables."  The current values of these variables are included at the end of the output for the `terraform apply` command. Note that these values are not displayed when you run `terraform plan`.  

Let's take a look at an example of an output:

```terraform
output "vcn_state" {
  description = "The state of the VCN."
  value       = oci_core_vcn.tf_101.state
}
```

#### Outputs definition file

While outputs can be defined in any Terraform code file, it’s best to get into the practice of separating Terraform code into logical files so the code base is easier to navigate.  For this purpose, it's recommended that you use the `outputs.tf` file for these definitions.

#### Terraform functions as output definitions

Additionally, the value of an output variable doesn't have to be static, it can be any programmatic calculation supported in Terraform code. We can see this at work with the following example:

```terraform
output "two_plus_two" {
  value       = 2+2
}
```

While this is a trivial example, you can use many [functions in Terraform](https://www.terraform.io/docs/language/functions/index.html).  String substitutions, merging, changes, calculating hashes, etc.  The world's your oyster!

With this added functionality, accessing outputs can be particularly useful when you're using Terraform as part of an automated pipelines. It can also be an invaluable resource to users running it manually.

### Logic

Another aspect of Terraform's versatility is its ability to provide a wealth of functions to embed logic and perform complex computations.  Need to iterate through a list or map?  You're covered!  How about concatenating strings (or string manipulations in general)?  Got it.  If-then-else logic?  Yep, it's in there.  Need to do some CIDR calculations?  There are functions for that too.  

If you'd like to learn more, take a look at these resources on [Terraform functions](https://www.terraform.io/docs/language/functions/index.html), [Terraform conditional expressions](https://www.terraform.io/docs/language/expressions/conditionals.html), and the [Terraform `for` expressions](https://www.terraform.io/docs/language/expressions/for.html). It's well worth checking out, even if you're just trying to get some familiarity with what's available and possible.

## Terraform State

When interacting with an environment, there are three main components Terraform needs (in addition to the Terraform binary):

1. Terraform code
2. Environment being managed
3. Terraform state

The first two components (code and environment) are topics you should already be familiar with. What's left to cover is how Terraform use these resources to develop an accurate picture of available resources.

Terraform uses a lot of intelligence to map out relationships between managed resources.  Many applications rely on a local database to store information needed by the application.  Terraform's no different, and is very transparent in how it manages its application content, by default storing what's needed in a local JSON file.

The *state* is where Terraform caches a copy of what it knows about the environment.  Details about the managed resources are stored there in verbose form, along with Inputs (variable values).  

> **NOTE:** State files should be carefully guarded as it's possible to have secrets or other sensitive data stored in them.  Even though a variable might be marked as sensitive, Terraform can still store its contents in the state file.  Although it might not show via `terraform apply`, it might be right there in plain text in the state file. {:.warn}

### Updates and Deltas

When Terraform runs, it will update the state with what actually exists in the managed environment and compare that state against the code.  Any deltas (variances between the code and state) will be marked as requiring a remediation (changes that must be made to bring the current resource state in line with the code is asking for it).

### Keeping the Terraform state in sync

It's important to always use the latest copy of the state, as `terraform apply` might update the state file.  This is particularly important when sharing the management responsibilities for a single environment among multiple people.  Each environment has a *single* state file.  If the state file becomes corrupted or out of sync, Terraform can do weird and unexpected things.  So, carefully guard your state file!

### Where the Terraform state lives

By default, the state (`terraform.tfstate`) is stored locally within the project directory.  But, keep in mind that there are cases where backends may be defined in such a way that Terraform is required to store the state in a different location.  

For the remaining parts of the tutorial, though, we'll stick to keeping the state local.  

### Backends - common use scenarios

For production deployments, many Terraform users find the [OCI Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/home.htm) beneficial, as it maintains the Terraform state file for each stack automatically.  However, you might find that [OCI Object Storage](https://www.oracle.com/cloud/storage/object-storage/) works better for you as a backend. Or, you might prefer using git. Whichever way you prefer, Terraform has you covered.

Terraform supports many different kinds of backends are supported. For a full list, check out the [backend documentation](https://www.terraform.io/docs/language/settings/backends/index.html) for more information.  

## What's next

Now that you understand some of the basic components used in a Terraform project, let's dive into [variables in the next lesson](4-variables).

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

{% endslides %}
