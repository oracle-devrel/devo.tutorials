---
title: Terraform Variables
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
date: 2021-10-14 12:00
description: Learn about how variables are used in Terraform.
toc: true
author: tim-clegg
published: true
redirect_from: "/collections/tutorials/4-variables/"
---
{% slides %}
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

This lesson will take a deeper look at Terraform variabales.  You've already had a little bit of exposure to them in the [Experiencing Terraform](2-experiencing-terraform) tutorial, as well as a brief summary in the [Understanding Terraform Concepts](3-understanding-terraform) tutorial.  Let's dive in and take a deeper look at what these are and how they're used.

## Why use variables?

Variables provide a way to easily decouple a value and its reference from your Terraform code.  A topology may be defined, but the specifics are given programmatically (or manually).  Writing parameterized Terraform code (using variables for many of the customizable values), means that as an environment changes new values for the variables may be provided without requiring any modification to the underlying Terraform code.

Here are some common use-cases for parameterizing code:

*	Multiple deployments of the same topology.  This could be for deploying separate development, staging and production environments that share identical topologies (but have unique names, compartments, CIDR blocks, etc.).
*	Passing secret/sensitive data in via variables.  Rather than hard-coding credentials, keys and other sensitive data in the Terraform code, this can be passed via variables.
*	Writing extensible modules in Terraform, where variables are used as inputs to the module, determining its behavior and/or setting resource attributes.

> **Warning:** NEVER commit secrets, credentials, keys and any other sensitive data to a git repo!
{:.alert}

## Types of variables

There are two kinds of variables:

* Input variables (variables)
* Local values (locals)

### Input variables (variables)

Most Terraform projects use variables in one way or another.  Variables are very common, and for good reason.  Variables are accessible within the entire project (or module, if you're building projects made of one or more modules).

### Local values (locals)

There's another kind of variable called a local variable (aka locals) which is not accessible to your entire project, but is limited to the context of a single Terraform file.  This means that if you define a local variable in a particular Terraform file, it will only be available to code within that same file (but not to code in other Terraform files).

## Getting the contents of a variable

To use a variable, prepend `var.` at the beginning of the variable name.  Take for example the `var.tenancy_ocid` used in the following VCN resource block:

```terraform
resource oci_core_vcn tf_101 {
  cidr_block     = "192.168.1.0/24"
  compartment_id = var.tenancy_ocid
  display_name   = "tf-101"
  dns_label      = "tf101"
}
```

If this looks familiar, it should - it's borrowed from the [Experiencing Terraform](2-experiencing-terraform) tutorial!  This is how the `tenancy_ocid` variable is referenced (read and used).

### Getting the contents of a local

To use a local (variable), simply prepend the local variable name with `local`.  Here's an example:

```terraform
resource oci_core_vcn tf_101 {
  cidr_block     = local.cidr
  compartment_id = var.tenancy_ocid
  display_name   = "tf-101"
  dns_label      = "tf101"
}
```

The above example is setting the `cidr_block` attribute to whatever is in the `cidr` local.

## Setting variable values

There are multiple ways to set the values of a variable.  Terraform uses the following order of precedence when setting the value of a variable (listed from the highest to lowest priority):

1.	CLI arguments (-var and -var-file CLI parameters)
2.	*.auto.tfvars
3.	terraform.tfvars
4.	Environment variables

### Setting local values (locals)

Local values are a little different than regular variables (which we'll be looking at in the rest of this section).  Locals (aka local values) are set in the Terraform code itself.  A benefit of locals is --- because they're set within the Terraform code --- they can be computed programmatically, granting the ability to use Terraform functions, reference to other variables, locals, and resources.

Here's an example of how locals are defined.

```terraform
locals {
  comp_id = len(var.compartment_id) > 0 ? var.compartment_id : "abcd.1234"
}
```

The above example is just fictitious (and not even the most efficient method of doing this), but gives you an idea about how you'd set the `comp_id` local (variable).  Locals are defined within a plural `locals` block, but when referenced, are singular (`local.comp_id`).

### Via the command-line interface

Terraform supports many command-line parameters, one of which is the `-var` parameter which allows you to set the value of a variable when you run Terraform.  Here's an example of how you might set the `compartment_id` variable using the command-line.

```console
$ terraform plan -var 'compartment_id=abcd.1234'
```

Or alternatively, you can use the following formatting.

```console
$ terraform plan -var="compartment_id=abcd.1234"
```

You can set one or more variables using this technique.  This is one way to set variables, but it's a bit tedious because it can result in a really long command when running Terraform (if there are a lot of variables being set).  This would need to be used every time you want to run Terraform!

### Variable files

Files ending in `.tfvars` can be used to set the value of variables.  You can tell Terraform which files to read at run-time with the `-var-file` parameter or you can let it auto-load files (based on their filename).

If the `terraform.tfvars` file exists in the working directory, Terraform will read it and set the variable values that are given there.  Here's a sample `terraform.tfvars` file:

```terraform
compartment_id   = "<your_compartment_OCID_here>"
region           = "us-phoenix-1"
cidr             = "172.16.0.0/20"
```

These are setting variable values (note that there's no `var.` prefix used).  Terraform implicitly uses the `terraform.tfvars` file for setting variable values.

The `terraform.tfvars` file is statically read, meaning that there's no computation that takes place.  Terraform does not reference other variables, resources or other Terraform functions.  It reads only static values.

The `terraform.tfvars` file can often be used for setting environment-specific settings.  It is usually not committed to git repos (at least alongside the Terraform code), as its values might determine the characteristics for the environment.

### `*.auto.tfvars`

You can specify as many files as you'd like that end in `.auto.tfvars` and Terraform will gladly read these and set variable values accordingly.  This allows you to set different variable definitions between different files.  For instance, it might make sense to set the variable definitions as-follows (this is just an example, by no means the only way).

* `network.auto.tfvars`
* `storage.auto.tfvars`
* `compute.auto.tfvars`

Grouping variable assignments like this allows a person to better navigate between variables, especially if there's a large number of variables.

### Via environment variables

Terraform is smart enough to look at the environment variables at run-time.  If there are any that begin with `TF_VAR_` (the full environment variable would be: `TF_VAR_<variable_name>`), Terraform will assign the value to the given variable.

Here's an example of how to set the `compartment_id` variable on a MacOS/Linux system.

```bash
export TF_VAR_compartment_id=<your_compartment_OCID_here>
```

This same environment variable might be set as follows on Windows:

```bash
setx TF_VAR_compartment_id <your_compartment_OCID_here>
```

### Via user-interactive prompts

If a variable is not given a value, Terraform will resort to asking the user to provide it at run-time.  Terraform cannot proceed without knowing what value to use.

This is annoying and can be tedious (especially if there are lots of undefined variables), however there are times when this might make perfect sense and be a desirable behavior.  In situations where the user should be asked for a value (such as for a confirmation prompt), this can be a good solution.

## Defining variables

To define the existence of a variable, simply provide the following anywhere in the Terraform code:

```terraform
variable "compartment_id" {}
```

It's common practice to place variable definitions in a single file: `variables.tf`.  This allows for easier management of variable definitions (having them in one place).

Besides the name of the variable, there are several different attributes you can set for a variable, including (but not limited to):

* type (some of the common types will be discussed shortly)
* description (it's nice to let people know how this variable is used)
* default
* sensitive

### Default values

The `default` attribute is important to know about, as its behavior is multi-purpose.  Notice how there's no `required` attribute?  If a variable does *not* have a default value, Terraform will require the variable value to be set.  This means that `default` not only allows you to provide a default, but it can also make a variable "optional" (sort of).  This is really just a side effect of providing a value. Every variable defined *must* have a value.  Giving a default value (even if empty, such as a value of `""` or `null`) keeps Terraform from "bugging" the operator, which gives the impression that it's *not* required.  It's a matter of how you look at it.

Some variables might best be left blank (so it's very obvious if the user running Terraform doesn't set it to a specific value).  Often times it's nice to have "sane defaults" set so that a reasonable default value is used on a variable, minimizing the amount of inputs that must be provided.  When a variable is given a default value, the default value is used unless it is overridden (with a value explicitly set).

To define a default value, add the `default` attribute to the variable definition.

```terraform
variable "compartment_id" {
  default = "abcd.1234"
}
```

In the above example, unless a value is explicitly provided, the default value of "abcd.1234" will be used for the the `compartment_id` variable.

### Sensitive variables

If you set the sensitive attribute of a variable to `true`, Terraform tries to minimize displaying the value to the user. This is not a guarantee that it's not accessible to the user or that it won't be shown on the screen.  See the [Terraform documentation](https://www.terraform.io/docs/language/values/variables.html#suppressing-values-in-cli-output) for more information.

Here's an example:

```terraform
variable "api_token" {
  sensitive = true
}
```

In the above example, the visibility of the `api_token` variable is minimized through the use of setting the `sensitive` attribute to true for the `api_token` variable.

## Variable Types

### Strings
The variables used up to this point have been string values.  String values are enclosed by double-quotes (").

```terraform
compartment_id="<your_compartment_OCID_here>"
```

Here's how this is defined in `variables.tf`:

```terraform
variable tenancy_id {
  type = string
}
```

Strings are common, but are by no means the only kind that you can use.

### Numbers
Numbers are numeric values that are not surrounded by quotes.

```terraform
number_of_computes=10
```

Here's how this might be defined in `variables.tf`:

```terraform
variable "number_of_computes" {
  type = number
}
```

### Boolean

Like many other languages, Terraform supports `true` and `false` boolean values.  Here's an example of a Boolean variable being set.

```terraform
create_computes = true
```

In the above example, the `create_computes` variable is set to `true`.  These can be useful for many things, including specifying the desired behavior (like this example, where it might be possible to not create the computes if the value was set to `false`).

Here's how this might be defined in `variables.tf`:

```terraform
variable "create_computes" {
  type = bool
}
```

### Lists

There are times when a list is needed.  Terraform lists are similar to arrays in many other languages.  A Terraform list is an ordered lists of values of a given type (could be string values, number values, etc.).  Here's an example of a string list.

```terraform
compute_names = [ "web1", "web2", "app1", "app2", "db1", "db2" ]
```

Here's how this might be defined in `variables.tf`.

```terraform
variable "compute_names" {
  type = list(string)
}
```

To reference a list element, use the index of the item.  Terraform is zero-indexed, so the first item is index `0`, the second item is index `1`, and so on.  Look at how you might reference the `db1` value (from the above list example, being element `5`, index `4`):

```terraform
var.compute_names[4]   # this equals "db1"
```

### Maps

When the power of a key-value relationship is needed, Terraform maps are here to help!  Maps are similar to hashes in some other languages, allowing you to have multiple keys, with each key having a value.  Here's an example of a map.

```terraform
compute_shapes = {
  "web1" = "VM.Standard2.1",
  "web2" = "VM.Standard2.1",
  "app1" = "VM.Standard2.4",
  "app2" = "VM.Standard2.4",
  "db1"  = "VM.Standard2.8",
  "db2"  = "VM.Standard2.8"
}
```

Here's how this is defined in `variables.tf`.

```terraform
variable "compute_shapes" {
  type = map(string)
}
```

Notice that it is given what kind of values to expect in the map.  This could've been a map of numbers (instead of strings) or another valid variable type.

To reference a map element, use the item key.  Here's how the `db1` value might be referenced.

```terraform
var.compute_shapes["db1"]   # this equals "VM.Standard2.8"
```

## Sample Variable Definitions

Here's an example of a "toggle" variable (a boolean, which is either `true` or `false`):

```terraform
variable "extra_power" {
  type = bool
  default = true
}
```

And here's an example of a more complex variable (taken from [https://github.com/oracle-devrel/terraform-oci-ocloud-landing-zone/blob/main/component/network_domain/input.tf](https://github.com/oracle-devrel/terraform-oci-ocloud-landing-zone/blob/main/component/network_domain/input.tf)):

```terraform
variable "subnet" {
  type = object({
    cidr_block                  = string,
    prohibit_public_ip_on_vnic  = bool, 
    dhcp_options_id             = string,
    route_table_id              = string
  })
  description                   = "Parameters for each subnet to be managed"
}
```

In the above example, the subnet variable contains several attributes (`cidr_block`, `prohibit_public_ip_on_vnic`, etc.), which are of different types.  This is just one example of how complex variables can be crafted.  Don't worry about this though, as complex variables are optional (you can stick with single-value variables for most use-cases).

These are just a few examples.  You can get really crazy with variables!  Have fun with them, be creative, and remember that variables largely define the input interface for the Terraform environment.  Look at the [Terraform language documentation on input variables](https://www.terraform.io/docs/language/values/variables.html) to discover some of the other variable types and Terraform variable functionality.
{% endslides %}
