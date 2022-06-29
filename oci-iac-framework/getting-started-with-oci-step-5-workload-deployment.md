---
title: Workload Deployment
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
date: 2021-12-09 08:00
description: How to deploy and configure your code on the OCLOUD framework landing
  zone
toc: true
author: kubemen
mrm: WWMK211125P00022
xredirect: https://developer.oracle.com/tutorials/oci-iac-framework/getting-started-with-oci-step-5-workload-deployment/
slug: getting-started-with-oci-step-5-workload-deployment
---
{% imgx aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

## OCI best practices

Oracles's best practice recommendation for workloads on Oracle Cloud Infrastructure (OCI) is to use an **operator host** to install and maintain the service application and configuration for the workload.  

As you might imagine, since the number of applications and needed configurations varies, our goal at this step will be to dig deeper into the concept of the operator host and explore which configurations and automation tools can be best used to deploy your workload on OCI.  

## Operator Host

The aim of the operator host is to:  

1. Perform post-provisioning tasks with any automation tools that require a local installation.
2. Provide administrators access without the need to upload API authentication keys (instance_principal).  

### Access to Operator Host

As described in the [base] section of the series, OCI provides the ability to use a Bastion service for a controlled and secure access to resources in your tenancy.  

The operator host concept leverages this service, providing administrators and application hosts a quick and secure mechanism to access a system which can run scripts or any automation tool for maintaining and operating the services.

## OCI Tool Support for Automation and Configuration Management

Terraform is primarily used to define the infrastructure required to host the applications for the service. However, by itself, Terraform is not designed to perform certain application installation or configuration tasks.  

Oracle recognizes that everyone's needs are different. Throughout this series we've attempted to present ways to use the most common tools on the market in combination with Terraform to provide and guide you with a set of best practices. As always, it's up to you to decide which tool combination best suits your individual workload and which best fulfills your requirements.  

Terraform is focussed on Infrastructure as Code (IaC). While its strength lies in provisioning resources there's a potentially need for tools to install, configure, and manage applications on top of the infrastructure. There are a number of external tools which can be used to automate the workload deployment.  

In this session, we'll focus on how to use the most common tools like Ansible, Puppet, and Chef. We'll also take a cloud-native approach, so we'll show you in a demo how you can leverage Helm charts to deploy workloads via the Oracle Resource Manager onto an OKE cluster deployed [previously](./getting-started-with-oci-step-4-app-infrastructure.md).  

### Ansible

OCI supports the use of Ansible's modules to automate cloud infrastructure provisioning along with configuration, complex operation process orchestration, and deployment/maintenance of your software assets.  

{% imgx assets/ansible.png "Ansible" %}

**Resources:**  

- The OCI Ansible collection supports both Ansible Tower and AWX.  

  - **Ansible Tower -** For more information on how to set up the collection with Ansible Tower, refer to the [Ansible blog post][ansible_blogpost].  
  - **AWX -** To install the free version of Ansible Tower (AWX) on an OCI Compute instance, you can use [ansible solution on GitHub] and the following [ansible example playbooks].

- A complete example of how you can use Ansible to deploy Kubernetes and Istio can be found in this [article](https://blog.kube-mesh.io/single-click-deployment-of-oke-istio-mushop-using-ansible-from-oci-cloud-shell/).
- For additional information on Ansible, check out the [ansible collection].

### Puppet

While many organizations are using Terraform to provision Oracle cloud resources, a solution for continuous integration should be considered when it comes to ongoing management of resources. That’s where Puppet can help. With Puppet you can:  

- Integrate cloud resources into your existing infrastructure and manage everything with one tool.  
- Use existing [puppet_hiera] data to configure parts of your OCI infrastructure.  
- Have a tighter integration between OCI configuration in general and the configuration management on your systems.  

#### Extend Puppet with `oci_config`

The `oci_config` module extends the Puppet language to contain types needed to create and manage the lifecycle of objects within your Oracle Cloud Infrastructure. Although this is traditionally the domain of Terraform scripts, being able to manage these objects with Puppet has proven to be a big plus for many customers. For example:  

- Your organization is already using Puppet and not Terraform. Introducing a new tool into your organization might be more then you want or need. In these cases, Puppet in combination with this module can be a great help.
- You want to use existing Hiera data to configure parts of your OCI infrastructure. In this case, using this module is great. It integrates with all of the existing hieradata, just like your other Puppet code.
- You need tighter integration between OCI configuration in general and the configuration management on your systems. Again, this module is for you. Since it makes use of standard Puppet you can use all of the rich Puppet features like exported resources to integrate all of your configuration settings both on the cloud level as well as on the machines.  

**Puppet example code:**  

Configuration for using a tenant:  

```console
puppet apply /software/tenant_setup.pp
```

Your output should be something like:

```console
Notice: Compiled catalog for oci in environment production in 0.09 seconds
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/fingerprint: defined 'fingerprint' as 'xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx'
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/private_key: created with specified value
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/region: defined 'region' as 'eu-frankfurt-1'
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/tenancy_ocid: defined 'tenancy_ocid' as 'ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/user_ocid: defined 'user_ocid' as 'ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
Notice: Applied catalog in 0.02 seconds
```

**First inspection:**

```console
puppet resource oci_identity_compartment
```

Your output should look something like:  

```console
bash-4.2# puppet resource oci_identity_compartment
*** ENTERPRISE MODULES Universal License INTERNAL USE ONLY ***
oci_identity_compartment { 'your_tenant (root)/ManagedCompartmentForPaaS':
  ensure          => 'present',
  compartment     => '/',
  compartment_id  => 'ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  description     => 'idcs-f7246e2bbacf4a11a7e231507e34fdec|22626923|user@domain.com-Enterprise Modules B.V.-838062',
  id              => 'ocid1.compartment.oc1..aaaaaaaai2wkrvdvyxfuekjbt3jnv7b4hrlkvwnklu6uryy2daqsq425tzaa',
  lifecycle_state => 'ACTIVE',
  provider        => 'sdk',
  time_created    => '2019-10-24T08:42:26+00:00',
}
oci_identity_compartment { 'your_tenant (root)/test_compartment_1':
  ensure          => 'present',
  compartment     => '/',
  compartment_id  => 'ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  description     => 'changed',
  id              => 'ocid1.compartment.oc1..aaaaaaaatfskqfckrl4sucabclbsss47uyttlmwwur6lsm7crl3lrz7glfta',
  lifecycle_state => 'ACTIVE',
  provider        => 'sdk',
  time_created    => '2020-01-23T15:42:35+00:00',
}
```

**Resources:**  

- [oci_identity_compartment](https://www.enterprisemodules.com/blog/2020/02/getting-to-know-oracle-cloud-with-puppet-part-1/)
- Download the `oci_config` module from [Puppet forge][puppet_forge].  
- Read the [Puppet Enterprise Guide][puppet_enterprise_guide] to install the `oci_config` Puppet module.  
- Follow the guide to [deploy an Oracle 19 database via Puppet][deploy_an_Oracle19_database_via_puppet].

### Chef

Chef is a powerful automation platform that transforms infrastructure into code. Whether you’re operating in the cloud, on-premises, or in a hybrid environment, Chef automates how infrastructure is configured, deployed, and managed across your network, no matter its size.  

This diagram shows how you develop, test, and deploy your Chef code:  

{% imgx assets/chef.png "Chef" %}

*Chef Plugin for OCI ([Image Courtesy](https://docs.chef.io/platform_overview.html))*

### `knife-oci` plugin

The **[knife-oci](https://docs.us-phoenix-1.oraclecloud.com/Content/API/SDKDocs/knifeplugin.htm)** plugin allows users to interact with OCI through Chef Knife.  

The following are the available **knife-oci** plugin commands:  

| Action | Command |
| - | - |
| Launch an OCI instance and bootstrap it as a Chef node | `knife oci server create` |
List OCI compartments | `knife oci compartment list` |
| Delete an OCI instance | `knife oci server delete` |
| List OCI instances in a given compartment. <br>**Note:** All instances in the compartment are returned, not only those that are Chef nodes | `knife oci server list` |
| List the images in a compartment | `knife oci image list` |
| List the VCNs in a compartment | `knife oci vcn list` |
| List the subnets in a VCN | `knife oci subnet list` |
|List the shapes that may be used for a particular image type | `knife oci shape list` |
| List the availability domains for your tenancy | `knife oci ad list` |

**Resources:**  

- The `knife-oci` plugin can be downloaded from [the public repo](https://github.com/oracle/knife-oci/releases).
- How to setup the knife-oci plugin can be found in this [article](https://medium.com/oracledevs/using-oracles-chef-plugin-to-provision-resource-in-oracle-cloud-infrastructure-5891100e20ab).
- [OCI documentation for the chef][chef_plugin].

### Helm

*Helm* helps you manage Kubernetes applications while *Helm Charts* help you define, install, and upgrade even the most complex Kubernetes application. Charts are easy to create, version, share, and publish so you can avoid tedious copying-and-pasting.  

Advantages of using Helm for the deployment of applications on top of Kubernetes:  

- Managed Complexity
- Easy Updates
- Simple Sharing
- Rollbacks

#### Oracle Resource Manager

The Oracle Resource Manager (ORM) supports the Terraform provider for Helm and can be easily used in combination with the Terraform Kubernetes providers.  

**Reference:** Details about third-party provider versions of ORM can be found on this [providers page](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/providers.htm).  

In order to get the needed information about the Kubernetes cluster, we'll need to get the content of the Kubernetes cluster which has been deployed.  

This can be achieved for the Kubernetes and Helm provider through the following:  

```terraform
# Gets kubeconfig
data "oci_containerengine_cluster_kube_config" "oke_cluster_kube_config" {
  cluster_id = oci_containerengine_cluster.oke_cluster.id
}

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "kubernetes" {
  load_config_file       = "false" # Workaround for tf k8s provider < 1.11.1 to work with ORM
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["server"]
  exec {
    api_version = "client.authentication.k8s.io/v1beta1" # Workaround for tf k8s provider < 1.11.1 to work with orm - yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["apiVersion"]
    args = [yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][0],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][1],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][2],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][3],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][4],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][5],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][6]]
      command = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["command"]
  }
}

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "helm" {
  kubernetes {
    load_config_file       = "false" # Workaround for tf helm provider < 1.1.1 to work with ORM
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["server"]
    exec {
      api_version = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["apiVersion"]
      args = [yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][0],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][1],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][2],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][3],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][4],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][5],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][6]]
        command = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["command"]
    }
  }
}

```

>**Best practice:** It's recommended that you separate Kubernetes by service into logical entities called *namespaces* (see [below](#namespaces)).  
{:.notice}

#### namespaces

The following code snippet in Terraform creates a namespace:  

```terraform
resource "kubernetes_namespace" "<service>_namespace" {
  metadata {
    name = "<service>"
  }
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}
```

>**Best practice:** As we need to have a working Kubernetes up and ready with available worker nodes, we recommend that you wait until you can verify that worker nodes have been deployed in a previous step of Terraform.  
{:.notice}

### Deploy Kubernetes application

The next step would be to deploy your Kubernetes application with a Helm release into the previously created [namespace](#namespaces).  

This can be achieved by storing your Helm files in a sub-directory of your Terraform environment (e.g., *helm_charts*) and referencing your charts in your Terraform code as follows:  

```terraform
resource "helm_release" "<application_1>" {
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
  name       = "<application_1>"
  chart      = "helm_charts/<application_1>"
  namespace  = kubernetes_namespace.<service>_namespace.id
  wait       = false
  timeout    = 300
}
```

#### Deploy multiple applications

It's also possible to deploy multiple applications for your service in repeating the code fragment as follows:  

```terraform
resource "helm_release" "<application_2>" {
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
  name       = "<application_2>"
  chart      = "helm_charts/<application_2>"
  namespace  = kubernetes_namespace.<service>_namespace.id
  wait       = false
  timeout    = 300
}
```

>**Best practices:**  
>
>- **`timeout` -** Set a timeout to give Helm a time frame within which the deployment has to be completed.  
>- **`depends_on` -** As the Helm provider is not able to identify whether or not the Kubernetes deployment has been finished, we add a `depends_on` section to make sure that the Kubernetes cluster is up and running before deploying.
{:.notice}

**Reference:** Information about namespaces can be found in this Kubernetes [article on namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).

## Demonstration of a Helm deployment

To demonstrate how to use the ORM to deploy workload on Kubernetes cluster, we'll show an example by deploying a Helm release of an hivemq cluster and a kafka connector in one namespace.  

The target setup will look as follows:  

{% imgx assets/demo.png "Demo Setup" %}

We're using the following generic code which can be used independent of the IaaS or Kubernetes stack:  

```terraform
# Gets kubeconfig
data "oci_containerengine_cluster_kube_config" "oke_cluster_kube_config" {
  cluster_id = oci_containerengine_cluster.oke_cluster.id
}

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "kubernetes" {
  load_config_file       = "false" # Workaround for tf k8s provider < 1.11.1 to work with ORM
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["server"]
  exec {
    api_version = "client.authentication.k8s.io/v1beta1" # Workaround for tf k8s provider < 1.11.1 to work with orm - yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["apiVersion"]
    args = [yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][0],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][1],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][2],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][3],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][4],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][5],
    yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][6]]
    command = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["command"]
  }
}

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "helm" {
  kubernetes {
    load_config_file       = "false" # Workaround for tf helm provider < 1.1.1 to work with ORM
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["clusters"][0]["cluster"]["server"]
    exec {
      api_version = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["apiVersion"]
      args = [yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][0],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][1],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][2],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][3],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][4],
        yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][5],
      yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["args"][6]]
      command = yamldecode(data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content)["users"][0]["user"]["exec"]["command"]
    }
  }
}


resource "kubernetes_namespace" "hivekafka_namespace" {
  metadata {
    name = "hivekafka"
  }
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}

resource "helm_release" "hivemq" {
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
  name       = "hivemq"
  chart      = "helm_charts/hivemq"
  namespace  = kubernetes_namespace.hivekafka_namespace.id
  wait       = false
  timeout    = 300
}

# Deploy kafka-connect chart
resource "helm_release" "kafkaconnect" {
   depends_on = [oci_containerengine_node_pool.oke_node_pool]
   name      = "kafka-connect"
   chart     = "helm_charts/cp-kafka-connect"
   namespace = kubernetes_namespace.hivekafka_namespace.id
   wait      = false
   timeout   = 120
}

#Output the public IP addresses of the helm-chart generated service load balancers
resource "time_sleep" "wait_120_seconds" {
  depends_on = [helm_release.hivemq] 
  create_duration = "120s"
}

data "kubernetes_service" "oss_kafka_connect" {
  depends_on = [time_sleep.wait_120_seconds]
  metadata {
    name = "oss-kafka-connect-service"
    namespace = "hivekafka"
  }
}

data "kubernetes_service" "hivemq_mqtt" {
  depends_on = [time_sleep.wait_120_seconds]
  metadata {
    name = "hivemq-mqtt"
    namespace = "hivekafka"
  }
}

output "oss_kafka_connect_load_balancer_ip_address" {
  //value = [data.kubernetes_service.oss_kafka_connect.status.0.load_balancer.0.ingress.0.ip]
  value = [data.kubernetes_service.oss_kafka_connect.load_balancer_ingress[0].ip]
}

output "hivemq_mqtt_load_balancer_ip_address" {
  //value = [data.kubernetes_service.hivemq_mqtt.status.0.load_balancer.0.ingress.0.ip]
  value = [data.kubernetes_service.hivemq_mqtt.load_balancer_ingress[0].ip]
}
```

**Examining the code:**  

When you're comparing the code with the example it's easy to see that the content itself hasn't really changed. We've only added some output, in this case the IP addresses of the loadbalancers, which will be automatically deployed by the Helm chart. Lastly, we've added a 120-second timeout since the loadbalancers will be deployed directly by Kubernetes, something which Terraform isn't able to see.  

### View the deployment

To get a list of current deployments, pods, and services, run the following kubectl command:  

```console
kubectl -n hivekafka get deployments,pods,services
```

Your output should look something like:  

```console
NAME                                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hivemq-cluster                 3/3     3            3           61m
deployment.apps/oss-kafka-connect-deployment   2/3     3            2           61m
NAME                                                READY   STATUS             RESTARTS   AGE
pod/hivemq-cluster-59c44cdb59-fpvb9                 1/1     Running            0          61m
pod/hivemq-cluster-59c44cdb59-nw6dd                 1/1     Running            0          61m
pod/hivemq-cluster-59c44cdb59-txrt5                 1/1     Running            0          61m
pod/oss-kafka-connect-deployment-5f87774458-gbr9s   0/1     CrashLoopBackOff   11         61m
pod/oss-kafka-connect-deployment-5f87774458-qnmgr   1/1     Running            12         61m
pod/oss-kafka-connect-deployment-5f87774458-zcgpt   1/1     Running            12         61m
pod/wallet-extractor-job-9j8xl                      0/1     Completed          0          61m
NAME                                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
service/hivemq-control-center       LoadBalancer   10.96.171.15    <pending>        8080:30666/TCP   61m
service/hivemq-discovery            ClusterIP      None            <none>           1883/TCP         61m
service/hivemq-mqtt                 LoadBalancer   10.96.49.214    129.159.77.93    1883:31094/TCP   61m
service/oss-kafka-connect-service   LoadBalancer   10.96.114.200   129.159.74.132   80:31501/TCP     61m
```

## What's next

In the sixth and final segment of our series, we'll discuss how to organize your tenants in a section on [governance](./getting-started-with-oci-step-6-governance.md).  

<!--- Links -->

[base]: ./getting-started-with-oci-step-2-base.md

[home]:       index
[intro]:      getting-started-with-oci-intro.md
[provider]:   getting-started-with-oci-step-1-provider
[base]:       getting-started-with-oci-step-2-base
[db-infra]:   getting-started-with-oci-step-3-database-infrastructure
[app-infra]:  getting-started-with-oci-step-4-app-infrastructure
[workload]:   getting-started-with-oci-step-5-workload-deployment
[governance]: getting-started-with-oci-step-6-governance
[vizualize]:  step7-vizualize

[ansible collection]:                       https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/ansible.htm
[ansible_blogpost]:                         https://blogs.oracle.com/cloud-infrastructure/post/using-oracle-cloud-infrastructure-with-ansible-tower-and-awx
[ansible solution on GitHub]:               https://github.com/oracle-quickstart/oci-ansible-awx
[ansible example playbooks]:                https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/ansiblesamples.htm#Sample_Ansible_Playbooks
[puppet_blog]:                              https://puppet.com/blog/configure-and-manage-oracle-cloud-infrastructure-components-with-puppet/
[puppet_hiera]:                             https://puppet.com/docs/puppet/5.5/hiera_intro.html
[puppet_forge]:                             https://forge.puppet.com/enterprisemodules/oci_config?_ga=2.53914861.492612131.1628576569-1666656837.1628576569
[puppet_enterprise_guide]:                  https://www.enterprisemodules.com/blog/2020/02/getting-to-know-oracle-cloud-with-puppet-part-1/
[deploy_an_Oracle19_database_via_puppet]:   https://forge.puppet.com/configuration-management/enterprisemodules/deploy-oracle-19c?_ga=2.93880664.492612131.1628576569-1666656837.1628576569
[chef_plugin]:                              https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/knifeplugin.htm
