---
title: Get Compute Image OCID by Name
series: oci-tf-cookbook
thumbnail: assets/cookbook.jpg
author: tim-clegg
tags: [open-source, terraform, iac, devops]
solution_names: [Compute - get compute image OCID by name, Compute image - get OCID by name,Image - get compute image OCID by name]
---

## Problem
OCI Compute Instances require the OCID of a Compute Image to be provided.  Hard-coding an OCID is rather risky, as Compute Images should be changed/updated rather regularly (and each new image will have a new OCID).  How can we get the OCID for a Compute Instance based on its friendly name, as found in [https://docs.oracle.com/en-us/iaas/images/](https://docs.oracle.com/en-us/iaas/images/)?

## Solution
```
data "oci_core_images" "this" {
  compartment_id = var.compartment_ocid
  filter {
    name = "state"
    values = ["AVAILABLE"]
  }
}

locals {
  list_images = { for s in data.oci_core_images.this.images :
    s.display_name =>
    { id = s.id,
      operating_system = s.operating_system
    }
  }
}

resource "oci_core_instance" "my_compute" {
  ...
  
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
  }
  
  ...
}
```

The `var.compute_image_name` can be set to something like `Oracle-Linux-8.4-2021.10.20-0` (found at the time of this writing at [https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/](https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/)).

What have we done here?  First, we retrieved the list of compute images (`data.oci_core_images.this`), then coerce this into a tuple, where the key is the name of the image.  Lastly, we grabbed the OCID (`id`) from the tuple, based on the name given in the `var.compute_image_name` input variable).

