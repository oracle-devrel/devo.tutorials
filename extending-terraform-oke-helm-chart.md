---
title: Extending Terraform OKE with a helm chart
parent: [tutorials]
tags: [kubernetes, devops, terraform]
date: 2021-10-28 12:00
description: Extend a sample repo with your own extensions to make reusable provisioning scripts.
---
{% slides %}
When designing the [Terraform OKE](https://github.com/oracle/sample-oke-for-terraform) provisioning scripts, one of the things we wanted to do is making it reusable. That means extending the base sample repo and add in your own extensions.

In this post, we will deploy a redis cluster to OKE using helm charts. Terraform has a [helm provider](https://www.terraform.io/docs/providers/helm/index.html) so we will use that.

First, clone the repo as we did before:

```console  
git clone [https://github.com/oracle/sample-oke-for-terraform.git](https://github.com/oracle/sample-oke-for-terraform.git) tfoke  
cd tfoke
```

Follow the [instructions](https://github.com/oracle/sample-oke-for-terraform/blob/master/docs/instructions.md) to create your Terraform variable file.

## Adding the helm provider and repository

In the oke module, create a file redis.tf. First, we need to configure the helm provider. Since we already have the kubeconfig file, we will use the File Config method. Add the following to redis.tf:

```terraform
provider "helm" {  
    kubernetes {  
        config_path = "${path.root}/generated/kubeconfig"  
    }  
}
```

Next, we will add a helm repository:

```terraform
data "helm_repository" "stable" {  
    name = "stable"  
    url = "https://kubernetes-charts.storage.googleapis.com"  
}
```

## Adding redis with a helm release

We will use the [redis helm chart](https://github.com/helm/charts/tree/master/stable/redis) to create a helm release. However, we want helm to deploy only after the worker nodes become active. In the [sample repo](https://github.com/oracle/sample-oke-for-terraform/blob/master/modules/oke/activeworker.tf), there’s a null_resource “is_worker_active” that you can use to set an explicit dependency. Add the following to the redis.tf:
   
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

If you prefer to customize your helm release using a yaml file, create a folder called resources under the oke module and copy the file values.yaml from the redis chart repo to redis_values.yaml:

```console
curl -o modules/oke/resources/redis_values.yaml https://raw.githubusercontent.com/helm/charts/master/stable/redis/values.yaml
```

Remove the individual settings in the redis release from the terraform code and add the following instead:

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

Note that you can also combine the 2 configuration approaches above but I prefer to keep mine in 1 location. You can change the values in the yaml file e.g. I changed the default cluster.slaveCount to 3 and persistence.size to 50Gi.

Run terraform init to download the helm provider and then apply again:

```console
terraform init  
terraform apply -auto-approve
```

Login to the bastion and do a helm list:

```console
helm list
NAME          REVISION    UPDATED                     STATUS        CHART         APP VERSION   NAMESPACE                          
oke-redis     1           Wed Apr 24 12:05:40 2019    DEPLOYED      redis-6.4.5   4.0.14        default
```

Next, get the notes provided by the redis chart:

```console
helm status
```

## Interacting with the Redis cluster

The following steps can be obtained when you run helm status.

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

Recall that in the yaml file, we set the number of redis slaves to 3. Let’s verify that:

```console
kubectl get pods  
NAME                               READY   STATUS    RESTARTS   AGE                                                                                
oke-redis-master-0                 1/1     Running   0          42m                                                                                
oke-redis-slave-79c45c57d8-67bxj   1/1     Running   1          42m                                                                                
oke-redis-slave-79c45c57d8-s6znq   1/1     Running   0          42m                                                                                
oke-redis-slave-79c45c57d8-wnfrh   1/1     Running   0          42m
```

You can see there are 3 pods running the redis slaves.

## Updating your release

Say, we now want to update the helm release to change some settings e.g. change the number of slaves from 3 to 2. We can do that manually using the helm cli:

```console
helm upgrade oke-redis stable/redis --set cluster.slaveCount=2
```

Or, we can change it in the redis_values.yaml and run terraform apply again:

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


In the meantime, from another terminal, we can watch the number of pods being updated:

```console
kubectl get pods -w

oke-redis-master-0                 0/1     Terminating   0          61s                                                                            
oke-redis-slave-6bd9dc8d89-jdrs2   0/1     Running       0          3s                                                                             
oke-redis-slave-6bd9dc8d89-kvc8r   0/1     Running       0          3s                                                                             
oke-redis-slave-6fdd8c4b56-44qpb   0/1     Terminating   0          63s
```

In future articles, we will look at other ways to extend the terraform-oci-oke module to deploy software on OKE.

Check out these sites to explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
{% endslides %}
