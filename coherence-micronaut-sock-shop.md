---
title: Creating an E-commerce Site with Oracle Coherence CE and Micronaut
parent: [tutorials]
tags:  [analytics, oci]
date: 2022-01-14 13:04
description: Coherence and Micronaut are powrful bedfellows when used together. This tutorial steps you through using them to build a hypothetical online sock shop. That's right, socks.
mrm: WWMK220110P00039
thumbnail: assets/coherence-micronaut-diagram.png
author:
  name:  Aleks Seovic 
  github: https://github.com/aseovic
---
Welcome! 

In this tutorial, I'll walk you through creating a stateful, microservices based application that uses [Oracle Coherence CE](https://coherence.community/) as a scalable embedded data store, and [Micronaut Framework](https://micronaut.io/) as an application framework.

Ultimately, the application we're building is an online store that sells socks, and is based on the [SockShop Microservices Demo](https://microservices-demo.github.io) originally written and published under Apache 2.0 license by [Weaveworks](https://go.weave.works/socks).

You can see a working demo of the original application [here](http://socks.weave.works/).

This demo still uses the original front end implementation provided by Weaveworks, but all back end services have been re-implemented from scratch using Micronaut Framework and Oracle Coherence in order to showcase the many features of the [Coherence Micronaut](https://github.com/micronaut-projects/micronaut-coherence) integration.

We also provide the implementations of the same application that uses Spring Boot or Helidon
as the application framework, in case one of those is your framework of choice.

* [Coherence Spring Sock Shop](https://github.com/oracle/coherence-spring-sockshop-sample)
* [Coherence Helidon Sock Shop](https://github.com/oracle/coherence-helidon-sockshop-sample)

## How can I get started on OCI?

Remember that you can always sign up for free with OCI! Your Oracle Cloud account provides a number of Always Free services and a Free Trial with US$300 of free credit to use on all eligible OCI services for up to 30 days. These Always Free services are available for an **unlimited** period of time. The Free Trial services may be used until your US$300 of free credits are consumed or the 30 days has expired, whichever comes first. You can [sign up here for free](https://signup.cloud.oracle.com/).

# Table of Contents

* [Architecture](#architecture)
* [Project Structure](#project-structure)
* [Pre-Requisites](#pre-requisites)
* [Quick Start](#quick-start)
* [Complete Application Deployment](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/doc/complete-application-deployment.md)
* [Development](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/doc/development.md)
* [License](#license)

## Architecture

The application consists of six back end services (rewritten from the ground up on top of Micronaut, implementing the API that the legacy `front-end` service expects).

{% imgx assets/coherence-micronaut-diagram.png "Network diagram of the sock shop" %}

Find more details for each service by following these links:

- **[Product Catalog](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/catalog)**, which provides REST API that allows you to search product catalog and retrieve individual product details;

- **[Shopping Cart](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/carts)**, which provides REST API that allows you to manage customers' shopping carts;

- **[Orders](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/orders)**, which provides REST API that allows customers to place orders;

- **[Payment](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/payment)**, which provides REST API that allows you to process payments;

- **[Shipping](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/shipping)**, which provides REST API that allows you to ship orders and track shipments;

- **[Users](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/users)**, which provides REST API that allows you to manage customer information and provides registration and authentication functionality for the customers.

## Project Structure

The main [Sock Shop](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master) repository also contains Kubernetes deployment files for the whole application, top-level POM file which allows you to easily build the whole project and import it into your favorite IDE.

## Quick Start

Kubernetes scripts depend on Kustomize, so make sure that you have a newer version of `kubectl` that supports it (at least 1.16 or above).

The easiest way to try the demo is to use the Kubernetes deployment scripts from this repo.

If you do, you can simply run the following command from the `coherence-micronaut-sockshop-sample` directory.

### Install the Coherence Operator

Install the Coherence Operator using the instructions in the [Coherence Operator Quick Start](https://oracle.github.io/coherence-operator/docs/latest/#/about/03_quickstart) documentation.

### Installing a Back-end

Create a namespace in Kubernetes called `sockshop`.

```bash
$ kubectl create namespace sockshop
```

Install the back-end into the `sockshop` namespace.

 ```bash
$ kubectl --namespace sockshop apply -k k8s/coherence 
 ```

The `-k` parameter above will use `kubectl` with `kustomize` to merge all the files under the specified directory and create all Kubernetes resources defined by them, such as deployments and services for each microservice.

### (Optional) Install the Original WeaveSocks Front End

> Warning: The original WeaveSocks Front End has a few bugs, as well as some security issues, and it hasn't been actively maintained for a few years. However, if you want to deploy it nevertheless to see how it interacts with our back-end services, please follow the steps below.

Install the `front-end` service by running the following command:

```bash
$ kubectl apply -f k8s/optional/original-front-end.yaml --namespace sockshop
```

Port-forward to the `front-end` UI using the following processes:

**Mac/Linux**

```bash
$ kubectl port-forward --namespace sockshop service/front-end <localPort>:80
```

**Windows**

```bash
$ kubectl port-forward --namespace sockshop service/front-end <localPort>:80
```

> Note: If you have installed into a namespace then add the `--namespace` option to all `kubectl` commands in these instructions.

You should be able to access the home page for the application by pointing your browser to `http://localhost:<localPort>/`.

You should then be able to browse the product catalog, add products to shopping cart, register as a new user, place an order, and browse order history, among other actions

Once you are finished, you can clean up the environment by executing the following:

```bash
$ kubectl delete -f k8s/optional/original-front-end.yaml --namespace sockshop
$ kubectl delete -k k8s/coherence --namespace sockshop
```

### Scale Back-End

If you wish to scale the back-end, issue the following command:

Scale only the orders microservice

```bash
$ kubectl --namespace sockshop scale coherence orders --replicas=3
```

Or, alternatively, scale all the microservices

```bash
$ for name in carts catalog orders payment shipping users
    do kubectl --namespace sockshop scale coherence $name --replicas=3
done
```

## Complete Application Deployment

The Quick Start shows how you can run the application locally, but that may not be enough if you want to experiment with scaling individual services. Look at tracing data in Jaeger, monitor services via Prometheus and Grafana, or make API calls directly using Swagger UI.

To do all of the above, you need to deploy the services into a managed Kubernetes cluster in the cloud, by following the same set of steps described above (except for port forwarding, which is not necessary), and performing a few additional steps.

[Go to Complete Application Deployment section](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/doc/complete-application-deployment.md)

## Development

If you want to modify the demo, you will need to check out the code for the project, build it
locally, and (optionally) push new container images to the repository of your choice.

[Go to Development section](https://github.com/oracle/coherence-micronaut-sockshop-sample/blob/master/doc/development.md)

## License

The Universal Permissive License (UPL), Version 1.0
