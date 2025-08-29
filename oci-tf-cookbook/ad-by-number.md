---
title: Get the AD name by user-friendly number
series: oci-tf-cookbook
thumbnail: assets/cookbook.jpg
author: tim-clegg
tags: [open-source, terraform, iac, devops]
solution_names: [Administrative Domain - get AD name by the AD number,AD - get AD name by the AD number,IAM - get AD name by the number]
---

## Problem
Rather than use the AD name, it'd be nice to use the AD number.

## Solution
Use a handy [data source](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_availability_domains) to make this happen:
```
data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}
```

Then within your resource definition(s), use the data source:
```
resource "oci_core_instance" "this" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  ...
}
```

This could be abbreviated with a local, such as:
```
locals {
  ad_names = { for y in data.oci_identity_availability_domains.this.availability_domains :
    index(data.oci_identity_availability_domains.this.availability_domains, y) => y.name
  }
}
```

This can be used as follows:
```
resource "oci_core_instance" "this" {
  availability_domain = local.ad_names[0]
  ...
}
```

Note that this uses zero-index array, with index 0 being AD 1, index 1 being AD 2, etc.:

| Index # | AD # | Example |
|---------|------|---------|
| 0 | 1 | local.ad_names[0] |
| 1 | 2 | local.ad_names[1] |
| 2 | 3 | local.ad_names[2] |

If you'd like the index to match the AD number, change the local as-follows:

```
locals {
  ad_names = { for y in data.oci_identity_availability_domains.this.availability_domains :
    index(data.oci_identity_availability_domains.this.availability_domains, y) + 1 => y.name
  }
}
```

Then use it as follows:

```
local.ad_names[1] # AD 1
local.ad_names[2] # AD 2
local.ad_names[3] # AD 3
```