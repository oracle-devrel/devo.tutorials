---
title: Deploy a modern data lake on OCI
parent:
- tutorials
description: Using Terraform to create a data lake on Oracle Cloud Infrastructure.
thumbnail: assets/datalakeocichart_4481-9331b237844018b1.png
author: Ali Mukadam
tags:
- kubernetes
- devops
- terraform
- oci
category: clouddev
date: 2021-10-29 12:00
mrm: WWMK211125P00021
xredirect: https://developer.oracle.com/tutorials/create-modern-data-lake-oci-readme/
slug: create-modern-data-lake-oci-readme
---
{% imgx aligncenter assets/datalakeocichart_4481-9331b237844018b1.png "OCI Datalake Architecture Overview" %}

What is a data lake? Simply, a data lake is a place to store both your structured and unstructured data. It's also a great method for organizing large volumes of diverse data from diverse sources.  

In this article, we'll guide you through deploying a data lake in OCI and quickly get you up and running so you can explore its many benefits!  

For more information, see:

* [Signing Up for Oracle Cloud Infrastructure]
* [Getting started with Terraform]
* [Getting started with OCI Cloud Shell]
* [What is a data lake?]

## Prerequisites

In order to successfully complete this tutorial, you'll need:

* An Oracle Cloud Infrastructure (OCI) Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* Access to the [OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm) - It provides a great platform for quickly working with Terraform as well as a host of other OCI interfaces and tools.
* The [OCI Resource Manager (ORM)] - This Quick Start uses the ORM to make deployment easy.
* The ORM stack - Select the button below to download the `master.zip` file:  

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-datalake/releases/download/0.1/master.zip)

## Getting started

After logging into the console you'll be taken through the same steps described in the [Deploy](#deploy-with-orm) section below.  

>**NOTE:** If you use this template to create another repo you'll need to change the link for the button to point at your repo.
{:.notice}

## Local Development

Make sure your credentials are defined in `$HOME/.oci/config` file since Terraform takes takes the default value from the `.oci/config` file.  

For example:  

```console
user=ocid1.user.oc1..aaaaaxxxwf3a \
fingerprint=de:50:15:13:...:d6 \
key_file=/Users/shadab/.oci/oci_api_key.pem \
tenancy=ocid1.tenancy.oc1..aaaaaaaa2txfa \
compartment=ocid1.compartment.oc1..aaaa5pti7sq \
region=us-ashburn-1
```

```console
git clone https://github.com/oracle-quickstart/oci-datalake && cd oci-datalake
```

### Initialize

Initialize the Terraform provider for OCI and Random:  

```console
terraform init
```

### Build Plan

```console
terraform plan -var-file=config.tfvars -out oci_datalake.out
```

### Apply

```console
terraform apply "oci_datalake.out"
```

### Destroy

```console
terraform destroy -var-file=config.tfvars
```

## Deploy with ORM

1. **Import the stack -** [Log in] to OCI to import the stack:  

   **Home > Solutions & Platform > Resource Manager > Stacks > Create Stack**

1. **Upload stack -** Upload the `master.zip` and provide a name and description for the stack:  

    {% imgx aligncenter assets/datalakeoci_4a6e6eb3_bbfb_d66353a189bc.png "Create Stack Dialog" %}

1. **Configure the Stack -** The UI will present the variables to the user dynamically, based on their selections.

<!--- Links -->

[Signing Up for Oracle Cloud Infrastructure]: https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm
[Getting started with Terraform]: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformgettingstarted.htm
[Getting started with OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm
[What is a data lake?]: https://www.oracle.com/big-data/what-is-data-lake/
[OCI Resource Manager (ORM)]: https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm
[OCI account]: https://cloud.oracle.com/en_US/tryit
[Log in]: https://console.us-ashburn-1.oraclecloud.com/resourcemanager/stacks/create
