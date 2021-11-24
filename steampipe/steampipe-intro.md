---
title: Introduction to Steampipe on Oracle Cloud Infrastructure
parent: [tutorials,steampipe]
tags: [open-source, steampipe, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/pexels-gabriela-palai-507410.jpg
date: 2021-11-24 10:56
description: Steampipe is a great tool that you should have in your IaC toolbox.  Learn about how to use it with OCI here!
toc: true
author: jon-decamp
---
*[OCI]: Oracle Cloud Infrastructure

{% imgx alignright assets/pexels-gabriela-palai-507410.jpg 800 534 "Steam train on bridge" %}

*Photo credit: Photo by [Gabriela Palai](https://www.pexels.com/@gabriela-palai-129458?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels) from [Pexels](https://www.pexels.com/photo/train-with-smoke-507410/?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels)*

I must be virtually hanging out in the wrong circles these days, because [Steampipe](https://steampipe.io/) by [Turbot](https://turbot.com/) seems like it came out of nowhere. I admit that I haven't used anything by Turbot in the past, but I'm an instant fan now that I've been pulled into the wonderful world of Steampipe.

## So, what is Steampipe?

Steampipe is a new open source tool for running queries against cloud resources. It supports multiple cloud providers (plugins), supports a Postgres-like SQL query language, and provides an interactive CLI to navigate through resources. I had the opportunity to perform an evaluation of Steampipe, and I wanted to share some of my experiences. The tool seems to be growing quickly, so I'll try to link to their excellent documentation whenever I have a chance.

See the [official Steampipe introduction](https://steampipe.io/blog/introducing-steampipe) for more background.

## How do you install it?

Install instructions for Windows, Mac, and Linux are provided on the [Steampipe webpage](https://steampipe.io/downloads). The instructions walk you through using Homebrew if you're on a Mac, an installer script for Linux, or on Windows via Windows Subsystem for Linux with Ubuntu.

## The OCI plugin

Steampipe has a plugin which [adds support for Oracle Cloud Infrastructure](https://hub.steampipe.io/plugins/turbot/oci) (OCI). You can install the plugin using the syntax below:

```console
steampipe plugin install oci
```

To learn more about the OCI plugin, see the [documentation and examples at the table level](https://hub.steampipe.io/plugins/turbot/oci/tables). You can also learn more about the tables available via the plugin using the `.tables` and `.inspect` commands in the interactive shell.

Once you have the plugin installed, you're ready to run queries.

## Basic functionality

The Steampipe [documentation](https://steampipe.io/docs) is a thorough reference to the commands and query syntax. I'm no SQL expert, and so I'll just touch on a few highlights to help you get started.

The query syntax can start as simple as a "select thing from table" and extend far beyond that. For example:

```console
select display_name from oci_kms_vault
+-----------------------+
| display_name          |
+-----------------------+
| oci-vault1       |
| oci-vault2       |
| oci-myvault      |
```

You can store queries in external files and run the queries by specifying the filename on the command line. Let's look at an example SQL file from the OCI Compliance mod (more on this later):

```sql
select
  -- Required Columns
  a.id as resource,
  case
    when public_access_type like 'Object%' then 'alarm'
    else 'ok'
  end as status,
  case
    when public_access_type like 'Object%' then a.title || ' publicly accessible.'
    else a.title || ' not publicly accessible.'
  end as reason,
  -- Additional Dimensions
  region,
  coalesce(c.name, 'root') as compartment
from
  oci_objectstorage_bucket as a
  left join oci_identity_compartment as c on c.id = a.compartment_id;
```

And say we have that stored in a file called `objectstorage_bucket_public_access_blocked.sql`. You can run this query like so:

```console
steampipe query objectstorage_bucket_public_access_blocked.sql
+-----------------------------------------------------------------------------------+--------+---------------------------------------------------+--------------+---------------+
| resource                                                                          | status | reason                                            | region       | compartment   |
+-----------------------------------------------------------------------------------+--------+---------------------------------------------------+--------------+---------------+
| ocid1.bucket.oc1.iad.<sanitized> | ok     | jon-test-rep not publicly accessible.             | us-ashburn-1 | mytest02-dev  |
| ocid1.bucket.oc1.phx.<sanitized> | ok     | bootstrap_testing not publicly accessible.        | us-phoenix-1 | mytest02-dev  |
| ocid1.bucket.oc1.phx.<sanitized> | ok     | Inventory not publicly accessible.                | us-phoenix-1 | root          |
| ocid1.bucket.oc1.phx.<sanitized> | ok     | bucket-20210428-0949 not publicly accessible.     | us-phoenix-1 | mytest03-dev  |
| ocid1.bucket.oc1.phx.<sanitized> | ok     | mybucket not publicly accessible.                 | us-phoenix-1 | mytest01-dev  |
+-----------------------------------------------------------------------------------+--------+---------------------------------------------------+--------------+---------------+
```

Lastly, you can run an interactive Steampipe shell, which offers more tools for navigating tables, as well as tab completion. Run the steampipe query command to enter the shell. From the shell, you can run queries by typing them out, or by copying and pasting them from an external source.

Other helpful commands in the shell (note that they all begin with a dot):

 * `.inspect` - inspect the contents of a table
 * `.tables` - list the tables available to query
 * `.output` - change the output format (JSON, CSV, or table)

Example of opening the CLI and listing the available tables:

```console
steampipe query
Welcome to Steampipe v0.9.0
For more information, type .help
> .tables
 ==> oci
+--------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| table                                      | description                                                                                                                    |
+--------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| oci_apigateway_api                         | OCI Apigateway Api                                                                                                             |
| oci_autoscaling_auto_scaling_configuration | OCI Auto Scaling Configuration                                                                                                 |
| oci_cloud_guard_configuration              | OCI Cloud Guard Configuration                                                                                                  |
| oci_cloud_guard_detector_recipe            | OCI Cloud Guard Detector Recipe                                                                                                |
| oci_cloud_guard_managed_list               | OCI Cloud Guard Managed List                                                                                                   |
| oci_cloud_guard_responder_recipe           | OCI Cloud Guard Responder Recipe                                                                                               |
| oci_cloud_guard_target                     | OCI Cloud Guard Target                                                                                                         |
| oci_core_boot_volume_backup                | OCI Core Boot Volume Backup                                                                                                    |
| oci_core_dhcp_options                      | OCI Core DHCP Options
```

## Using mods (oci compliance)

Mods can be a collection of SQL scripts built for custom reporting. Compliance is an important aspect of what [my team works on](https://docs.oracle.com/en/solutions/pci-compliant-webapp-terraform), and that made finding an `oci_compliance` module an exciting discovery. The `oci_compliance` mod has Center for Internet Security (CIS) compliance reporting built on top of Steampipe, and that just scratches the surface of the possibilities.

Steampipe mods [can be found here](https://hub.steampipe.io/mods).

For more information, plus examples and instructions, be sure to visit [the oci_compliance page](https://hub.steampipe.io/mods/turbot/oci_compliance). 

Let's install the mod, and run a check for a specific control in this example:

```console
$ git clone https://github.com/turbot/steampipe-mod-oci-compliance.git
Cloning into 'steampipe-mod-oci-compliance'...
remote: Enumerating objects: 254, done.
remote: Counting objects: 100% (254/254), done.
remote: Compressing objects: 100% (184/184), done.
remote: Total 254 (delta 121), reused 155 (delta 61), pack-reused 0
Receiving objects: 100% (254/254), 468.38 KiB | 949.00 KiB/s, done.
Resolving deltas: 100% (121/121), done.
 
$ cd steampipe-mod-oci-compliance/
 
$ steampipe check control.cis_v110_2_1
 
+ 2.1 Ensure no security lists allow ingress from 0.0.0.0/0 to port 22 ................................................................................... 26 / 77 [==========]
  |
  ALARM: Default Security List for ca_vcn contains 1 ingress rule(s) allowing SSH from 0.0.0.0/0. ......................................................... us-ashburn-1 ca_dev
  ALARM: Default Security List for Inventory_VCN contains 1 ingress rule(s) allowing SSH from 0.0.0.0/0. .................................................... us-phoenix-1 root
  ALARM: Default Security List for Primary VCN contains 1 ingress rule(s) allowing SSH from 0.0.0.0/0. ............................................. us-phoenix-1 oci-test
  ALARM: Bastion Security List contains 1 ingress rule(s) allowing SSH from 0.0.0.0/0. ............................................................. us-phoenix-1 oci-test
  OK   : App Security List ingress restricted for SSH from 0.0.0.0/0. .............................................................................. us-phoenix-1 oci-test
  OK   : Wazuh Security List ingress restricted for SSH from 0.0.0.0/0. ............................................................................ us-phoenix-1 oci-test
  OK   : DMZ Security List - Egress ingress restricted for SSH from 0.0.0.0/0. ..................................................................... us-phoenix-1 oci-test
  OK   : DMZ Security List - Ingress ingress restricted for SSH from 0.0.0.0/0. .................................................................... us-phoenix-1 oci-test
*** OUTPUT CUT ***
```

## Wrapping Up

Steampipe shows tremendous potential. It's easier to use Steampipe to query OCI resources than it is to remember complex command line options. Results come back fast, especially with a tuned query. Modules provide an additional layer of reporting and glue for the data. I look forward to working with Steampipe and building this tool into my toolbox.
