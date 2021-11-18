---
title: Database Infrastructure
parent: [tutorials,oci-iac-framework]
tags: [open-source, terraform, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/landing-zone.png
date: 2021-11-12 12:00:00
description: How to deploy database infrastructure on top of the OCLOUD framework
toc: true
author: kubemen
draft: true
---
{% imgx aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

# Autonomous Database - Shared

Oracle Cloud Infrastructure's Autonomous Database is a fully managed, preconfigured database environment with four workload types available:

- Autonomous Transaction Processing 
- Autonomous Data Warehouse 
- Oracle APEX Application Development 
- Autonomous JSON Database 

You don't need to configure or manage any hardware or install any software. After provisioning, you can scale the number of CPU cores or storage capacity of the database at any time without impacting availability or performance. Autonomous Database handles creating the database, and the following maintenance tasks:

- Backing up the database
- Patching the database
- Upgrading the database
- Tuning the database

## Workload Types

**DWH**: Built for decision support and data warehouse workloads. Offers fast queries over large volumes of data.

**JSON**: Built for JSON-centric application development. Offers developer-friendly document APIs and native JSON storage. Note that Autonomous JSON Database is Oracle Autonomous Transaction Processing, but specialized for developing NoSQL-style applications that use JavaScript Object Notation (JSON) documents.

**ATP**: Built for transactional workloads. Offers high concurrency for short-running queries and transactions.

**APEX**: Optimized for application developers, who want a transaction processing database for application development using Oracle APEX, that enables creation and deployment of low-code applications, including databases.

This module enables you to quickly equip your tenancy with a [Oracle Cloud Infrastructure Free Tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) instance of a [Autonoumous Data - Shared](https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/adboverview.htm) .

## Prerequistes

In case of a ADB with private endpoints, deploy a Landing Zone whose VCN is used to create a private subnet.


## Mandatory Steps

1. Create DB **Compartment**
1. Create Database **User Groups**
1. Create **Policies**
1. Create ADB
    1. Select **VCN**
    2. Enter **Compartment Name**, defaults to ...
    3. Enter **Database Name**, defaults to ....
    4. Select **Workload Type**, defaults to DWH
    5. Enter **Admin Password**
    6. Select **Database Version**, defaults to 19c
    7. Enter **Free Form Tags** 
     

## Optional Steps

1. Select **Private Endpoint** Option
1. Create **Private Subnet**
1. Create **Network Security Group**
1. Enter Database **Display Name**, defaults to ...

## Advanced Parameter

1. cpu_core_count
1. are_primary_whitelisted_ips_used
1. is_auto_scaling_enabled
1. is_data_guard_enabled
1. kms_key_id
1. license_model
1. data_safe_status
1. data_storage_size_in_tbs
1. vault_id
1. whitelisted_ips
1. is_free_tier
1. defined_tags 

## Output

1. all_connection_strings
1. connection_urls


## Usage

1. Login to your tenancy
1. Go to Resource Manager
1. Create a stack
1. upload zip files 
1. Plan stack
1. Apply stack

## Validate

1. Access database
1. (Optional) Access APEX

## Addional Resources


[< base][base] | [+][home] | [app-infra >][app-infra] 

<!--- Links -->
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
