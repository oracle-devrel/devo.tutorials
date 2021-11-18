---
title: Workload Deployment
parent: [tutorials,oci-iac-framework]
tags: [open-source, terraform, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/landing-zone.png
date: 2021-10-18 20:00:00
description: How to deploy and configure your code on the OCLOUD framework landing zone
toc: true
author: kubemen
draft: true
---
{% imgx aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

Best practice from Oracle for workload on OCI is to use the concept of an operator host to install and maintain the service application and configuration for the workload. 

As the number of applications and needed configurations varies, the goal of this step is to dig a bit deeper in the concept of the operator host and which configuration and automation tools can be used on OCI to deploy your workload.  

## Operator Host
The aim of the operator host is:
1. Performing post-provisioning tasks with any automation tools which requires a local installation.
2. Provide administrators access without the need to upload api authentication keys (instance_principal).  

### Access to Operator Host
As described in the base section, OCI provides the ability to use a bastion service for a controlled and secure access to ressources in your tenancy. 

The operator host concept leverages this service, providing administrators and application hosts a quick and secure mechanism to access a system which can run scripts or any automation tool for maintaining and operating the services.

## OCI Tool Support for automation & configuration management
The use of Terraform is mostly in defining the infrastructure to host the applications for the service. Terraform itself is not naturally designed to do certain application installation or configuration tasks. 

Oracle is not recommending to use any of the described tools as the right way to go for customers or prospects - instead Oracle is describing how to use the most commons tools on the market in combination with Terraform to provide and guide customers with best practices. It is up to the customer and their requirements to define which is the tool combination for their individual workload and which best fulfills their needs.

There are a number of external tools which can be used to automate the workload deployment. Terraform is focussed on IaC and has it strength in provisioning infrastructure resources there is potentially a need to use further tools to install, configure and manage applications on top of the infrastracture.

We will focus in this session on how to use the most common tools like Ansible, Puppet, and Chef, and we will show how they can be used.

The focus of this session is on cloud-native, thus we will show you in a demo how you can leverage helm charts to deploy workload via the Oracle Resource Manager onto an OKE cluster which has been deployed in the previous session.

### **Ansible**
OCI supports the use of Ansibles modules to automate cloud infrastructure provisioning and configuration, orchestrating of complex operation process, and deployment and update of your software assets.  
{% imgx assets/ansible.png "Ansible" %}

The OCI Ansible collection supports Ansible Tower and AWX. For more information on how to set up the collection with Ansible Tower, refer to the [ansible_blogpost]. To install the free version of Ansible Tower (AWX) on an OCI Compute instance, you can use [ansible solution on GitHub] and the following [ansible example playbooks]

A complete example how you can use Ansible to deploy Kubernetes, Istio and an example service can be found here: https://blog.kube-mesh.io/single-click-deployment-of-oke-istio-mushop-using-ansible-from-oci-cloud-shell/  
Link: [ansible_collection]

### **Puppet**
While many organizations are using Terraform to provision Oracle cloud resources, a solution for continuous integration should be considered when it comes to ongoing management of resources. That’s where Puppet can help. With Puppet you can:  
- Integrate cloud resources into your existing infrastructure, and manage everything with one tool.  
- Use existing [puppet_hiera] data to configure parts of your OCI infrastructure.  
- Have a tighter integration between OCI configuration in general and the configuration management on your systems.  

The oci_config module extends the Puppet language to contain types needed to create and manage the lifecycle of objects within your Oracle Cloud Infrastructure. Although this is traditionally the domain of Terraform scripts, being able to manage these objects with Puppet has proven to be a big plus for many customers. For example:
- Your organization is already using Puppet and not Terraform. Introducing a new tool into your organization might be more then you want or need. In these cases, Puppet, in combination with this module, is a great help.
- You want to use existing hiera data to configure parts of your OCI infrastructure. In this case, using this module is great. It integrates with all of the existing hieradata, just like your other Puppet code.
- You need tighter integration between OCI configuration in general and the configuration management on your systems. Again, this module is for you. It is regular Puppet so you can use all of the rich Puppet features like exported resources to integrate all of your configuration settings both on the cloud level as well as on the machines.

**Puppet example code:**  
Configuration of using a tenant: 
```
$ puppet apply /software/tenant_setup.pp
Notice: Compiled catalog for oci in environment production in 0.09 seconds
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/fingerprint: defined 'fingerprint' as 'xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx'
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/private_key: created with specified value
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/region: defined 'region' as 'eu-frankfurt-1'
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/tenancy_ocid: defined 'tenancy_ocid' as 'ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
Notice: /Stage[main]/Main/Oci_tenant[enterprisemodules]/user_ocid: defined 'user_ocid' as 'ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
Notice: Applied catalog in 0.02 seconds
```
First inspection:
```
$ puppet resource oci_identity_compartment
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
*(available via [this link] (https://www.enterprisemodules.com/blog/2020/02/getting-to-know-oracle-cloud-with-puppet-part-1/))*


**Learn more**  
- Download the oci_config module from [puppet_forge]  
- Read the [puppet_enterprise_guide] to installing the oci_config Puppet module  
- Follow the guide to [deploy_an_Oracle19_database_via_puppet]  
Link by Puppet: [puppet_blog]

### **Chef**
Chef is a powerful automation platform that transforms infrastructure into code. Whether you’re operating in the cloud, on-premises, or in a hybrid environment, Chef automates how infrastructure is configured, deployed, and managed across your network, no matter its size.

This diagram shows how you develop, test, and deploy your Chef code  
{% imgx assets/chef.png "Chef" %}
*(Image Courtesy https://docs.chef.io/platform_overview.html)*
*Chef Plugin for OCI*

The **knife-oci** plugin allows users to interact with Oracle Cloud Infrastructure through chef knife.

The home page for the project is [here](https://docs.us-phoenix-1.oraclecloud.com/Content/API/SDKDocs/knifeplugin.htm). Plugin can be downloaded from [this](https://github.com/oracle/knife-oci/releases) location.

Following are the knife-oci plugin commands available.
- Launch an OCI instance and bootstrap it as a Chef node: *knife oci server create*
- List OCI compartments: *knife oci compartment list*
- Delete an OCI instance: *knife oci server delete*
- List OCI instances in a given compartment. Note: All instances in the compartment are returned, not only those that are Chef nodes: *knife oci server list*
- List the images in a compartment: *knife oci image list*
- List the VCNs in a compartment: *knife oci vcn list*
- List the subnets in a VCN: *knife oci subnet list*
- List the shapes that may be used for a particular image type: *knife oci shape list*
- List the availability domains for your tenancy: *knife oci ad list*

How to setup the knife-oci plugin can be found here: https://medium.com/oracledevs/using-oracles-chef-plugin-to-provision-resource-in-oracle-cloud-infrastructure-5891100e20ab  
OCI documentation for chef is available here: [chef_plugin]

### **Helm**
Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application.  
Charts are easy to create, version, share, and publish — so start using Helm and stop the copy-and-paste.  

The advantages of using Helm for the deployment of applications on top of Kubernetes are:
- Manage Complexity
- Easy Updates
- Simple Sharing
- Rollbacks

The Oracle Resource Manager (ORM) supports the Terraform provider for Helm and can be easily used in combination with the Terraform Kubernetes providers.  
Details about Third-party Provider Versions for ORM can be found here: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/providers.htm  

In order to get the needed information about the Kubernetes cluster it is needed to get the content of the Kubernetes cluster which has been deployed.
This can be achieved for the Kubernetes and Helm provider in the following way:
```
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

It is recommended as best practice to seperate Kubernetes by service into logical entities called *namespaces*.  
Information about namespaces can be found [here.] (https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

The following code snippet in terraform creates a namespace:
```terraform
resource "kubernetes_namespace" "<service>_namespace" {
  metadata {
    name = "<service>"
  }
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}
```

As we need to have a working Kubernetes up and ready with available worker nodes it is recommended to check and wait until the worker nodes has been deployed in a previous step of Terraform.

The next step would be to deploy your Kubernetes application with a helm release in the previously created namespace.

This can be achieved in storing your Helm files in a sub-directory of your Terraform environment, e.g. *helm_charts* and reference to your charts in your Terraform code as follows:  
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
It is as well possible to deploy multiple applications for your service in repeating the code fragment as follows:
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
Best practice is to set a timeout to give Helm a maximum time until the deployment has to be finished.  
As the Helm provider is not capable to identify if the Kubernetes deployment has been finished before we are adding a `depends_on` section to make sure that the Kubernetes cluster is up and running before deploying.

## Demonstration of a Helm deployment
To demonstrate how it is possible to use the ORM to deploy workload on Kubernetes cluster we will show case an example use case in deploying a Helm release of an hivemq cluster and an kafka connector in one namespace.

The target setup will look as follows:  
{% imgx assets/demo.png "Demo Setup" %}

We are using the following generic code which can be used independent of the IaaS or Kubernetes stack:
```
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

When you are comparing the code with the example it's easy to see that the content itself hasn't really changed.

We have only addded some output - in this case the IP addresses of the loadbalancers - which will be automaticly deployed by the Helm chart.

Furthermore, we have added a 120 second timeout as the loadbalancers will be deployed Kubernetes directly which Terraform is not able to see.

The overall output via kubectl looks likes follows:
```
$ kubectl -n hivekafka get deployments,pods,services
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



[< app-infra][app-infra] | [+][home] | [governance >][governance] 

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

[ansible_collection]:                       https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/ansible.htm
[ansible_blogpost]:                         https://blogs.oracle.com/cloud-infrastructure/post/using-oracle-cloud-infrastructure-with-ansible-tower-and-awx
[ansible solution on GitHub]:               https://github.com/oracle-quickstart/oci-ansible-awx
[ansible example playbooks]:                https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/ansiblesamples.htm#Sample_Ansible_Playbooks
[puppet_blog]:                              https://puppet.com/blog/configure-and-manage-oracle-cloud-infrastructure-components-with-puppet/
[puppet_hiera]:                             https://puppet.com/docs/puppet/5.5/hiera_intro.html
[puppet_forge]:                             https://forge.puppet.com/enterprisemodules/oci_config?_ga=2.53914861.492612131.1628576569-1666656837.1628576569
[puppet_enterprise_guide]:                  https://www.enterprisemodules.com/blog/2020/02/getting-to-know-oracle-cloud-with-puppet-part-1/
[deploy_an_Oracle19_database_via_puppet]:   https://forge.puppet.com/configuration-management/enterprisemodules/deploy-oracle-19c?_ga=2.93880664.492612131.1628576569-1666656837.1628576569
[chef_plugin]:                              https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/knifeplugin.htm
