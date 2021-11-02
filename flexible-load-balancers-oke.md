---
title: Creating flexible OCI Load Balancers with OKE
parent: tutorials
tags:
- kubernetes
categories: [clouddev]
date: 2021-11-02 16:17
description: New load balancer shapes mean more options to optimize your configuration. Ali walks you through how to create these shapes using OKE.
author: Ali Mukadam
---
Until recently, the OCI Load Balancer shapes were fairly restricted to a handful of options:

* 100 Mbps
* 400 Mbps
* 8000 Mbps

What’s more, if you had to change the shape, that would involve recreating the load balancer. 

**Not anymore.**

A few more options have been created for new load balancer shapes:

* 10 Mbps-Micro
* 10 Mbps
* [Flexible](https://blogs.oracle.com/cloud-infrastructure/post/announcing-oracle-cloud-infrastructure-flexible-load-balancing)

Now, [load balancer](https://blogs.oracle.com/cloud-infrastructure/introducing-dynamic-update-of-load-balancer-shapes) shapes are updatable without having to destroy and recreate them.

So let’s see how we can create them with OKE.

## Creating Load Balancer Shapes
First, let’s see what load balancer shapes are available in our tenancy.

```console
$ oci lb shape list --compartment-id ocid1.compartment.oc1..   
 "data": [                                                                                                                                                                                   
    {                                                                                                                                                                                         
      "name": "100Mbps"                                                                                                                                                                       
    },                                                                                                                                                                                 
    {                                                                                                                                                                                         
      "name": "10Mbps"                                                                                                                                                                        
    },                                                                                                                                                                                   
    {                                                                                                                                                                                         
      "name": "10Mbps-Micro"                                                                                                                                                                  
    },                                                                                                                                                                                       
    {                                                                                                                                                                                         
      "name": "400Mbps"                                                                                                                                                                       
    },                                                                                                                                                                                        
    {                                                                                                                                                                                         
      "name": "8000Mbps"                                                                                                                                                                      
    } ,                                                                                                                                                                                        
    {                                                                                                                                                                                         
      "name": "flexible"                                                                                                                                                                      
    }                                                                                                                                                                                         
  ]
}
```

As you can see, all the shapes are available. I could use a simple service to have the load balancer created but I want to show that these work equally well with ingress controllers, so let’s use the NGINX Ingress Controller to create one.

### Creating and Updating a Load Blanacer with an Ingress Controller
Let's first add an ingress controller:

```console
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
$ helm repo update
$ helm install nginx ingress-nginx/ingress-nginx
```
By default, this will create a load balancer with a of shape 100 Mbps:

```console
$ oci lb load-balancer get --load-balancer-id ocid1.loadbalancer...."shape-name": "100Mbps",...
```

Let’s say we want to change the shape to 400 Mbps. We can do this with a load balancer annotation and a helm upgrade:

```console
$ helm upgrade nginx ingress-nginx/ingress-nginx \
$ --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"="400Mbps"
```

If you want to avoid the horrible escapes and `\`, use the `values.yaml` file provided by the chart. All you would need to do is traverse to the annotations section and add the following:

```console
$ service.beta.kubernetes.io/oci-load-balancer-shape: "400Mbps"$ 
```

After the upgrade is done, we can check on the shape again as before. We can see it’s now been upgraded to 400 Mbps:

```console
...
$ "shape-name": "400Mbps",
...
```

Now, let’s say we want to create one with the flexible shape and want to take the opportunity to set the bandwidth limits. We can do this passing the following annotations:

When we check on the shape, we see the following:

```console
$ helm upgrade nginx ingress-nginx/ingress-nginx --set 
$ controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"="flexible" --set 
```

We can also dynamically change the bandwidth:

```console
$ helm upgrade nginx ingress-nginx/ingress-nginx --set controller.service.annotations."service\.beta\.kubernetes\.$ io/oci-load-balancer-shape"="flexible" --set controller.service.annotations."service\.beta\.kubernetes\.io/ 
$ oci-load-balancer-shape-flex-min"=10 --set controller.service.annotations."service\.beta\.kubernetes\.io/
$ oci-load-balancer-shape-flex-max"=500      
$ "shape-name": "flexible",
```

Now when we check the shape, we can see the changes reflected:

```console
$ "shape-details": {                                                                                                                                                                        
      "maximum-bandwidth-in-mbps": 500,                                                                                                                                                       
      "minimum-bandwidth-in-mbps": 10                                                                                                                                                         
    },                                                                                                                                                                                        
$ "shape-name": "flexible",
```

Finally, all the OCI Load Balancer annotations can be found [here](https://github.com/oracle/oci-cloud-controller-manager/blob/master/docs/load-balancer-annotations.md). These annotations allow you to control the behaviour of the load balancers created by OKE.