---
title: Find the OCI home region programmatically
series: oci-tf-cookbook
thumbnail: assets/cookbook.jpg
author: tim-clegg
tags: [open-source, terraform, iac, devops]
solution_names: [IAM - get the home region programmatically,Region - get home region]
---

## Problem
Many OCI services have to interact with the home region, which might not be the region used by the primary OCI provider definition.  Is it possible to programmatically determine the home OCI region of a tenancy?

## Solution
Yes it is!  Typically the primary OCI provider will be a user-specified region, which might not be the home region.  In these situations, it's necessary to programmatically determine the home region (which may or may not be the same).

```
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "home-region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }
}

data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid
  
  filter {
    name   = "is_home_region"
    values = [true]
  }
}
```

Next setup a provider definition for the home region (the following assumes that you already have an OCI provider defined without an alias):

```
provider "oci" {
  alias        = "home"
  region       = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
  tenancy_ocid = var.tenancy_ocid
  ...
}
```

From within the resource blocks that need to talk to the home region, specify this provider, like the following:

```
resource "oci_identity_tag_namespace" "this" {
  provider = oci.home
  ...
}
```
