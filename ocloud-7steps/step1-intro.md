---
title: Getting Started with Oracle Cloud Infrastructure (OCI)
parent: ocloud-7steps
tags: [open-source, terraform, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/landing-zone.png
date: 2021-10-18 20:00:00
description: You want to astart with OCI and do not know how - here is a short summary what OCI is all about it
toc: true
author: kubemen
---
{% img aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

Over the last two decades Cloud Computing has revolutionized the technological landscape, allowing companies to rent infrastructure instead of buidling rapidly-obsolescing hardware on-site. During this time, the architectual approach that combines infrastructure orchestration and application code into cloud services has evolved. Today, cloud user have a choice between technology stacks for virtual hosts, master-slave architectures and container cluster. Each stack wraps application code differently, relies on different methods to launch server and provides different mechansims to automate fail-over and scaling processes. For Enterprise IT organizations, managing a large variety of applications, choosing one particular stack is ususally not sufficient, because a single stack can not address the broad variety of functional and non-functional requirements. Multi-cloud, hence spreading workloads accross multiple cloud provider is a common strategy to address this constrain. However, deploying private workloads accross multiple public infrastructure stacks increases operational complexity significantly and comes with certain vulnaribilities. Adopting a second generation infrastructure service (IaaS) like [Oracle Cloud Infrastructure (OCI)][oci_cloud] is an attractive alternative. Purpose build hardware enables cloud providers to separate the orchestration layer from the hosts and allows cloud customers to build private data centers on prebuild infrastructure pools. Programming interfaces allow operators to build extensible service delivery platforms and service owners to modernize applications in incremental steps. The bare metal approach allows to run enterprise applications in a traditional way. Cloud ochstrators remain optional and can be added as managed service, but even than the user remain in control over the infrastructure resources. 

[<img alt="Global Presence" src="https://www.oracle.com/a/ocom/img/rc24-oci-region-map.png" title="Data Center Regions">][oci_regionmap]

Oracle operates a fast growing network of data centre to provide access to prebuild cloud infrastructure in more than 30 regions. In addition, Oracle builds private infrastructure pools on-demand and offers to extend these pools with edge compute or database nodes. In every data center, dedicated compute- and storage resources are isolated on a native layer three network. Orchstrators incl. hypervisor, container and network functions remain private by default - also in shared pools. Combining on open-source orchestration technologies with cloud agnostic monitoring and management services allows operators to build a control center for hybrid cloud services. End to end programmability ensures fast and flexible resource deployments, with platform components like middleware, integration and database infrastructure, provided either as managed or as unmanaged service to offer a choice between convenience and control. In any case, standard hardware controls like the [integrated lights out manager (ILOM)][oci_ilom] and [off-box vitrualization][oci_offbox] allow to address regional privacy regulations and compliance requirements.  

## Oracle Cloud Infrastructure Benefits

### Autonomous services
OCI is the exclusive home of Oracle Autonomous Database and its self-repairing, self-optimizing autonomous features. Leveraging machine learning to automate routine tasks, Autonomous Database delivers higher performance, better security, and improved operational efficiency, and frees up more time to focus on building enterprise applications.  

[Gartner: Critical Capabilities for Operational Database Management Systems](https://www.oracle.com/database/gartner-dbms.html)  

### Reduce Costs and enhance performance
Oracle Cloud Infrastructure is built for enterprises seeking higher performance, lower costs, and easier cloud migration for their existing on-premises applications, and better price-performance for cloud native workloads. Read how customers have moved from AWS to Oracle Cloud Infrastructure, substantially reducing their costs and enhancing their compute platform performance.  

[Compare against AWS](https://www.oracle.com/cloud/economics/)  
[Read Gartners perspective on Oracles public cloud](https://www.oracle.com/cloud/gartner-oci.html)

### Easily migrate enterprise apps
Traditional, on-premises workloads that enterprises rely on to run their business are easier to migrate to Oracle Cloud. Designed to deliver bare-metal compute services, network traffic isolation, and the only service-level guarantees for performance, Oracle Cloud enables rapid migration and faster time to innovation. Build new value around migrated applications faster with Autonomous Database, data science tools, and our cloud native development tools.  

[Learn why Oracle apps run best on OCI](https://www.oracle.com/cloud/migrate-applications-to-oracle-cloud/)   
[Start migrating your custom apps to OCI](https://www.oracle.com/cloud/migrate-custom-applications-to-cloud/)

### Best support for hybrid architecture
Deploy your cloud applications and databases anywhere with a wide choice of options, ranging from our public regions to edge devices. In addition to our public cloud region, we offer full private Dedicated Regions in customers data centers, edge-computing Oracle Roving Edge devices, and our blazingly fast Oracle Exadata Cloud@Customer, with Autonomous Database service delivered behind your firewall. With full support for VMware environments in the customer tenancy as well, Oracle offers cloud computing that works the way you expect.  

[Learn about hybrid, multicloud, and intercloud deployment options](https://www.oracle.com/cloud/cloud-deployment-models/)  
[Oracle Brings the Cloud to You (PDF)](https://www.oracle.com/a/ocom/docs/engineered-systems/exadata/idc-adb-on-exac-at-cloud.pdf)

Oracle Cloud Infrastructure (OCI) is a deep and broad platform of public cloud services that enables customers to build and run a wide range of applications in a scalable, secure, highly available, and high-performance environment.  
For on-premises requirements, OCI is available with the new Dedicated Region Cloud@Customer—behind a company’s private firewall and in their data center. 

A detailed "Getting Started Guide" is part of our documentation and available here: [Getting Started with OCI][oci_intro]

This introduction targets future operation engineers is structured as follows.
* [Automating with Terraform][provider]
* [Base Configuration][base]
* [Database Infrastructure][db-infra]
* [Application Infrastructure][app-infra]
* [Workload Deployment][workload]
* [Governance][governance]
* [Vizualizer][vizualize]


Cloud operations engineering is a relatively new field extending the scope of IT service management (ITSM). It represents an important step towards more agility and flexibilty in service operation. The concept of "Infrastructure as Code" replaces runbook tools and has become an enabler for self-service delivery - even for complex solution architectures. Operators empower service owners and developers to add, change or delete infrastructure on demand with deployment templates for logical resources. Service consumers gain flexibility to provision virtual infrastructure while resource operators remain in control of the physical infrastructure. This repository aims to provide a path for IT Organizations introducing cloud engineering. We starts with a short introduction about Infrastructure as Code, show how to define logical resources for application and database services and end with as an example how to consolidate infrastructure and application services in a self-service catalogue. We build on the official [Oracle Cloud Architect training][oci_training], that prepares administrators for the [Oracle Architect Associate exam][oci_certification], but aim to extend the [Learning Path][oci_learning], with tool recommendations and code examples for cloud engineers.

[< home][home] | [+][intro] | [provider >][provider] 

<!--- Links -->
[home]:       index
[intro]:      step1-intro
[provider]:   step1-provider
[base]:       step2-base
[db-infra]:   step3-dbinfra
[app-infra]:  step4-appinfra
[workload]:   step5-workload
[governance]: step6-governance
[vizualize]:  step7-vizualize

[oci_certification]: https://www.oracle.com/cloud/iaas/training/architect-associate.html
[oci_cli]:           https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/
[oci_cloud]:         https://www.oracle.com/cloud/
[oci_cloudshell]:    https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm
[oci_data]:          https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[oci_sdk]:           https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm
[oci_freetier]:      http://signup.oraclecloud.com/
[oci_global]:        https://www.oracle.com/cloud/architecture-and-regions.html
[oci_learn]:         https://learn.oracle.com/ols/user-portal
[oci_learning]:      https://learn.oracle.com/ols/learning-path/become-oci-architect-associate/35644/75658
[oci_homeregion]:    https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Tasks/managingregions.htm
[oci_identifier]:    https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
[oci_identity]:      https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_availability_domains
[oci_ilom]:          https://www.oracle.com/servers/technologies/integrated-lights-out-manager.html
[oci_offbox]:        https://blogs.oracle.com/cloud-infrastructure/first-principles-l2-network-virtualization-for-lift-and-shift
[oci_provider]:      https://github.com/terraform-providers/terraform-provider-oci
[oci_region]:        https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_regions
[oci_regions]:       https://www.oracle.com/cloud/data-regions.html
[oci_regionmap]:     https://www.oracle.com/cloud/architecture-and-regions.html
[oci_sdk]:           https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm
[oci_tenancy]:       https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/settinguptenancy.htm
[oci_training]:      https://www.oracle.com/cloud/iaas/training/
[oci_intro]:         https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/baremetalintro.htm


[tf_doc]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[cli_doc]: https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/
[iam_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm
[network_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm
[compute_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/Concepts/computeoverview.htm#Overview_of_the_Compute_Service
[storage_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm
[database_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Database/Concepts/databaseoverview.htm

[iam_video]: https://www.youtube.com/playlist?list=PLKCk3OyNwIzuuA-wq2rVuxUE13rPTvzQZ
[network_video]: https://www.youtube.com/playlist?list=PLKCk3OyNwIzvHm2E-cGrmoMes-VwanT3P
[compute_video]: https://www.youtube.com/playlist?list=PLKCk3OyNwIzsAjIaUaVsKdXcfBOy6LASv
[storage_video]: https://www.youtube.com/playlist?list=PLKCk3OyNwIzu7zNtt_w1dXFOUbAjheMeo
[database_video]: https://www.youtube.com/watch?v=F4-sxIsnbKI&list=PLKCk3OyNwIzsfuB9kj1CTPavjgByJBXGK

[jmespath_site]: https://jmespath.org/tutorial.html
[jq_site]: https://stedolan.github.io/jq/
[jq_play]: https://jqplay.org/
[json_validate]: https://jsonlint.com/

[vsc_site]: https://code.visualstudio.com/

[terraform]: https://www.terraform.io/
[tf_examples]: https://github.com/terraform-providers/terraform-provider-oci/tree/master/examples
[tf_lint]: https://www.hashicorp.com/blog/announcing-the-terraform-visual-studio-code-extension-v2-0-0

[oci_regions]: https://www.oracle.com/cloud/data-regions.html
