---
title: Database Infrastructure
parent:
- tutorials
- oci-iac-framework
tags:
- open-source
- terraform
- iac
- devops
- get-started
categories:
- iac
- opensource
thumbnail: assets/landing-zone.png
date: 2021-12-01 12:00
description: How to deploy database infrastructure on top of the OCLOUD framework
toc: true
author: kubemen
mrm: WWMK211201P00070
xredirect: https://developer.oracle.com/tutorials/oci-iac-framework/getting-started-with-oci-step-3-database-infrastructure/
slug: getting-started-with-oci-step-3-database-infrastructure
---
{% imgx aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

## Overview of the Oracle Database Cloud Service

{% imgx aligncenter assets/dbcs_overview.png 1200 494 "Database System Overview" "Database System Overview" %}

The Oracle Database Cloud Service offers autonomous and co-managed Oracle Database cloud solutions. Autonomous databases are preconfigured, fully-managed environments that are suitable for either transaction processing or data warehouse workloads. Co-managed solutions are virtual machine and Exadata DB systems that you can customize with the resources and settings that meet your needs.  

You can quickly provision an Autonomous Database or co-managed DB system. You have full access to the features and operations available with the database, but Oracle owns and manages the infrastructure.  

You can also extend co-managed database services into your data center by using Exadata Cloud@Customer, which applies the combined power of Exadata and Oracle Cloud Infrastructure while enabling you to meet your organization's data-residency requirements.  

For details about each offering, start with the following overview topics:  

- **Autonomous Databases**

  The Database service offers Oracle's [Autonomous Databases] with transaction processing and data warehouse workload types.

- **Co-managed Systems**

  - [Virtual Machine DB Systems]
  - [Exadata Cloud Service]
  - [Exadata Cloud@Customer]

## Database Cloud Service on Virtual Machine

Database Cloud Service offers full-featured Oracle Database cloud instances:  

- Enterprise Edition or Standard Edition 2
- Multiple Oracle Database versions, including [21c]
- 4 tiers of Oracle Database License Included options or Bring Your Own License
- Enhanced with Cloud automation features

In addition to our Oracle Database Cloud Solution (DBCS), we also offer managed MySQL Cloud Services and other Data Management Cloud Services.

### Cloud automation under customer control - provisioning, patching, backup, disaster recovery

{% imgx aligncenter assets/dbcs_features.png 1200 737 "DBCS Features" "DBCS Features" %}

## Database Cloud Service Provisioning using Terraform and OCI Resource Manager

Database Cloud Service on VM is an exceptional entry into the world of cloud-supported database services. First, you keep full control of your database servers and databases. Plus, the service includes many convenient functions which simplify and accelerate the creation and configuration of database systems. But not only that, with just a few clicks your database can be enhanced with additional features to accommodate growing demands or needed adjustments. These include CPU and storage scaling as well as the creation of a standby database through Data Guard.  

When creating a Database Cloud Service on VM all the cloud resources you need to get a fully operational database instance going are provisioned:  

- Compute instance instantiates a Real Application Cluster (RAC)
- Block storage is made available to the database nodes
- Object Store is used to store automated and manual backups

>**Notes:**  
>
>- All DBCS resources are only accessible through the Database System resource, not through the individual categories as Compute Instances or Object Store.
>
>- All DBCS components are created as part of the Database System resource. Therefore you won't find them under the Compute Instance or Object Storage Categories in the OCI console.
{:.notice}

## Prepare the OCloud Landing Zone

Before we create a DBCS on VM resource, we'll set up a Compartment, a Virtual Cloud Network (VCN), and a Subnet. You can do this either through the OCI console or through Terraform using OCI’s Rest API. The latter method is used for this session.  

**Reference:** Instructions on how to deploy OCloud Landing Zone can be found in this [article](https://github.com/oracle-devrel/terraform-oci-ocloud-landing-zone).

### DBCS architecture

{% imgx aligncenter assets/ocloud_dbcs_architecture.png 1200 648 "DBCS Architecture" "DBCS Architecture" %}

Policies for the Database Compartment allow members of the dbops group to create database subnets and to manage database-family resources:  

```sql
- ALLOW GROUP <label>_dbops manage database-family in compartment <label>_database_compartment
- ALLOW GROUP <label>_dbops read all-resources in compartment <label>_database_compartment
- ALLOW GROUP <label>_dbops manage subnets in compartment <label>_database_compartment
```

## OCloud Remote Stack

Now, to create the database system resource the OCI Rest API requires a target compartment and a target subnet. There are three different ways to collect information in OCI:  

1. By default, the Terraform stack defines the required parameters itself, but they can also be entered by the user when the stack is created in OCI Resource Manager (ORM).
1. Both the `Database Compartment OCID` and `VNC OCID` are queried from OCI as data elements:

      ```terraform
      # In this example a list of all compartments within a Tenant is returned which is filtered by the database compartment name
      data "oci_identity_compartments" "db_compartment" {
         compartment_id = <tenancy_ocid>
         compartment_id_in_subtree = true
         state          = "ACTIVE"
         filter {
            name   = "name"
            values = [ <Datenbank Compartment Name> ]
         }
      }
      ```

1. Terraform supports direct access to the output data of previously provisioned stacks through `oci_resourcemanager_stack_tf_stat` and `terraform_remote_state` resources. For this object-relational mapping (ORM), Terraform extracts the desired information from the Terraform `tfstate` file which is stored as part of a successfully deployed OCI Stack:  

      ```terraform
      data "oci_resourcemanager_stack_tf_state" "stack1_tf_state" {
         stack_id   = <stack id>
         local_path = "stack1.tfstate"
      }

      # Load the pulled state file into a remote state data source
      data "terraform_remote_state" "external_stack_remote_state" {
         backend = "local"
         config = {
            path = "${data.oci_resourcemanager_stack_tf_state.stack1_tf_state.local_path}"
         }
      }
      ```

>**Note:** In practice, several of these methods will likely be used in combination.
>{:.notice}

## Creating the Database Subnet

After validating the prerequisites for a DBCS on VM deployment, we'll now provision the resources for the DBCS on a VM stack.  

For this use case, all members of the dbops group should be able to create subnets and database resources within the Tenant’s Database Compartment’s limits. For creating subnets, we use a dedicated Terraform module that is provided by the terraform-oci-ocloud-landing-zone repository.  

**Reference:** [Network domain](https://github.com/oracle-devrel/terraform-oci-ocloud-landing-zone/tree/main/component/network_domain)

The *network_domain* module, which is also used as part of the landing zone provisioning, creates a private subnet as well as all required Security List Policies to communicate with the database system.  

When sizing the subnet, you should pay attention to the minimum required IP addresses for a certain deployment type (single node vs RAC). The OCloud landing zone defines the bigger subnets for each service, but if the database architecture requires one large subnet, the Terraform function `cidrsubnets(prefix,newbits,netum)` allows you to split the address space into smaller chunks:  

| service_segment_subnets | key subnet |
|---|---|
| app | 10.0.0.0/26 |
| db | 10.0.0.64/26 |
| pres | 10.0.1.0/26 |
| k8s | 10.0.0.128/25 |

Below, you can see an example where CIDIR block 10.0.0.64/26 is split into four subnets by adding two additional bits (newbits):  

```terraform
> cidrsubnets("10.0.0.64/26",2,2,2,2)
 tolist([
   "10.0.0.64/28",  --->  cidrsubnet("10.0.0.64/26",2,0)
   "10.0.0.80/28",  --->  cidrsubnet("10.0.0.64/26",2,1)
    "10.0.0.96/28",  --->  cidrsubnet("10.0.0.64/26",2,2)
   "10.0.0.112/28",  --->  cidrsubnet("10.0.0.64/26",2,3)
])
```

The Terraform module `network_domain` creates a private subnet for a given database compartment and VNC. It also sets all ingress rules to allow ssh access to the Database nodes and to communicate with the database itself. Last but not least, it sets all egress rules to access  both Object Storage and YUM Repository on the Service Network.  

It's important to note here that the *db_domain* module doesn’t define its own Bastion Service since it's available through the application subnet. However, after provisioning the database, a couple of Bastion Sessions are created (ssh, sqlnet) aiming to validate database system connectivity. Once the Time-to-Live has been exceeded for the Bastion Sessions, they will be terminated automatically.

### Resource Schema

```terraform
module "db_domain" {
  …
  source = "github.com/oracle-devrel/terraform-oci-ocloud-landing-zone/component/network_domain"
  config  = {
    service_id     = <Container Compartment ID>
    compartment_id = <Database Compartment ID>
    vcn_id         = <VNC ID>
    anywhere       = “0.0.0.0/0”
    defined_tags   = null
    freeform_tags  = {"framework" = "ocloud"}
  }
  # Subnet Requirements
  # DB System Type, # Required IP Addresses, Minimum Subnet Size
  # 1-node virtual machine, 1 + 3 reserved in subnet = 4, /30 (4 IP addresses)
  # 2-node RAC virtual machine, (2 addresses * 2 nodes) + 3 for SCANs + 3 reserved in subnet = 10, /28 (16 IP addresses)
  subnet  = {
    # Select the predefined name per index
    domain                      = <predefined subnet postfix (See OCloud Landing Zone, module service_segment)>
    # Select the predefined range per index
    cidr_block                  = <predefined subnet cidr block (See OCloud Landing Zone, module service_segment)>>
    # Create subnet as private
    prohibit_public_ip_on_vnic  = true # Creates a private subnet
    dhcp_options_id             = null
    route_table_id              = <Routing Table ID for Oracle Service Network connectivity which is created by the OCloud Landing Zone>
  }
  bastion  = {
    create            = false # Determine whether a bastion service will be deployed and attached
    client_allow_cidr = []
    max_session_ttl   = null
  }
  # Security List Policies
  tcp_ports = {
    // [protocol, source_cidr, destination port min, max]
    ingress = [
      ["ssh", “0.0.0.0/0”, 22, 22], # DBnode access
      ["http", “0.0.0.0/0”, 80, 80], # APEX access
      ["https", “0.0.0.0/0”, 443, 443], # APEX access
      ["tcp", “0.0.0.0/0”, 1521, 1522], # DB Access where 1521 is used for DBCS and 1522 for Autonomous DB
      ["tcp", “0.0.0.0/0”, 5500, 5500], # Enterprise Manager Express access
      ["tcp", “0.0.0.0/0”, 6200, 6200] # Enables the Oracle Notification Services (ONS) to communicate about Fast Application Notification (FAN) events
    ]
  }
```

## Database System Provisioning

Now that all of our prerequisite resources are created, we're ready to set up the final components. The OCI resource *oci_database_db_system* provisions a database system, database nodes, and an initial CDB and PDB all in one step. Convenient, no? Note that the *oci_database_db_system* comes with many additional parameters to support other flavors of provisioning a database (e.g, creating a database instance from a backup or as clone from an existing database system). For this scenario, we'll focus on a fresh database install. Refer to the *oci_database_db_system* resource documentation for further details.  

```terraform
resource "oci_database_db_system" "dbaas_db_system" {
  availability_domain = <Availability Domain>
  compartment_id      = <Database Compartment>
  database_edition    = <Database Edition, i.e. ENTERPRISE EDITION>

  db_home {
    database {
      admin_password = <SYS PASSWORD>
      db_name        = <CDB Name>
      character_set  = <Character Set>
      ncharacter_set = <International Character Set>
      db_workload    = <Workload Type, OLTP or DW>
      pdb_name       = <PDB Name>
      tde_wallet_password = <TDE Wallet Password if it is different to the admin_password>

      db_backup_config {
        auto_backup_enabled = <Is automated backup to Object Storage enabled?>
        auto_backup_window = <Two hour time slot within 24 hour when the backup can take place>
        recovery_window_in_days = <Retention Period>
      }
    }

    db_version   = <Database Version, whereas 19.0.0.0.0 corresponds to the latest available version, i.e. 19.12.0.0.0
    display_name = <>
  shape           = <Database Node Shape which defines the number of OCPUs and Memory>
  subnet_id       = <Target Database Subnet>
  ssh_public_keys = [<Public Key for ssh access>]
  display_name    = <OCI Display Name>
  hostname                = <DB Node Hostname Prefix>
  data_storage_size_in_gb = <Initial Database Storage>
  license_model           = <Database License is either included or transferred from On Premise >
  node_count              = <Database Node Count, 1 or 2 for a Real Application Cluster>
  cluster_name            = <RAC Cluster name>
  nsg_ids                 = <Optional Network Security Group>
  db_system_options {
    storage_management = <LVM or ASM>
  }
}
```

## OCI Resource Manager

To use DBCS on a VM stack with Resource Manager, you'll need to use one of the following methods:

- [download the code as a zip-file](https://github.com/oracle-devrel/terraform-oci-ocloud-db/tree/main)  
  After extracting the archive, select **Deploy to Oracle Cloud** within the Github repository’s [Readme](https://github.com/oracle-devrel/terraform-oci-ocloud-db/blob/updates/README.md) for further information.
- create your own cloned repository on Gitlab or Github  
  Note that the DBCS stack references [network_domain](https://github.com/oracle-devrel/terraform-oci-ocloud-landing-zone/tree/main/component/network_domain), so if you are using a customized version of the landing zone stack you might have to update the `source` parameter of the *db_domain* module.

### Deploy to Oracle Cloud

For this session, we'll use the **Deploy to Oracle Cloud** method from the stack’s Readme. This option automatically redirects you to the OCI Console login, and after authentication opens Resource Manager. **Package URL** points to the stack artifact which is stored within the Github repository. Finally, confirm the **Terms of Use**.  

#### Setting up Resource Manager

- **Configure manually**
  1. **Name the DBCS stack and select a compartment -** To get started, let's enter a meaningful name for your DBCS stack and choose a Compartment where your stack resource will be created.  
     >**Note:** The stack compartment may differ from the Compartment where the actual infrastructure resources reside.
     {:.notice}

  2. **Database configuration -** On the next page, you'll finalize the database system configuration. Enter the landing zone’s `Stack OCID`, which can be found in Resource Manager next to the landing zone stack. This avoids the need to re-enter a lot of the parameters and enables access to Output artifacts from the landing zone.

  3. **Database System display name -** Enter a *Database System display name*. Then, either accept the shown default values or adjust them to you needs.  

     For a default deployment, the following values are used:  

     | Configuration | Database Version | Oracle Database Software Edition | Shape | OCPUs | Storage(GB) |
     |---|---|---|---|---|---|
     | Small | 19c | Oracle Enterprise Edition | VM.Standard2.2 | 2 | 512 |

     | Deployment Type | Storage Management Software | Auto Backup enabled? | Node Count |
     |---|---|---|---|
     | Fast Provisioning | LVM | false | 1 |

  4. **Authentication -** Finally, enter the admin or sys password and the public part of your ssh key. Make sure that you update the admin password after installation as the initial password will show up in the Terraform `tfstate` file.

- **Configure using a `terraform.tfvars` file**
Another way to preconfigure parameters is to manually download the Terraform code from the repository and add a `terraform.tfvars` file. The respective values are shown as read-only parameters in the stack configuration.  

  **Example:**  

    ```terraform
    db_system_display_name = "OCI Database System Display Name"
    db_system_ssh_public_keys = "ssh-rsa …"
    db_system_db_home_database_admin_password = "Password"
    stack_id = "ocid1.ormstack.oc1.eu-frankfurt-1.aaaaaaaaqyekvuodrozodmn23zxi…"
    ```

#### Alternative methods for deploying a database system

OCloud DBCS on VM Stack supports other ways to deploy a database system, but they're not the subject of this session:  

- Deploy a Database System into an existing subnet
- Overwrite Organization, Project and Environment labels which were defined by the corresponding OCloud Landing Zone
- Customize all stack parameters

For further information, refer to the OCloud DBCS on VM stack’s [Readme](https://github.com/oracle-devrel/terraform-oci-ocloud-db/blob/updates/README.md).

### Plan but don’t apply

>Create the stack but don’t check **Run Apply** because you should always plan your deployment first.
{:.alert}  

This step is very important since it checks the stack code for syntax errors and determines exactly which OCI resources are going to be added, updated, or destroyed. Since OCI resources contain both updatable and non-updatable parameters, it's recommended that the planning task be made a required part of the set up routine since updating a non-updatable value *may result in destruction of the resource*.  

**Sample plan output:**

```console
Plan: 9 to add, 0 to change, 0 to destroy.
```

After verifying the expected results, the stack can be applied.  
>**Note:** For a "Small" configuration set up with "Fast Provisioning" it can take between 20 and 25 minutes before the database is available.
{:.notice}

### Verify DB Node and Database access

Once the Database System, Container Database, and Pluggable Database are available you can verify connectivity. Since our target resource is in a private subnet, the *Apps Compartments Bastion Service* needs to be used as the Bastion Sessions were created as part of the DBCS stack.  

| Protocol | Session type | IP Address | Port | Maximum session time-to-live (min) ||
|---|---|---|---|---|---|
| ssh | SSH Port Forwarding Session | Host IP | 22 | 1800 | ssh access to database node(s) |
| sqlnet | SSH Port Forwarding Session | Host IP | 1521 | 1800 | sqlplus, sqlcl or sqldeveloper |

**SSH:**

Copy the SSH command from OCI console (Bastion Session) to create an SSH tunnel from `localhost:localport` to `<database node ip address>:22`.  

```console
ssh -i <private key file path> -N -L <local port>:<database node ip address>:22 -p 22 <bastion session OCID>@host.bastion.eu-frankfurt-1.oci.oraclecloud.com
```

To ssh to the DB Node, use the following command:  

```console
ssh -i <private key file> opc@localhost -p <local port>
```

**Oracle SQL Developer:**

For an Oracle SQL Developer connection to either the CDB or PDB, copy the SSH command from OCI console (Bastion Session) to create an ssh tunnel from `localhost:localport` to `<database node ip address>:1521`:  

```console
ssh -i <private key file> -N -L <local port>:<database node ip address>:1521 -p 22 <bastion session OCID>@host.bastion.eu-frankfurt-1.oci.oraclecloud.com
```

Open sqldeveloper and create a new database connection:  

| Parameter | Value |
|---|---|
| Username | sys |
| Password | admin password |
| Role | SYSDBA |
| Connection Type | Basic |
| Hostname | localhost |
| Port | [local sql port] |
| Service Name | CDB or PDB SERVICE_NAME from DBCS output |

**SQLcl and SQLplus:**

For a sqlcl or sqlplus connection, copy the SSH command from OCI console (Bastion Session) to create a SSH tunnel from `localhost:localport` to `<database node ip address>:1521`.  

```console
ssh -i <private key file> -N -L <local port>:<database node ip address>:1521 -p 22 <bastion session OCID>@host.bastion.eu-frankfurt-1.oci.oraclecloud.com
```

**Execute:**  

```console
sql sys@localhost:1523/<FQ Database Name> AS sysdba
or
sqlplus sys@<FQ Database Name> AS sysdba
```

And now you've logged into the database, congratulations!

## What's next

We successfully provisioned a Database Cloud Service on VM Database instance. From here, you can apply further adjustments or add additional stacks to your OCI Infrastructure in your Tenancy.  

Happy building!  

Up next, [App Infrastructure].

<!--- links -->

[Autonomous Databases]: https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/adboverview.htm#Overview_of_Autonomous_Databases
[Virtual Machine DB Systems]: https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/overview.htm#Bare
[Exadata Cloud Service]: https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/exaoverview.htm#Exadata_DB_Systems
[Exadata Cloud@Customer]: https://docs.oracle.com/en-us/iaas/exadata/index.html
[21c]: https://blogs.oracle.com/database/post/introducing-oracle-database-21c

[App Infrastructure]: ./getting-started-with-oci-step-4-app-infrastructure.md

[home]:       index
[intro]:      getting-started-with-oci-intro.md
[provider]:   getting-started-with-oci-step-1-provider
[base]:       getting-started-with-oci-step-2-base
[db-infra]:   getting-started-with-oci-step-3-database-infrastructure
[app-infra]:  getting-started-with-oci-step-4-app-infrastructure
[workload]:   getting-started-with-oci-step-5-workload-deployment
[governance]: getting-started-with-oci-step-6-governance
[vizualize]:  step7-vizualize

[learn_doc_iam]:        https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm
[learn_doc_network]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm
[learn_doc_compute]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/Concepts/computeoverview.htm#Overview_of_the_Compute_Service
[learn_doc_storage]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm
[learn_doc_database]:   https://docs.cloud.oracle.com/en-us/iaas/Content/Database/Concepts/databaseoverview.htm
[learn_doc_vault]:      https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm
[learn_video_iam]:      https://www.youtube.com/playlist?list=PLKCk3OyNwIzuuA-wq2rVuxUE13rPTvzQZ
[learn_video_network]:  https://www.youtube.com/playlist?list=PLKCk3OyNwIzvHm2E-cGrmoMes-VwanT3P
[learn_video_compute]:  https://www.youtube.com/playlist?list=PLKCk3OyNwIzsAjIaUaVsKdXcfBOy6LASv
[learn_video_storage]:  https://www.youtube.com/playlist?list=PLKCk3OyNwIzu7zNtt_w1dXFOUbAjheMeo
[learn_video_database]: https://www.youtube.com/watch?v=F4-sxIsnbKI&list=PLKCk3OyNwIzsfuB9kj1CTPavjgByJBXGK
[learn_video_vault]:    https://www.youtube.com/watch?v=6OyrVWSL_D4

[oci_identity]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_availability_domains
[oci_l2]:       https://blogs.oracle.com/cloud-infrastructure/first-principles-l2-network-virtualization-for-lift-and-shift
[oci_landing]: https://docs.oracle.com/en/solutions/cis-oci-benchmark/
[oci_regional]: https://medium.com/oracledevs/provision-oracle-cloud-infrastructure-home-region-iam-resources-in-a-multi-region-terraform-f997a00ae7ed
[oci_compartments]: https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Concepts/settinguptenancy.htm#Understa
[oci_reference]:  https://docs.oracle.com/en/solutions/multi-tenant-topology-using-terraform/
[oci_policies]: https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Concepts/commonpolicies.htm
[oci_sdk_tf]: https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm
[oci_variable]: https://upcloud.com/community/tutorials/terraform-variables/#:~:text=Terraform%20variables%20can%20be%20defined,open%20the%20file%20for%20edit

[tf_boolean]:           https://medium.com/swlh/terraform-how-to-use-conditionals-for-dynamic-resources-creation-6a191e041857
[tf_count]:             https://www.terraform.io/docs/configuration/resources.html#count-multiple-resource-instances-by-count
[tf_compartment]:       https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_compartment
[tf_data_compartments]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_compartments
[tf_data_groups]:       https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_groups
[tf_data_policies]:     https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_policies
[tf_data_users]:        https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_users
[tf_doc]:               https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[tf_examples]:          https://github.com/terraform-providers/terraform-provider-oci/tree/master/examples
[tf_expression]:        https://www.terraform.io/docs/configuration/expressions.html
[tf_foreach]:           https://www.terraform.io/docs/configuration/resources.html#for_each-multiple-resource-instances-defined-by-a-map-or-set-of-strings
[tf_group]:             https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_group
[tf_intro]:             https://youtu.be/h970ZBgKINg
[tf_lint]:              https://www.hashicorp.com/blog/announcing-the-terraform-visual-studio-code-extension-v2-0-0
[tf_list]:              https://www.terraform.io/docs/language/values/variables.html#list-lt-type-gt-
[tf_loop]:              https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/
[tf_loop_tricks]:       https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
[tf_parameterize]:      https://build5nines.com/use-terraform-input-variables-to-parameterize-infrastructure-deployments/
[tf_pattern]:           https://www.hashicorp.com/resources/evolving-infrastructure-terraform-opencredo
[tf_policy]:            https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_policy
[tf_provider]:          https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[tf_pwd]:               https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_ui_password
[tf_resource]:          https://www.terraform.io/docs/configuration/resources.html
[tf_script]:            https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
[tf_sequence]:          https://www.terraform.io/docs/configuration/resources.html#create_before_destroy
[tf_ternary]:           https://github.com/hashicorp/terraform/issues/22131
[tf_type]:              https://www.terraform.io/docs/language/expressions/type-constraints.html
[tf_user]:              https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/identity_user
[tf_variable]:          https://www.terraform.io/docs/configuration/variables.html
[tf_module_vcn]:        https://registry.terraform.io/modules/oracle-terraform-modules/vcn/oci/latest

[code_compartment]: ../code/iam/compartment.tf
[code_user]:        ../code/iam/user.tf
[code_group]:       ../code/iam/group.tf
[code_policy]:      ../code/iam/policy.tf

[ref_cidr]:          https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing
[ref_cli]:           https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/
[ref_dgravity]:      https://whatis.techtarget.com/definition/data-gravity
[ref_dry]:           https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[ref_hostrouting]:   https://networkencyclopedia.com/host-routing/
[ref_iac]:           https://en.wikipedia.org/wiki/Infrastructure_as_code
[ref_jmespath]:      https://jmespath.org/tutorial.html
[ref_jq]:            https://stedolan.github.io/jq/
[ref_jq_play]:       https://jqplay.org/
[ref_json_validate]: https://jsonlint.com/
[ref_l2]:            http://sherpainthecloud.com/en/blog/why-oci-l2-support-is-a-big-deal
[ref_logresource]:   https://pubs.opengroup.org/architecture/togaf9-doc/arch/apdxa.html
[ref_nist]:          https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-145.pdf
[ref_sna]:           https://en.wikipedia.org/wiki/Shared-nothing_architecture
[ref_vsc]:           https://code.visualstudio.com/
[ref_vdc]:           https://www.techopedia.com/7/31109/technology-trends/virtualization/what-is-the-difference-between-a-private-cloud-and-a-virtualized-data-center

[itil_application]: https://wiki.en.it-processmaps.com/index.php/ITIL_Application_Management
[itil_operation]:   https://wiki.en.it-processmaps.com/index.php/ITIL_Service_Operation
[itil_roles]:       https://wiki.en.it-processmaps.com/index.php/ITIL_Roles
[itil_technical]:   https://wiki.en.it-processmaps.com/index.php/ITIL_Technical_Management
[itil_web]:         https://www.axelos.com/best-practice-solutions/itil
