---
title: Deploy a modern data lake on OCI
parent: [tutorials]
description: Using Terraform to create a data lake on Oracle Cloud Infrastructure. 
thumbnail: assets/datalakeocichart_4481-9331b237844018b1.png
author: Ali Mukadam
tags: [kubernetis, devops, terraform, oci]
category: clouddev
date: 2021-10-29 12:00
---
{% imgx aligncenter assets/datalakeocichart_4481-9331b237844018b1.png "OCI Datalake Architecture Overview" %}

## Resource Manager Deployment

This Quick Start uses [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment easy, sign up for an [OCI account](https://cloud.oracle.com/en_US/tryit) if you don't have one, and just click the button below:

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-datalake/releases/download/0.1/master.zip)

After logging into the console you'll be taken through the same steps described
in the **Deploy** section below.

Note, if you use this template to create another repo you'll need to change the link for the button to point at your repo.

## Local Development

Make sure your credentials are defined in $HOME/.oci/config file. As Terraform takes takes the default value from the .oci/config file

```console
For eg : [DEFAULT]
user=ocid1.user.oc1..aaaaaxxxwf3a \
fingerprint=de:50:15:13:...:d6 \
key_file=/Users/shadab/.oci/oci_api_key.pem \
tenancy=ocid1.tenancy.oc1..aaaaaaaa2txfa \
compartment=ocid1.compartment.oc1..aaaa5pti7sq \
region=us-ashburn-1

$ git clone https://github.com/oracle-quickstart/oci-datalake && cd oci-datalake
```

### Initialize
Initialize Terraform provider for OCI and Random

```console
$ terraform init
```

### Build Plan

```console
$ terraform plan -var-file=config.tfvars -out oci_datalake.out
```

### Apply

```console
$ terraform apply "oci_datalake.out"
```

### Destroy

```console
$ terraform destroy -var-file=config.tfvars
```

## Deploy with ORM

1. [Login](https://console.us-ashburn-1.oraclecloud.com/resourcemanager/stacks/create) to Oracle Cloud Infrastructure to import the stack

    ```
    > Home > Solutions & Platform > Resource Manager > Stacks > Create Stack
    ```

2. Upload the `master.zip` and provide a name and description for the stack

    {% imgx aligncenter assets/datalakeoci_4a6e6eb3_bbfb_d66353a189bc.png "Create Stack Dialog" %}

3. Configure the Stack. The UI will present the variables to the user dynamically, based on their selections. 
