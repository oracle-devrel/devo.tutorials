---
title: Terraform Dependencies
parent: tf-201
tags: [open-source, terraform, iac, devops, intermediate]
categories: [iac, opensource]
thumbnail: assets/terraform-201.png
date: 2021-10-05 10:51
description: Learn how Terraform automatically manages resource dependencies and when (and how) to use explicit (manual) resource dependencies.
toc: true
author: tim-clegg
---
{% img aligncenter assets/terraform-201.png 400 400 "Terraform 201" "Terraform 201 Tutorial Series" %}

If you went through the [Terraform 101 tutorial series](/tutorials/tf-101), then you got a chance to see how intelligently Terraform behaved when it came time to destroy all of the resources in the project (the [Destroying resources with Terraform](/tutorials/tf-101/7-destroying) tutorial).  This is due to how Terraform automatically manages resource dependencies.  There are times when explicit resource dependencies need to be configured.  This tutorial takes a brief overview of how resource dependencies are managed in Terraform.

Make sure that to start with the code at the end of the [Destroying resources with Terraform](/tutorials/tf-101/7-destroying) tutorial.

## Implicit Dependencies
As you define resources, Terraform automatically tracks resource dependencies.  A graph of the topology is maintained by Terraform, allowing Terraform to track dependencies and relationships between different resources.

This was seen at work in the [Destroying resources with Terraform tutorial](/tutorials/tf-101/7-destroying), when the environment was entirely destroyed.  During this process Terraform chose to destroy all of the Subnets first, then destroy the VCN last.  Had Terraform tried to delete the VCN while the Subnets were still present, the process would've failed.

The reverse is true as an environment is provisioned.  See this at work by applying the environment that was destroyed in the [Terraform-101 series](/tutorials/tf-101/7-destroying):

```
$ terraform apply 

# ...

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_vcn.tf_101: Creating...
oci_core_vcn.tf_101: Creation complete after 3s [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.dev: Creating...
oci_core_subnet.test: Creating...
oci_core_subnet.test: Still creating... [10s elapsed]
oci_core_subnet.dev: Still creating... [10s elapsed]
oci_core_subnet.test: Creation complete after 16s [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev: Still creating... [20s elapsed]
oci_core_subnet.dev: Creation complete after 27s [id=ocid1.subnet.oc1.phx.<sanitized>]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

> **NOTE:** If you're prompted to enter a value for the `region` or `tenancy_ocid` variables, it's likely that the environment variables (above) need to be set.  Each time you connect to your OCI Cloud Shell session, you'll need to set these, similar to the following:
> ```console
declare -x TF_VAR_tenancy_ocid=`echo $OCI_TENANCY`
declare -x TF_VAR_region=`echo $OCI_REGION`
```
{:notice}


The VCN was built *first*, then the Subnets were added.  This goes back to the fact that Terraform understands the relationship between these dependent resources.  It knows that the VCN must exist *before* the Subnets can be created.

For many use-cases, this implicit dependency relationship mapping works just fine.  There are situations where Terraform might need some help... this is where explicit dependencies come into play.

## Explicit Dependencies
The implicit dependency mapping works so well, you might be asking yourself why would you ever want to manually specify an explicit dependency?  It turns out that Terraform can't read minds, and there are situations where it cannot infer or see any logical relationship or dependency between two resources.

For example, pretend that you have an OCI Object Storage Bucket that contains objects (files) that are used by a particular application.  This application is deployed and running on an OCI Compute instance.  Follow along by adding the following to your `main.tf` file:

```terraform
# OSS Bucket
data "oci_objectstorage_namespace" "this" {
}

resource "oci_objectstorage_bucket" "app" {
  compartment_id = "<your_compartment_OCID_here>"
  name           = "App_Data"
  namespace      = data.oci_objectstorage_namespace.this.namespace
  access_type    = "NoPublicAccess"
}

# Get all Availability Domains for the region
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Compute images
data "oci_core_images" "this" {
  compartment_id   = var.tenancy_ocid
  state            = "AVAILABLE"
  operating_system = "Oracle Linux"
  shape            = "VM.Standard.E3.Flex"
  sort_by          = "DISPLAYNAME"
  sort_order       = "DESC"
}

# Compute instance
resource "oci_core_instance" "app" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.ailability_domains[0], "name")
  compartment_id      = var.tenancy_ocid
  shape               = "VM.Standard.E3.Flex"
  display_name        = "app"

  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  create_vnic_details {
    assign_public_ip = false
    subnet_id        = oci_core_subnet.dev.id
  }
  source_details {
    source_id   = data.oci_core_images.this.images[0].id
    source_type = "image"
  }
  preserve_boot_volume = false
}
```

> If you're wanting to use a specific Compartment, make sure to use that instead of `var.tenancy_ocid`.
{:.notice}

> **NOTE:** If you're using an Always Free OCI tenancy, you'll need to use a shape of `VM.Standard.E2.1.Micro` (instead of `VM.Standard.E3.Flex`) and get rid of the `shape_config` block.
{:.notice}

There's a few lines of code in there – some of which you don't need to get mired down with.  Some handy code best-practices (like retrieving the latest Compute image OCID programmatically, getting the name of the AD programmatically, etc.) are part of it, but don't get distracted or overwhelmed by it.  In short, Terraform is being asked to to create an OCI Object Storage Bucket for the application, then to create an OCI Compute instance.  The OCI Compute instance would presumably run the application, although in this example there's nothing actually installed on it (just pretend that it's being used in this way).

Look at the Terraform plan to see what Terraform proposes be done.

```
$ terraform plan
oci_core_vcn.tf_101: Refreshing state... [id=ocid1.vcn.oc1.phx.<sanitized>]
oci_core_subnet.test: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]
oci_core_subnet.dev: Refreshing state... [id=ocid1.subnet.oc1.phx.<sanitized>]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # oci_core_instance.app will be created
  + resource "oci_core_instance" "app" {
      + availability_domain                 = "123:PHX-AD-1"
      + boot_volume_id                      = (known after apply)
      + compartment_id                      = "ocid1.<sanitized>"
      + dedicated_vm_host_id                = (known after apply)
      + defined_tags                        = (known after apply)
      + display_name                        = "app"
      + fault_domain                        = (known after apply)
      + freeform_tags                       = (known after apply)
      + hostname_label                      = (known after apply)
      + id                                  = (known after apply)
      + image                               = (known after apply)
      + ipxe_script                         = (known after apply)
      + is_pv_encryption_in_transit_enabled = (known after apply)
      + launch_mode                         = (known after apply)
      + preserve_boot_volume                = false
      + private_ip                          = (known after apply)
      + public_ip                           = (known after apply)
      + region                              = (known after apply)
      + shape                               = "VM.Standard.E3.Flex"
      + state                               = (known after apply)
      + subnet_id                           = (known after apply)
      + system_tags                         = (known after apply)
      + time_created                        = (known after apply)
      + time_maintenance_reboot_due         = (known after apply)

      + agent_config {
          + is_management_disabled = (known after apply)
          + is_monitoring_disabled = (known after apply)
        }

      + availability_config {
          + recovery_action = (known after apply)
        }

      + create_vnic_details {
          + assign_public_ip       = "false"
          + defined_tags           = (known after apply)
          + display_name           = (known after apply)
          + freeform_tags          = (known after apply)
          + hostname_label         = (known after apply)
          + private_ip             = (known after apply)
          + skip_source_dest_check = (known after apply)
          + subnet_id              = "ocid1.subnet.oc1.phx.<sanitized>"
          + vlan_id                = (known after apply)
        }

      + instance_options {
          + are_legacy_imds_endpoints_disabled = (known after apply)
        }

      + launch_options {
          + boot_volume_type                    = (known after apply)
          + firmware                            = (known after apply)
          + is_consistent_volume_naming_enabled = (known after apply)
          + is_pv_encryption_in_transit_enabled = (known after apply)
          + network_type                        = (known after apply)
          + remote_data_volume_type             = (known after apply)
        }

      + shape_config {
          + gpu_description               = (known after apply)
          + gpus                          = (known after apply)
          + local_disk_description        = (known after apply)
          + local_disks                   = (known after apply)
          + local_disks_total_size_in_gbs = (known after apply)
          + max_vnic_attachments          = (known after apply)
          + memory_in_gbs                 = 1
          + networking_bandwidth_in_gbps  = (known after apply)
          + ocpus                         = 1
          + processor_description         = (known after apply)
        }

      + source_details {
          + boot_volume_size_in_gbs = (known after apply)
          + kms_key_id              = (known after apply)
          + source_id               = "ocid1.image.oc1.phx.<sanitized>"
          + source_type             = "image"
        }
    }

  # oci_objectstorage_bucket.app will be created
  + resource "oci_objectstorage_bucket" "app" {
      + access_type                  = "NoPublicAccess"
      + approximate_count            = (known after apply)
      + approximate_size             = (known after apply)
      + bucket_id                    = (known after apply)
      + compartment_id               = "ocid1.compartment.oc1..12345ABCDEF"
      + created_by                   = (known after apply)
      + defined_tags                 = (known after apply)
      + etag                         = (known after apply)
      + freeform_tags                = (known after apply)
      + id                           = (known after apply)
      + is_read_only                 = (known after apply)
      + kms_key_id                   = (known after apply)
      + name                         = "App_Data"
      + namespace                    = "<namespace>"
      + object_events_enabled        = (known after apply)
      + object_lifecycle_policy_etag = (known after apply)
      + replication_enabled          = (known after apply)
      + storage_tier                 = (known after apply)
      + time_created                 = (known after apply)
      + versioning                   = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

Let's proceed forward and ask Terraform to apply (deploy) it:

```
$ terraform apply

# ...

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_objectstorage_bucket.app: Creating...
oci_core_instance.app: Creating...
oci_objectstorage_bucket.app: Creation complete after 2s [id=n/<namespace>/b/App_Data]
oci_core_instance.app: Still creating... [10s elapsed]
oci_core_instance.app: Still creating... [20s elapsed]
oci_core_instance.app: Still creating... [30s elapsed]
oci_core_instance.app: Still creating... [40s elapsed]
oci_core_instance.app: Still creating... [50s elapsed]
oci_core_instance.app: Still creating... [1m0s elapsed]
oci_core_instance.app: Still creating... [1m10s elapsed]
oci_core_instance.app: Still creating... [1m20s elapsed]
oci_core_instance.app: Still creating... [1m30s elapsed]
oci_core_instance.app: Creation complete after 1m31s [id=ocid1.instance.oc1.phx.<sanitized>]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

The bucket and the compute instance were created in parallel.  This isn't what is needed, as in our fictitious example, the bucket must exist *before* the compute instance is created.  In this fictitious scenario, pretend that there's a cloud-init configuration that references something in the bucket.  If the bucket doesn't exist *prior* to the compute instance, provisioning would fail.

Let's remove the instance just created:

```
$ terraform destroy -target=oci_core_instance.app

# ...

Plan: 0 to add, 0 to change, 1 to destroy.

# ...

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

# ...

Destroy complete! Resources: 1 destroyed.
```

Now destroy the bucket:

```
$ terraform destroy -target=oci_objectstorage_bucket.app

# ...

Plan: 0 to add, 0 to change, 1 to destroy.

# ...

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

# ...

Destroy complete! Resources: 1 destroyed.
```

Explicit dependencies need to be added to ensure the order-of-precedence for resource creation is correct.  Make the beginning of the `oci_core_instance.app` resource look like the following (notice the only addition is the `depends_on` line) in your `main.tf` file:

```terraform
resource "oci_core_instance" "app" {
  depends_on = [oci_objectstorage_bucket.app]
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[0],"name")
```

Run `terraform apply`:

```
$ terraform apply

# ...

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_objectstorage_bucket.app: Creating...
oci_objectstorage_bucket.app: Creation complete after 3s [id=n/<namespace>/b/App_Data]
oci_core_instance.app: Creating...
oci_core_instance.app: Still creating... [10s elapsed]
oci_core_instance.app: Still creating... [20s elapsed]
oci_core_instance.app: Still creating... [30s elapsed]
oci_core_instance.app: Still creating... [40s elapsed]
oci_core_instance.app: Still creating... [50s elapsed]
oci_core_instance.app: Still creating... [1m0s elapsed]
oci_core_instance.app: Still creating... [1m10s elapsed]
oci_core_instance.app: Creation complete after 1m15s [id=ocid1.instance.oc1.phx.<sanitized>]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Success!  Take notice of how Terraform recognized that the Bucket needed to be created *before* the Compute Instance.  It is possible to add multiple explicit resource dependencies by simply providing a list of resources (`depends_on = [rez_type.first, rez_type.second]`).

Making things even better, Terraform's smart enough to know how to destroy resources in the proper order, following the implicit and explicit resource dependencies.  See this in action by removing the Bucket with the terraform destroy command:

```
$ terraform destroy -target=oci_objectstorage_bucket.app

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # oci_core_instance.app will be destroyed
  - resource "oci_core_instance" "app" {
      - availability_domain  = "123:PHX-AD-1" -> null
      - boot_volume_id       = "ocid1.bootvolume.oc1.phx.<sanitized>" -> null
      - compartment_id       = "ocid1.<sanitized>" -> null
      - defined_tags         = {} -> null
      - display_name         = "app" -> null
      - fault_domain         = "FAULT-DOMAIN-2" -> null
      - freeform_tags        = {} -> null
      - hostname_label       = "app" -> null
      - id                   = "ocid1.instance.oc1.phx.<sanitized>" -> null
      - image                = "ocid1.image.oc1.phx.<sanitized>" -> null
      - launch_mode          = "NATIVE" -> null
      - preserve_boot_volume = false -> null
      - private_ip           = "172.16.0.172" -> null
      - region               = "phx" -> null
      - shape                = "VM.Standard.E3.Flex" -> null
      - state                = "RUNNING" -> null
      - subnet_id            = "ocid1.subnet.oc1.phx.<sanitized>" -> null
      - system_tags          = {} -> null
      - time_created         = "2021-02-09 21:52:02.115 +0000 UTC" -> null

      - agent_config {
          - is_management_disabled = false -> null
          - is_monitoring_disabled = false -> null
        }

      - availability_config {
          - recovery_action = "RESTORE_INSTANCE" -> null
        }

      - create_vnic_details {
          - assign_public_ip       = "false" -> null
          - defined_tags           = {} -> null
          - display_name           = "app" -> null
          - freeform_tags          = {} -> null
          - hostname_label         = "app" -> null
          - private_ip             = "172.16.0.172" -> null
          - skip_source_dest_check = false -> null
          - subnet_id              = "ocid1.subnet.oc1.phx.<sanitized>" -> null
        }

      - instance_options {
          - are_legacy_imds_endpoints_disabled = false -> null
        }

      - launch_options {
          - boot_volume_type                    = "PARAVIRTUALIZED" -> null
          - firmware                            = "UEFI_64" -> null
          - is_consistent_volume_naming_enabled = true -> null
          - is_pv_encryption_in_transit_enabled = false -> null
          - network_type                        = "VFIO" -> null
          - remote_data_volume_type             = "PARAVIRTUALIZED" -> null
        }

      - shape_config {
          - gpus                          = 0 -> null
          - local_disks                   = 0 -> null
          - local_disks_total_size_in_gbs = 0 -> null
          - max_vnic_attachments          = 2 -> null
          - memory_in_gbs                 = 1 -> null
          - networking_bandwidth_in_gbps  = 1 -> null
          - ocpus                         = 1 -> null
          - processor_description         = "2.25 GHz AMD EPYC™ 7742 (Rome)" -> null
        }

      - source_details {
          - boot_volume_size_in_gbs = "47" -> null
          - source_id               = "ocid1.image.oc1.phx.<sanitized>" -> null
          - source_type             = "image" -> null
        }
    }

  # oci_objectstorage_bucket.app will be destroyed
  - resource "oci_objectstorage_bucket" "app" {
      - access_type           = "NoPublicAccess" -> null
      - approximate_count     = "0" -> null
      - approximate_size      = "0" -> null
      - bucket_id             = "ocid1.bucket.oc1.phx.<sanitized>" -> null
      - compartment_id        = "ocid1.<sanitized>" -> null
      - created_by            = "ocid1.user.oc1..<sanitized>" -> null
      - defined_tags          = {} -> null
      - etag                  = "1234567" -> null
      - freeform_tags         = {} -> null
      - id                    = "n/<namespace>/b/App_Data" -> null
      - is_read_only          = false -> null
      - name                  = "App_Data" -> null
      - namespace             = "<namespace>" -> null
      - object_events_enabled = false -> null
      - replication_enabled   = false -> null
      - storage_tier          = "Standard" -> null
      - time_created          = "2021-02-09 21:51:59.295 +0000 UTC" -> null
      - versioning            = "Disabled" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.


Warning: Resource targeting is in effect

You are creating a plan with the -target option, which means that the result
of this plan may not represent all of the changes requested by the current
configuration.

The -target option is not for routine use, and is provided only for
exceptional situations such as recovering from errors or mistakes, or when
Terraform specifically suggests to use it as part of an error message.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

oci_core_instance.app: Destroying... [id=ocid1.instance.oc1.phx.<sanitized>]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 10s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 20s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 30s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 40s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 50s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 1m0s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 1m10s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 1m20s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 1m30s elapsed]
oci_core_instance.app: Still destroying... [id=ocid1.instance.oc1.phx.<sanitized>, 1m40s elapsed]
oci_core_instance.app: Destruction complete after 1m50s
oci_objectstorage_bucket.app: Destroying... [id=n/<namespace>/b/App_Data]
oci_objectstorage_bucket.app: Destruction complete after 3s

Warning: Applied changes may be incomplete

The plan was created with the -target option in effect, so some changes
requested in the configuration may have been ignored and the output values may
not be fully updated. Run the following command to verify that no other
changes are pending:
    terraform plan

Note that the -target option is not suitable for routine use, and is provided
only for exceptional situations such as recovering from errors or mistakes, or
when Terraform specifically suggests to use it as part of an error message.


Destroy complete! Resources: 2 destroyed.
```

Terraform recognized that to destroy the bucket, it must destroy the compute instance first!  This is terrific - that means that I can safely create and destroy resources, even when there are carefully crafted resource dependencies.

It's time to clean-up your code and delete the following lines from your `main.tf` file (you don't need the Bucket or compute instance any longer):

```terraform
# OSS Bucket
data "oci_objectstorage_namespace" "this" {
}

resource "oci_objectstorage_bucket" "app" {
  compartment_id = var.tenancy_ocid
  name           = "App_Data"
  namespace      = data.oci_objectstorage_namespace.this.namespace
  access_type    = "NoPublicAccess"
}

# Get all Availability Domains for the region
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Compute images
data "oci_core_images" "this" {
  compartment_id   = "<your_compartment_OCID_here>"
  state            = "AVAILABLE"
  operating_system = "Oracle Linux"
  shape            = "VM.Standard.E3.Flex"
  sort_by          = "DISPLAYNAME"
  sort_order       = "DESC"
}

# Compute instance
resource "oci_core_instance" "app" {
  depends_on = [oci_objectstorage_bucket.app]
  availability_domain = lookup(data.oci_identity_availability_domains.ads.ailability_domains[0], "name")
  compartment_id      = var.tenancy_ocid
  shape               = "VM.Standard.E3.Flex"
  display_name        = "app"

  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  create_vnic_details {
    assign_public_ip = false
    subnet_id        = oci_core_subnet.dev.id
  }
  source_details {
    source_id   = data.oci_core_images.this.images[0].id
    source_type = "image"
  }
  preserve_boot_volume = false
}
```

With the above lines deleted, the environment should be back to a single VCN and two Subnets.

The [next tutorial](/tutorials/tf-201/2-remotes) will cover [Remote state in Terraform](/tutorials/tf-201/2-remotes).