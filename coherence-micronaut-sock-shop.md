---
title: Creating an E-commerce Site with Oracle Coherence CE and Micronaut
parent:
- tutorials
tags:
- analytics
- oci
date: 2022-01-14 13:04
description: Coherence and Micronaut are powerful bedfellows when used together. This
  tutorial steps you through using them to build a hypothetical online sock shop.
  That's right, socks.
mrm: WWMK220110P00039
thumbnail: assets/coherence-micronaut-diagram.png
author:
  name: Aleks Seovic
  github: https://github.com/aseovic
xredirect: https://developer.oracle.com/tutorials/coherence-micronaut-sock-shopp/
---
Welcome!

In this tutorial, we'll walk through creating a stateful, microservices-based application that uses [Oracle Coherence CE] as a scalable embedded data store and [Micronaut Framework] as an application framework.  

Ultimately, the application we're building is an online store that sells socks, and is based on the [SockShop Microservices Demo] originally written and published under Apache 2.0 license by [Weaveworks].

If you're curious, check out a [working demo] of the original application.

**Demo summary:**

This demo still uses the original front-end implementation provided by Weaveworks, but all back-end services have been re-implemented from scratch using Micronaut Framework and Oracle Coherence in order to showcase the many features of the [Coherence Micronaut] integration.

We also provide the implementations of the same application that uses Spring Boot or Helidon as the application framework, in case one of those is your framework of choice.

* [Coherence Spring Sock Shop]
* [Coherence Helidon Sock Shop]

**Topics covered in this tutorial:**

* **Local install**
  * Installing the Coherence Operator
  * Installing a back end
  * (Optional) Installing the back end into the `sockshop` namespace
  * Scaling the back end
* **Complete application deployment**
* **Development (extending the application)**

**For more information, see:**

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)
* [Getting started with OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm)

## Prerequisites

To successfully complete this tutorial, you'll need the following:

* An Oracle Cloud Infrastructure (OCI) Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* **[OCI Cloud Shell]** - It provides a host of other OCI interfaces and tools.
* **Kustomize** - Make sure that you have a newer version of `kubectl` that supports it (at least 1.16 or above)

## Architecture

Before we get started, let's take a quick look at how this is all put together. The application consists of six back-end services rewritten from the ground up on top of Micronaut, implementing the API that the legacy `front-end` service expects.

{% imgx assets/coherence-micronaut-diagram.png "Network diagram of the sock shop" %}

**Reference -** You can find additional details for each service by following these links:

| Link | REST API |
| :-: | - |
| **[Product Catalog]** | allows you to search product catalog and retrieve individual product details |
| **[Shopping Cart]** | allows you to manage customers' shopping carts |
| **[Orders]** | allows customers to place orders |
| **[Payment]** | allows you to process payments |
| **[Shipping]** | allows you to ship orders and track shipments |
| **[Users]** | allows you to manage customer information and provides registration and authentication functionality for the customers |

## Project Structure

The main [Sock Shop] repository also contains Kubernetes deployment files for the whole application as well as a top-level POM file which allows you to easily build the whole project and import it into your favorite IDE.

## Getting started

Kubernetes scripts depend on Kustomize, so make sure that you have a newer version of `kubectl` that supports it (at least 1.16 or above).

The easiest way to try the demo is to use the Kubernetes deployment scripts from this [repo].

If you do, you can simply run the following commands from the `coherence-micronaut-sockshop-sample` directory.

### Install the Coherence Operator

Install the Coherence Operator using the instructions in the [Coherence Operator Quick Start] documentation.

### Installing a back end

1. Create a namespace in Kubernetes called `sockshop`:  

      ```bash
      kubectl create namespace sockshop
      ```

1. Install the back end into the `sockshop` namespace:

      ```bash
      kubectl --namespace sockshop apply -k k8s/coherence 
      ```

   The `-k` parameter above will use `kubectl` with `kustomize` to merge all the files under the specified directory and create all Kubernetes resources defined by them, such as deployments and services for each microservice.

### (Optional) Install the original WeaveSocks front end

> **Warning:** There are a few important things to note about the original implementation of the the WeaveSocks front end, so keep these in mind as you try out the demo. It has a few bugs, including some security issues, and it hasn't been actively maintained for a few years. However, if you want to deploy it to see how it interacts with our back-end services, you can follow the steps in the sections below.
{:.warn}

1. Install the `front-end` service by running the following command:  

      ```bash
      kubectl apply -f k8s/optional/original-front-end.yaml --namespace sockshop
      ```

2. Port-forward to the `front-end` UI using the following processes:

   **Mac/Linux:**

      ```bash
      kubectl port-forward --namespace sockshop service/front-end <localPort>:80
      ```

   **Windows:**

      ```bash
      kubectl port-forward --namespace sockshop service/front-end <localPort>:80
      ```

   > **Note:** If you have installed into a namespace then add the `--namespace` option to all `kubectl` commands in these instructions.
   {:.notice}

At this point, you should be able to access the home page for the application by pointing your browser to: `http://localhost:<localPort>/`.

You should then be able to browse the product catalog, add products to shopping cart, register as a new user, place an order, and browse order history, among other actions.

Once you are finished, you can clean up the environment by executing the following:  

```bash
kubectl delete -f k8s/optional/original-front-end.yaml --namespace sockshop
kubectl delete -k k8s/coherence --namespace sockshop
```

### Scale the back end

If you wish to scale the back end, use one of the following commands:

* **Scale only the orders microservice**

    ```bash
    kubectl --namespace sockshop scale coherence orders --replicas=3
    ```

* **Scale *all* the microservices**

    ```bash
    $ for name in carts catalog orders payment shipping users
        do kubectl --namespace sockshop scale coherence $name --replicas=3
    done
    ```

## Complete application deployment

The steps in the [Getting Started](#getting-started) section showed you how to run the application locally. However, that may not be enough if you want to experiment with scaling individual services such as tracing data in *Jaeger*, monitoring services via *Prometheus* and *Grafana*, or making API calls directly using *Swagger UI*.

To do all of the above, you'll need to deploy the services into a managed Kubernetes cluster in the cloud. You can accomplish this by following the same set of steps described above (except for port forwarding, which isn't necessary) and performing a few additional steps described more fully in the [Complete Application Deployment] document.

## Development

If you want to modify the demo, follow these steps:  

1. check out the code for the project
1. build it locally
1. **(optionally)** push new container images to the repository of your choice

**Reference -** [Development section]

## Next steps

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

## License

The Universal Permissive License (UPL), Version 1.0

<!--- links -->

[Oracle Coherence CE]: https://coherence.community/
[Micronaut Framework]: https://micronaut.io/

[sign up here for free]: https://signup.cloud.oracle.com/

[SockShop Microservices Demo]: https://microservices-demo.github.io
[Weaveworks]: https://go.weave.works/socks

[working demo]: http://socks.weave.works/

[Coherence Micronaut]: https://github.com/micronaut-projects/micronaut-coherence

[Coherence Spring Sock Shop]: https://github.com/oracle/coherence-spring-sockshop-sample
[Coherence Helidon Sock Shop]: https://github.com/oracle/coherence-helidon-sockshop-sample

[OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm

[Product Catalog]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/catalog
[Shipping]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/shipping
[Shopping Cart]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/carts
[Orders]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/orders
[Payment]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/payment
[Shipping]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/shipping
[Users]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/users

[Sock Shop]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master
[repo]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master

[Coherence Operator Quick Start]: https://oracle.github.io/coherence-operator/docs/latest/#/about/03_quickstart

[Complete Application Deployment]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/doc/complete-application-deployment.md

[Development section]: https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/doc/development.md

[Oracle Developers Portal]: https://developer.oracle.com/
[Oracle Cloud Infrastructure]: https://www.oracle.com/cloud/
