---
title: Get the most recent Compute Image OCID
series: oci-tf-cookbook
thumbnail: assets/cookbook.jpg
author: tim-clegg
tags: [open-source, terraform, iac, devops]
solution_names: [Compute - get the latest compute image OCID for a given distro, Compute image - get the latest distro OCID,Image - get latest compute image OCID]
---

## Problem
While it's possible to get the OCID of a compute instance image by name, it can often be ideal to always use the latest image (whatever it may be).  How can this be done?

## Solution
```
data "oci_core_images" "latest_ol8" {
  compartment_id = var.tenancy_ocid
  operating_system = "Oracle Linux"
  operating_system_version = 8.0
  shape = "VM.Standard2.1"
  state = "AVAILABLE"
  sort_by = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "my_compute" {
  ...
  
  source_details {
    source_id = data.oci_core_images.latest_ol8.images.images[0].id
    source_type = "image"
  }
  
  ...
}
```

The shape, OS, etc. can all be customized.  The key here is to use the sort attributes to allow you to select the first element in the returned results.  This gives you an idea of what you can do to solve this need!

To make this a bit cleaner, a local could be defined:

```
locals {
  latest_ol8_image_id = data.oci_core_images.latest_ol8.images.images[0].id
}
```

Then you can use it like:

```
resource "oci_core_instance" "my_compute" {
  ...
  
  source_details {
    source_id = local.latest_ol8_image_id
    source_type = "image"
  }
  
  ...
}
```

Just a bit cleaner!