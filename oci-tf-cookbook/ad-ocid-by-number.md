---
title: Get the AD OCID by AD number
series: oci-tf-cookbook
thumbnail: assets/cookbook.jpg
author: tim-clegg
tags: [open-source, terraform, iac, devops]
solution_names: [Administrative Domain - getting OCID by AD number, AD - getting OCID by AD number, IAM - getting the AD OCID programmatically]
---

## Problem
There are times when it's necessary to get the OCID of an Administrative Domain (AD).  How can this be done?

## Solution
This is similar to the solution for getting the name of an AD by friendly number.  Instead of getting the name, we'll get the OCID.

```
# Get all availability domains for the region
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}
```

Now use it within your resource definition(s):

```
# Then use it to get a single AD name based on the index:
  ...
  availability_domain_id = data.oci_identity_availability_domains.ads.availability_domains[0].id
  ...
}
```

This can also be refactored into a local:

```
locals {
  ad_ids = { for y in data.oci_identity_availability_domains.this.availability_domains :
    index(data.oci_identity_availability_domains.this.availability_domains, y) => y.id
  }
}
```

Then used like so:
```
  ...
  availability_domain_id = local.ad_ids[0]
  ...
}
```
