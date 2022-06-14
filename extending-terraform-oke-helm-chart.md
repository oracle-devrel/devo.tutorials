---
title: Extending Terraform OKE with a helm chart
parent:
- tutorials
tags:
- kubernetes
- devops
- terraform
date: 2021-10-28 12:00
description: Extend a sample repo with your own extensions to make reusable provisioning
  scripts.
mrm: WWMK211125P00024
xredirect: https://developer.oracle.com/tutorials/extending-terraform-oke-helm-chart/
---
{% slides %}
When designing the [Terraform OKE] provisioning scripts, one of the things we wanted to do was make it reusable. So, what does that translate to here? In this context, it means extending the base sample repo and adding in our own extensions.

In this tutorial, we'll deploy a Redis Cluster to OKE using helm charts. Terraform conveniently provides a [helm provider], so we'll use that for our purposes.

Topics covered in this tutorial:  

* Adding the helm provider and repository
* Adding Redis with a helm release
* Interacting with the Redis Cluster
* Inspecting the new Redis Cluster
* Updating your release after deployment

For additional information, see:  

* [Signing Up for Oracle Cloud Infrastructure]
* [Getting started with Terraform]
* [Getting started with OCI Cloud Shell]

## Prerequisites

To successfully complete this tutorial, you'll need the following:

* An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* [OCI Cloud Shell] - It provides a great platform for quickly working with Terraform as well as a host of other OCI interfaces and tools.
* Access to Terraform.

## Getting started

First, clone the repo as we did before:  

```console  
git clone https://github.com/oracle/sample-oke-for-terraform.git tfoke
```

Then, navigate into the `tfoke` directory:  

```console
cd tfoke
```

And finally, follow the [instructions] to create your Terraform variable file.

## Adding the helm provider and repository

In the OKE module, create a `redis.tf` file. First, we need to configure the helm provider. Since we already have the `kubeconfig` file, we'll use the **File Config** method:

1. Add the following to `redis.tf`:  

      ```terraform
      provider "helm" {  
          kubernetes {  
              config_path = "${path.root}/generated/kubeconfig"  
          }  
      }
      ```

1. Add a helm repository:  

      ```terraform
      data "helm_repository" "stable" {  
          name = "stable"  
          url = "https://kubernetes-charts.storage.googleapis.com"  
      }
      ```

## Adding Redis with a helm release

In this section, we'll use the [Redis helm chart] to create a helm release. However, we want helm to deploy only *after* the worker nodes become active, so we'll have to make sure to check their status before proceeding.  

Let's get started setting up our release. In the [sample repo], there’s a null_resource `is_worker_active` that you can use to set an explicit dependency.  

To make use of this dependency, add the following to `redis.tf`:  

   ```terraform
   resource "helm_release" "redis" { depends_on = ["null_resource.is_worker_active", "local_file.kube_config_file"] provider = "helm"  
       name = "oke-redis"  
       repository = "${data.helm_repository.stable.metadata.0.name}"  
       chart = "redis"  
       version = "6.4.5"    set {  
           name  = "cluster.enabled"  
           value = "true"  
       }    set {  
           name = "cluster.slaveCount"  
           value = "3"  
       }  
        
       set {  
           name = "master.persistence.size"  
           value = "50Gi"  
       }  
   }
   ```

### yaml file

If you prefer to customize your helm release using a yaml file, we'll quickly walk through setting that up here:  

1. Create a folder called `resources` under the oke module.
1. Copy the file, `values.yaml` from the **redis chart repo** to `redis_values.yaml`:

      ```console
      curl -o modules/oke/resources/redis_values.yaml https://raw.githubusercontent.com/helm/charts/master/stable/redis/values.yaml
      ```

1. Remove the individual settings in the redis release from the terraform code and add the following instead:  

      ```terraform
      values = [  
         "${file("${path.module}/resources/redis_values.yaml")}"  
      ]
      ```

   Your release should then look like this:  

      ```terraform
      resource "helm_release" "redis" {  depends_on = ["null_resource.is_worker_active",    "local_file.kube_config_file"]  provider = "helm"  
          name = "my-redis-release"  
          repository = "${data.helm_repository.stable.metadata.0.name}"  
          chart = "redis"  
          version = "6.4.5"  values = [  
          "${file("${path.module}/resources/redis_values.yaml")}"  
        ]  
      }
      ```

>**Note:** You can also combine the two approaches above, but in general it's not a bad idea to keep the configurations in a single location for easy updating.  
>
>Also, you can change the values in the yaml file if you want to. For example, a good working pair of settings might be:  
>
> * default **`cluster.slaveCount`** = 3
> * **persistence.size** = 50Gi
{:.notice}

### Download the helm provider and check status

1. Run `terraform init` to download the helm provider and then apply again:  

      ```console
      terraform init  
      terraform apply -auto-approve
      ```

1. Log in to the bastion and do a helm list:  

      ```console
      helm list
      NAME          REVISION    UPDATED                     STATUS        CHART         APP VERSION   NAMESPACE                          
      oke-redis     1           Wed Apr 24 12:05:40 2019    DEPLOYED      redis-6.4.5   4.0.14        default
      ```

1. Get the notes provided by the redis chart:  

      ```console
      helm status
      ```

## Interacting with the Redis Cluster

After you've run `helm status` (see [previous section](#download-the-helm-provider-and-check-status)), the following are available to you:  

1. Get the Redis password:  

    ```console
    export REDIS_PASSWORD=$(kubectl get secret --namespace default oke-redis -o jsonpath="{.data.redis-password}" | base64 --decode)
    ```

2. Run a Redis pod:  

    ```console
    kubectl run --namespace default oke-redis-client --rm --tty -i --restart='Never' \                                                              
         --env REDIS_PASSWORD=$REDIS_PASSWORD \                                                                                                         
        --image docker.io/bitnami/redis:4.0.14 -- bash
    ```

3. Connect using the Redis cli:  

    ```console
    redis-cli -h oke-redis-master -a $REDIS_PASSWORD
    ```

4. Type a redis command:  

    ```console
    oke-redis-master:6379> ping
    PONG
    ```

## Inspecting your cluster

Recall that in the yaml file, we set the number of `redis slaves` to 3. Let’s verify that this is still the case:

```console
kubectl get pods  
```

Your output should look something like this:  

```console
NAME                               READY   STATUS    RESTARTS   AGE                                                                                
oke-redis-master-0                 1/1     Running   0          42m                                                                                
oke-redis-slave-79c45c57d8-67bxj   1/1     Running   1          42m                                                                                
oke-redis-slave-79c45c57d8-s6znq   1/1     Running   0          42m                                                                                
oke-redis-slave-79c45c57d8-wnfrh   1/1     Running   0          42m
```

From this, you can see that there are 3 pods running the redis slaves.

## Updating your release

Let's consider a real-world example. Let's say we want to update the helm release to change some settings. For example, we need to reduce the number of slaves from 3 to 2.  We actually have a couple of different ways we can do this.

1. Change settings (2 methods)
   * **helm cli -** Perform the setting change manually using the helm cli:

       ```console
       helm upgrade oke-redis stable/redis --set cluster.slaveCount=2
       ```

   * **yaml file -** Or, change the settings in the `redis_values.yaml` and then run `terraform apply` again.  
     In the case where we reduced the number of slaves from 3 to 2 the output of the `terraform apply` command should be something like:  

       ```console
       ..  
       ..  
       ..  
       module.oke.helm_release.redis: Still modifying… (ID: oke-redis, 10s elapsed)  
       module.oke.helm_release.redis: Still modifying… (ID: oke-redis, 20s elapsed)  
       module.oke.helm_release.redis: Still modifying… (ID: oke-redis, 30s elapsed)  
       module.oke.helm_release.redis: Still modifying… (ID: oke-redis, 40s elapsed)  
       module.oke.helm_release.redis: Still modifying… (ID: oke-redis, 50s elapsed)  
       module.oke.helm_release.redis: Still modifying… (ID: oke-redis, 1m1s elapsed)  
       module.oke.helm_release.redis: Modifications complete after 1m9s (ID: oke-redis)

       Apply complete! Resources: 1 added, 1 changed, 1 destroyed.
       ```

2. In the meantime, from another terminal, we can watch the number of pods being updated:  

      ```console
      kubectl get pods -w
      ```

   Your output should be something like:  

      ```console
      oke-redis-master-0                 0/1     Terminating   0          61s                                                                            
      oke-redis-slave-6bd9dc8d89-jdrs2   0/1     Running       0          3s                                                                             
      oke-redis-slave-6bd9dc8d89-kvc8r   0/1     Running       0          3s                                                                             
      oke-redis-slave-6fdd8c4b56-44qpb   0/1     Terminating   0          63s
      ```

## Next steps

In future articles, we'll look at other ways to extend the terraform-oci-oke module to deploy software on OKE.  

Check out these sites to explore more information about development with Oracle products:  

* [Oracle Developers Portal]
* [Oracle Cloud Infrastructure]
{% endslides %}

<!--- links -->

[Signing Up for Oracle Cloud Infrastructure]: https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm
[Getting started with Terraform]: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformgettingstarted.htm
[Getting started with OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm

[OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm

[Terraform OKE]: https://github.com/oracle/sample-oke-for-terraform
[helm provider]: https://www.terraform.io/docs/providers/helm/index.html
[instructions]: https://github.com/oracle/sample-oke-for-terraform/blob/master/docs/instructions.md
[Redis helm chart]: https://github.com/helm/charts/tree/master/stable/redis
[sample repo]: https://github.com/oracle/sample-oke-for-terraform/blob/master/modules/oke/activeworker.tf

[Oracle Developers Portal]: https://developer.oracle.com/
[Oracle Cloud Infrastructure]: https://www.oracle.com/cloud/
