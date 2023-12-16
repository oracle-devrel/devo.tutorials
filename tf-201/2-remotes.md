---
title: Using remote states with Terraform
parent: tf-201
tags: [open-source, terraform, iac, devops, intermediate]
categories: [iac, opensource]
thumbnail: assets/terraform-201.png
date: 2021-10-07 6:17
description: This tutorial shows some of the options for storing your Terraform state remotely.
toc: true
author: tim-clegg
---
{% img aligncenter assets/terraform-201.png 400 400 "Terraform 201" "Terraform 201 Tutorial Series" %}

Terraform by default stores the state locally.  This works great when a single person is managing an environment.  When multiple people are managing an environment, this doesn't scale well.  Managing and sharing the Terraform state between team members is an important facet in any Terraform-managed environment.

## Remote State Storage Options
There are several options available for storing Terraform state remotely on Oracle Cloud Infrastructure (OCI), including (but not limited to):

* OCI Resource Manager
* OCI Object Storage
* Git repository

## OCI Resource Manager
OCI Resource Manager (ORM) is a way to effortlessly run Terraform through an Oracle-managed cloud service that's integrated into OCI.  ORM takes care of managing the Terraform state and is a great way to quickly and easily manage OCI infrastructure.

ORM allows for the manual management of OCI infrastructure by the uploading of Terraform stacks, then plan/apply activities which are user-initiatied.  The service also might be integrated into an automated pipeline, where the interactions with ORM take place via the ORM API (to upload, plan and apply stacks).

It's possible to integrate ORM with many popular version control systems (VCS), including GitHub and GitLab, eliminating the need to upload a Terraform stack by hand, but rather have ORM read a Git repository for the Terraform code it should use.  ORM makes it possible to achieve a more streamlined CI/CD pipeline between your code and its final implementation in OCI!

In situations where Terraform will be used to manage pre-existing resources (already in-place, but not currently managed by Terraform), ORM can allow you to quickly discover these existing resources in your OCI tenancy.  This is particularly helpful for environments that have not been built and maintained using Terraform, but should be managed by Terraform going forward.  The resource discovery functionality can save an enormous amount of time in creating Terraform code based on the resources present at the time of discovery.

Taking the resource discovery functionality a step further, ORM makes it easy to perform drift detection, allowing you to look for unwanted changes in the environment (those that have taken place outside of the Terraform stack).

To learn more about ORM, please look at the [OCI ORM documentation](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/landing.htm).

## OCI Object Storage
This is an ideal place to store your state, as it supports versioning (being able to look back at previous versions of the Terraform state) and is highly-available.  To use OCI Object Storage, follow these steps.

1.	Create the Bucket in OCI Object Storage
2.	Tell Terraform to use the Bucket

Because you need to create the Bucket *before* you can use it in a Terraform project, you'll need to have two Terraform projects if you take this route:
* One Terraform project to create the Bucket for the Terraform project
* Another Terraform project to manage your other resources

You could create the Bucket via the Console or CLI, however here’s how you might do it using Terraform.

```terraform
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "env1-tfstate" {
  compartment_id = var.tenancy_ocid
  name = "env1-tfstate"
  namespace = data.oci_objectstorage_namespace.this.namespace
  access_type = "NoPublicAccess"
  object_events_enabled = false
  storage_tier = "Standard"
  versioning = "Enabled"
}
```

Whether you created the Bucket in the Console or via Terraform, here’s how to tell Terraform to use it:

```terraform
terraform {
  backend "s3" {
    bucket = "env1-tfstate"
    key = "terraform.tfstate"
    region = var.region
    endpoint = "https://${data.oci_objecstorage_namespace.this.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
    access_key = var.tf_access_key
    secret_key = var.tf_secret_key
    skip_region_validation = true
    skip_credentials_validation = true
    skip_metadata_api_check = true
    force_path_style = true
  }
}
```

The `tf_access_key` and `tf_secret_key` variables need to be set (ideally using environment variables).  By using variables, you can avoid committing sensitive information to a Git repo, plus in the case of automated pipelines, variables make it easy to integrate with a secret store.

For more information on using the OCI Object Storage as a backend for the Terraform state, take a look at the [OCI Provider documentation](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/guides/object_store_backend).

## Git Repository
While it’s possible to use a Git repository for storing Terraform state remotely, it’s not ideal.  Git isn’t a real-time shared file system, so if multiple people are working on the same environment at the same time, it’s possible that they’ll end up with two separate versions of the state file, which is not desirable (requiring some manual intervention to resolve the situation).  When using a git repository for Terraform state storage, coordination between between team members is typically needed, to ensure that only one person is making changes at any given point in time (who is doing it and when the changes are being made to the environment).

When using git, it's important to `git pull` (update your local copy) prior to making any changes (to make sure that both the code as well as state is up-to-date).  At this point you can typically make your changes (making sure you communicate with your team that you're doing this, effectively simulating a file locking mechanism).  After making your changes, commit and push your changes (so your team can pull the changes).  This is an overly-simplified view, but gives you an idea of what needs to take place.

## Conclusion
We've only touched a couple of the many backends available.  Check out the [Terraform documentation](https://www.terraform.io/docs/language/settings/backends/index.html) for more information and ideas.

Because the Terraform state is such a critically important component, finding a good home for it is an important early step to take with any environment.  Consider your options, desired workflow and choose accordingly!
