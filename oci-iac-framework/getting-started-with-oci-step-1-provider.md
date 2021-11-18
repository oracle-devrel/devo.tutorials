---
title: Automating OCI with Terraform
parent: [tutorials,oci-iac-framework]
redirect_from: "/tutorials/7-steps-to-oci/getting-started-with-oci-step-1-provider"
tags: [open-source, terraform, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/landing-zone.png
date: 2021-10-26 19:00:00
description: You want to know how you can automate tasks on OCI - here you can find a short deep dive into automation with Terraform
toc: true
author: kubemen
date: 2021-10-29 08:00
---
{% imgx aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

Introducing Oracle Cloud Infrastructure for service delivery allows operators to represent physical and virtual infrastructure in the form of code. System administrators ensure server uptime and service levels, responding to infrastructure monitoring alerts and resolving incidents programmatically. Adopting ["Infrastructure as Code" (IaC)][tf_intro] helps operators to connect events and state changes with automated provisioning processes. 

While requesting a resource from a cloud provider is a matter of opening the console, providing input values, and launching the server, addressing functional and non-functional requirements of an IT operation during the launch process is more complex. Provisioning plans help to determine the correct framework, reflect the operational and management tools, and configure resources according to security and compliance regulations. In OCI, we rely on [Terraform][tf_main] to automate provisioning processes. The widely-adopted, open-source tool allows engineers to translate "declarative" syntax written in [JSON][tf_json] or [Hashicorp's Configuration Language (HCL)][tf_hcl] into API calls. 

## Getting Started

Terraform is orchestrator agnostic. The execution environment is dynamically extended with [hypervisor-specific interfaces][tf_provider] when needed. 

- Terraform templates comprise the physical infrastructure, network functions and orchestrators for distributed systems. 
- Topology templates comprise configuration scripts that intiate service deployments upon the successful creation of a resource. 
- Terraform’s [local-exec][tf_local-exec] and [remote-exec][tf_remote-exec] blocks run configuration scripts that install software components for service instances. 
- Operators combine application code and/or binaries with virtualization and an orchestration environment of their choice into comprehensive build plans. 

The process of provisioning infrastructure is merged with the continuous integration and deployment chain for application code. Combinging Terraform with OCI, enterprise IT departments benefit from:

- **Increased flexibility and agility in operation**

    Relying on automated deployment allows you to centralize topology management in code repositories. While Terraform is creating resources, state is maintained. This helps to prevent confusion among engineering teams. The desired state for all resources is compared to the current state and the delta defines the provisioning sequence for the requested changes. 

    This allows operators to launch virtual data center in more than 30 locations and rely on a single script source to maintain company-wide security and compliance standards. 

- **Integrated cloud services**

    Database and application infrastructure is separated in OCI. The terraform service provider combines deployment scripts for database services with provisioning scripts for applications relying on open source orchestrators and commercial hypervisors like Kubernetes and VMWare vSphere. 

    Engineers merge cloud-native services and traditional enterprise applications into comprehensive deployment templates. Combining Oracle's orchestrator-agnostic approach for the applications stack with separate infrastructure for multi-model databases on a native layer three network, service owners modernize existing applications incrementally and adopt cloud native services in digestable steps. Doing so, they avoid rewriting entire applications before migrating to a managed infrastrcuture stack.

- **Shadow IT prevention**

    Terraform separates code and execution environments and allows you to maintain security and cost-control while enabling self-service application deployments. 

    Defining resources in code allows you to define launch parameters and user credentials programmitically, take dependencies during the provisioning process into account, and define the sequence of resources that are deployed. 

    Engineers describe a target topology and terraform determines the steps required to create a resource automatically. Leveraging flags like the region argument, modules are exectuted in different regions and availability/security domains. This allows modules to be defined which represent services in a self-service portal, with admin expertise and configuration dependencies reflected in the predefined deployment process.

<!--EDIT-->

We refer to resources that are programmatically defined as [custom or logical resources][ref_logical]. The learning curve, adding to orchestrator-specific service provider to the OCI core services is not very steep, because syntax patterns that are used to code infrastructure on orchestrators remain the same.   

### Command Line Access

A fast way to start, is obtaining an Oracle Cloud Infrastructure account by **signing up for the [Free Tier][oci_freetier]**. Because Oracle assigns dedicated resources to every user, new registrations can be prevented by a lack of resources in a specific region. Select a different region for the registration usually helps to overcome the hurdle.

{% imgx aligncenter assets/cloud_shell.png "OCI Free Tier" %}

After obtaining an account we log into the web console and start the [Cloud Shell][oci_cloudshell] with |*>_*| button. The cloud shell launches in the region that is active in the cloud console. For the initial setup the home region of a tenant should be selected. Executing deployment plans, Terraform depends on the directory structure to identify files that belong to a plan.

```console
mkdir ~/project
```

In the *project* directory we create a file with the name `hello.tf`. 

```
cd ~/project && touch hello.tf
```

Terraform code is stored in a text file that ends with *.tf*. We open the file with an editor of choice. The cloud shell comes with *vim* and *nano* preinstalled.

```
nano ~/project/hello.tf
```

### Hello World

Terraform uses a configuration language called HashiCorp Configuration Language (HCL) for templates that characterize components of a topology. HCL is a decalrative lanuguage, instructions are stored in blocks, the synthax looks as follows.

```
<BLOCK TYPE> "<BLOCK project>" {
 <IDENTIFIER> = <EXPRESSION>
}
```
Infrastructure components are defined, adopting an input-output model. [Input parameter][Input] are passed to a build plan, resources definitions describe the provision process and [output parameters][Output] return the results. 


{% imgx aligncenter assets/iomodel.png "HCL Syntax" %}


This principle can be explained using a simple "Hello World" example. First we define an input variable. The input block, contains type constraints as arguments for interpretation. Simple [types][tf_types] are `string`, `number` and `bool`, complex types are `list` and `object`. The resource block remains empty for now, because we do not aim to provision any resources. The output block returns the execution results. Referring to an output variable instructs Terraform to execute the referenced block, the sequence inside the code is actaully not relevant. 

```
# Input
variable "input" {
  type        = string
  default     = "Hello World"
}

# Function
resource "null_resource" "nothing" {}

# Output
output "greeting" { value = var.input }
```

HCL scripts do not include a shebang, we need to call terraform explicitely. We store the file as `~/project/hello.tf` and run the terraform command. Before executing terraform, we need to initalize the working directory. 

```
cd ~/project && terraform init
```

The command allows for additional subcommands, using the format *terraform <subcommand> -options*. The *-auto-approve* option forces terraform to execute the command without further confirmation. 

```
terraform apply -auto-approve
```

The command only returns with an output of the variable.

```
greeting = Hello World
```

After this example, the `~/project/hello.tf` is no longer needed. 

## Provider Configuration

In order to create resources in OCI we need to configure terraform. We create a basic configuration file.

```
rm ~/project/hello.tf && nano ~/project/config.tf

```

The first block is the [provider block][tf_provider], we load the latest service provider. A [service provider][oci_terraform] is a plugin for the provisioning API, it translates [HCL code into API calls][oci_provider]. The API conituously evolves, adding a the provider block enforces terraform to load the latest version before exectuing any scripts. In the cloud shell, an empty block is suffcient, because the necessary arguments are stored as default parameter.

```
# Setup the oci service provider
provider "oci" { }
```

Next, we instruct terraform to address a specific account, referring to the [Oracle Cloud Ressource Indentifier (OCID)][oci_tenancy]. We define the tenancy_ocid as empty input parameter and retrieve the OCID from the command line. 

```
# Input parameter to request the unique identifier for an account
variable "tenancy_ocid" { }
```

With that, the communication is established and we can use the cloud controller as data source. A [data block][tf_data] sends a request to the controller and retruns [account specific information][tf_tenancy] in JSON format.  

```
# Retrieve meta data for tenant
data "oci_identity_tenancy" "account" {
  tenancy_id = var.tenancy_ocid
}
```

We define the result as parameter print the result to the console defining an output block. 

```
# Output tenancy details
output "tenancy" {
  value = data.oci_identity_tenancy.account
}
```

Now, we close the file test the integration with `plan` command.  Because we left the input variable for the tenancy ID empty, we need to refer to a environment setting. The unix command [printenv][linux_printenv] unveils the respective environment variable.

```
printenv | grep TENANCY
```

With the `-var` argument we provide the expected input, running terraform. 

```
cd ~/project && terraform init && terraform plan -var tenancy_ocid=$OCI_TENANCY
```

### Home Region

OCI is available in multiple regions, every region represents one or more a physcal data center. Multi-data-center regions like FRA, PHX, IAD and LHR are managed as one resource pool with multiple availability domains (AD). All regions are managed through a single API, which makes global service roll-outs simple. We target a specific region, using the region argument inside a block. In the console, the active region is showen in the upper right corner, and in the cloud shell the command prompt shows the active region. 

![Cloud Shell](https://docs.cloud.oracle.com/en-us/iaas/Content/Resources/Images/cloud-shell-region-location-prompt.png "OCI Console")

Some resources like compartments are defined once and replicated into every region, we call these global resources. These resources should be created in the ["home" region][blog_home]. We use the *locals block* to define a function that determines the [home region][oci_homeregion] for a tenant. 

```
# Create a region map
locals {
  region_map = {
    for city in data.oci_identity_regions.global.regions :
    city.key => city.name
  }
  home_region = lookup(
    local.region_map,
    data.oci_identity_tenancy.account.home_region_key
  )
}
```

[Region identifier][oci_identifier] in OCI are provided either in a long format that includes the AD, like *eu-frankfurt-1* or as simple three letter key, like *FRA*. Even though HCL is a templating language, [expressions][tf_expression] allow to use [scripts][tf_script] as primitives. We use this functionality in a [local block][tf_locals] to construct the right input format. 

```
# Get the list of regions
data "oci_identity_regions" "global" { }
```

The `oci_identity_tenancy` block in setting.tf delivers the home-region key that we match with the long format in [map][oci_regionmap] that contains all OCI regions. The map is retrieved "global" data block. The result is an identifier we can use as argument in the provider block. 


## Terraform Workflow

Executing a build plan is reflected in a sequence of terraform commands to validates block definitions, to quantify and to provision the required resources. The steps in the Terraform workflow are closely related to the lifecycle of resources on cloud platforms. These steps are orchestrator-agnostic, the commands are valid to create, update, and destroy resources on any given orchestrator.

{% imgx aligncenter assets/workflow.png "Initial Command Sequence" %}

Before executing terraform commands, we validate the HCL and JSON syntax. `Terraform validate` is a parser that checks the synthax structure for obvious errors. 

```
terraform validate
```

When the code is error free, we run the `init` command that instructs terraform to check and load the referenced service provider plug-ins from the [provider registry][tf_provider] and store the plugin in the `.terraform` sub directory. Third party service provider can be added by defining additional provider blocks.

```
terraform init
```

After that we run a plan command to check the list of resource changes before executing a deployment plan. The plan command indicates which resources will be created, updated or deleted in order to adjust the current architecture to match the desired architecture. The `-out config.tfplan` extension instructs terraform to store the excution plan for a later apply. 

```
terraform plan -var tenancy_ocid=$OCI_TENANCY -out config.tfplan
```

The apply command executes the script. We are not provisioning any resources yet and use the -auto-approve flag to skip the explicit confirmation.

```
terraform apply "config.tfplan" -auto-approve
```

Executing the script instructs Terraform to provision the required resources and to return the output varaibles in the shell. Once confirmed, it takes a few seconds to complete the creation of the resources on OCI. The completion of the command is indicated with the output messages. 

## State Management

Terraform is a state-aware deployment tool, it generates a file with the `apply` command that reflects the deployment status. The state file allows operators to track the current state of their resources. State information is maintained in syntax similar to JSON. The file is located in a hidden folder **.terraform/terraform.tfstate**. Editing the state file directly is not recommended.

```
cat ~/training/terraform.tfstate
```

This file captures terraform the results of every deployment process. State awareness sets Terraform apart from most configuration management systems used for cloud deployments, because it allows for "declarative" deployments. The admin only defines the desired architecture in the build plan and when terrafrom is executed, the programm automatically determines the difference between the as-is- and to-be architecture and deploys or destroys the required resources. 

```
# Terraform.tfstate file example

{
    "version": 3,
    "terraform_version": "0.11.8",
    "lineage": "35a9fcf6-c658-3697-9d74-480408535ce6",
    "modules": [
            {
                    "path": ["root"],
                    ……………………………………
                    "depends_on": []
            }
    ]&
}
```
Terraform provides a commands for operators to review the current state, `terraform show`. The *show* command retrieves all information captured in the state file. the `-json` option transfers the data into a valid [json format][tf_json] . 

```
terraform show -json
```

With a JSON parser like [jq][jq_site] we can filter infrastrucutre information for further use. In case of an error, the [json validator][json_valid] allowss to check the json structure and the [jq playground][jq_play] to develop the filter syntax before applying it.

```
terraform show -json | jq .values.outputs.tenancy.value.home_region_key -r
```

This example shows how to use jq to filter the home region of your tenant from json output. It returns the three letter value, e.g. *FRA* for the home region.

## Output

With `terraform output` will retrieve the definied output parameter from the state file. Adding the name of a particular block, the response and returns only the data of a specific block.

```
terraform output home
```

We can use the this command to ananlyse an existing tenancy from the command line. E.g. resources can only be deployed in regions that have been activated by the account owner. One option is to leverage the [OCI command line interface][oci_cli] to retrieve a list of regions have already been activated. 

```
oci iam region-subscription list --query 'data[*]'
```

Terraform allows operators to use the same API but provide a list in [JSON][tf_json] format. We create a small module in a subdirectory. This modules creates a JSON output containing all regions that a tenancy has subscribed to.

```
mkdir ~/project/subscriptions && nano ~/project/subscriptions/region.tf
```

The method `oci_identity_region_subscriptions` retrieves the list of activated regions form the service provider. With the output block we reformat the list into a list of provider arguments. 

```
variable "tenancy_ocid" { }

output "subscriptions" {
  value = [
     for subscription in data.oci_identity_region_subscriptions.activated.region_subscriptions:{
        "alias" = subscription.region_key
        "region"  = subscription.region_name
     }
  ]
}

data "oci_identity_region_subscriptions" "activated" { tenancy_id = var.tenancy_ocid }
```

After an initial *apply*, we use the `terraform output -json` command and parse the list with [jq][ref_jq] to crteate a terraform input file, in this example a list of regional provider. We use a bash command to transfer the result into `~/project/provider.tf.json` file. 

```
terraform output -json | jq '[{provider: {oci: .providers.value[]}}]' > p && mv ./p ../provider.tf.json
```

Next up, the [Service Delivery Framework][base].

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


[tf_doc]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[cli_doc]: https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/
[iam_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm
[network_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm
[compute_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/Concepts/computeoverview.htm#Overview_of_the_Compute_Service
[storage_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm
[database_doc]: https://docs.cloud.oracle.com/en-us/iaas/Content/Database/Concepts/databaseoverview.htm
[tf_cli]:         https://www.terraform.io/docs/commands/index.html
[tf_commands]:    https://www.terraform.io/docs/commands/index.html
[tf_data]:        https://www.terraform.io/docs/configuration/data-sources.html
[tf_doc]:         https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[tf_examples]:    https://github.com/terraform-providers/terraform-provider-oci/tree/master/examples
[tf_expression]:  https://www.terraform.io/docs/language/expressions/index.html
[tf_hcl]:         https://github.com/hashicorp/hcl
[tf_home]:        https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_tenancy
[tf_intro]:       https://youtu.be/h970ZBgKINg
[tf_json]:        https://www.terraform.io/docs/internals/json-format.html
[tf_lint]:        https://www.hashicorp.com/blog/announcing-the-terraform-visual-studio-code-extension-v2-0-0
[tf_local]:       https://www.terraform.io/docs/configuration/locals.html
[tf_locals]:      https://www.terraform.io/docs/configuration/locals.html
[tf_main]:        https://www.terraform.io/
[tf_provider]:    https://www.terraform.io/docs/language/providers/configuration.html
[tf_tenancy]:     https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_tenancy
[tf_local-exec]:  https://www.terraform.io/docs/language/resources/provisioners/local-exec.html
[tf_remote-exec]: https://www.terraform.io/docs/language/resources/provisioners/remote-exec.html
[tf_script]:      https://www.terraform.io/docs/language/expressions/for.html
[tf_syntax]:      https://www.terraform.io/docs/language/syntax/configuration.html
[tf_types]:       https://www.terraform.io/docs/language/expressions/types.html

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
