---
title: Building Safe, Fast, and Manageable Applications with Rust and Oracle Cloud Infrastructure
parent:
- tutorials
- rust-on-oci
tags:
- open-source
- devops
- get-started
- back-end
- rust
categories:
- clouddev
- cloudapps
date: 2022-12-12 08:00
description: How to build safely with modern technology.
toc: true
author: oracle-developers
slug: rust-safe-fast-manageable
---
## Introduction

No question---building and managing modern technology is complex.

Datasets can be massive, expensive to compute, and require highly-performant processes to scale. Data security is critical to business sustainability and is difficult to execute. Architecting systems that can handle modern scale requires intelligent network load balancing and hardware availability.

When you combine all of those challenges (and more!), it becomes a daunting task to imagine how to build an app that simply *works*. Choosing the tools that solve these issues becomes a crucial question for developers.

In this piece, we'll make the case that by using **Rust**---a programming language that is fast, secure, memory-safe, and supports complex abstractions---in combination with **OCI**---a Platform-as-a-Service (PaaS) that provides fine-grained control, excellent security measures, and is optimized for performance---developers can have just the right tools to help tame the complexity of building modern software.

We will start with brief backgrounds on Rust and OCI. Then, we'll dive into several use cases of how Rust and OCI are an excellent solution for modern software applications.

## Why Rust?

**[Rust][1]** is an open source, general-purpose programming language optimized for **safety**, **concurrency**, and **speed**. Rust offers low-level memory access and, as such, can be used for systems programming. It also has a rich set of built-in types and interfaces that allow for code organization and reuse typically associated with higher-level languages.

**Safety** - Rust is considered *memory safe*. This means it protects developers from writing code that results in bugs related to memory access, such as dangling pointers, null pointers, buffer overflows, and so on. These bugs are often exploited as security vulnerabilities. Rust achieves memory safety through features such as a strong type system and the famous [Borrow Checker][2].

**Concurrency** - Rust has built-in support for concurrent and parallel programming. Developers can easily spawn threads and pass messages between them. A number of abstractions, such as [Atomic Reference Counter][3] (Arc) and [Tokio][4], protect against many of the classic dangers involved with concurrent programs. Combined with Rust's memory safety guarantees, this allows the compiler to catch many types of bugs before the code runs. The Rust team calls this "[Fearless Concurrency][5]."

**Speed** - In terms of performance, Rust is comparable to other lower-level languages like C and C++. Rust is compiled to native code, which results in a low memory footprint. Developers have access to many features that inform the compiler how types will be laid out in memory. Rust's type system also allows for Zero Cost Abstractions which means that many of the higher-level constructs do not come with a cost at runtime.

## Why Oracle Cloud Infrastructure (OCI)

[**[Oracle Cloud Infrastructure]{.underline}**][6] (OCI) is a set of complementary cloud services that enable you to build and run various applications and services in a highly available hosted environment.

OCI provides **high-performance compute capabilities** (as physical hardware instances) and **storage capacity** in a flexible overlay virtual network that is **securely accessible** from your on-premises network. By abstracting away the complexities of safely managing infrastructure, OCI enables businesses to deploy complex, modern applications quickly and for a fraction of the cost of staffing an internal IT team.

Now that we have a little background, let's look at three services offered on OCI, and explore how Rust works well with these features.

## Web and Cloud Native Applications

A large percentage of applications today are deployed as cloud-native apps. **OCI provides best-in-class tools for easily building, hosting, and maintaining these web and cloud-native applications**.

When deploying these apps, containerization has become the industry standard. OCI's [**[Container Registry]{.underline}**][7] allows developers to store container images and then securely access those images at any time. CI/CD pipelines can be designed to build and push images to Container Registry automatically. Containers can then be built from stored images and orchestrated via OCI [**[Container Engine for Kubernetes]{.underline}**][8]. Once the code is live, OCI offers resource monitoring with its **Events Service**.

Cloud-based applications built on this type of infrastructure can take many forms, such as ecommerce websites, REST APIs, or backend systems managing IoT devices.

**Rust**

Regardless of the specifics of the business domain, security, usability, performance, and time to market are critical to most apps. As seen above, Rust is designed to handle these challenges, especially with cloud-native applications.

**Safety** - Web and cloud-native apps have a much broader attack surface than isolated systems. Not only is the app publicly available, but when building software for the internet, developers typically use frameworks and libraries to solve common problems. This means that the attack surface extends to code that was authored by someone else.

Rust's memory safety greatly enhances the security of an application and the software it depends on. Fewer vulnerabilities also mean fewer security updates, which means less maintenance and reduced costs.

**Concurrency** - Poor app performance leads to higher costs, lower user retention, and the inability to execute expensive computations. This is especially true with cloud-based software that may deal with concurrency issues from socket connections to monetary transactions. Rust's promise of "Fearless Concurrency" allows developers to take advantage of OCI infrastructure to build correct and performant concurrent software.

**Speed** - In addition to the built-in Rust features that increase execution speed, the Rust ecosystem also has several frameworks that encourage rapid development. ORMs exist for data modeling and persistence layer abstraction. Some notable web frameworks that are gaining popularity include [Nickel.rs][9] or [Actix][10], both of which can take advantage of projects like [Diesel][11] for the database abstraction layer.

## Serverless Functions

Serverless functions are short-running processes that perform discrete tasks, such as processing image data, persisting data to cloud storage, or sending emails. They are usually invoked in response to events and can be chained together to accomplish tasks of arbitrary complexity. When the code is invoked, resources are automatically allocated to achieve configurable performance characteristics. When the code stops running, resources are deallocated. This allows for a cheap and sustainable choice over other alternatives.

OCI supports serverless functions with its **[Cloud Functions][12].** Cloud Functions conform to [Fn Project][13] standards and utilize OCI **Cloud Events** to trigger the invocation of functions. Because Cloud Functions are based on standards from the Fn Project, the code is portable between OCI and other infrastructures that also conform to Fn Project standards.

Cloud Functions has built-in support for several popular programming languages, such as Go, Node, and Ruby. Developers can use the Fn Project CLI to create, configure, and manage serverless functions easily.

**Rust**

**Safety** - Rust's compile time checks allow developers to write serverless functions with peace of mind knowing that the code is memory safe and free of many types of bugs prior to deployment. Rust also has a built-in test harness, providing even more confidence through the use of unit testing. Test code is not compiled into releases which keeps binaries small.

**Speed** - The event-based nature of serverless functions allows for triggering the process on a predefined schedule. One example is sending a notification to an IoT device every minute. Rust's low memory footprint and emphasis on performance make it an ideal choice for serverless functions, as tasks can be completed quickly and with low resource consumption. This saves money and energy resulting in fast, sustainable, cheap software solutions.

OCI Cloud Functions run inside docker images. Although Cloud Functions do not have direct support for Rust, developers can design and build images conforming to the Fn Project standards and deploy those images to the OCI infrastructure. Rust code can easily be compiled into executable binaries and built into container images for use in Cloud Functions.

## High Performance Computing Workloads

Sometimes it's necessary to perform computational operations that are extremely resource-intensive. Situations like this require massive processing power, which translates to large numbers of cores working in parallel. Core clusters are connected over a network and often write output to some form of storage. For these types of programs, performance is key.

OCI supports performance-intensive workloads with [**[High Performance Computing]{.underline}**][14] services. Programs have access to potentially tens of thousands of cores connected over a low-latency network. Developers can choose to run code on bare metal or virtual machines. OCI also offers preconfigured virtual machines for ML/AI data science applications with access to large storage volumes.

**Rust**

**Speed** - Again, Rust's performance characteristics make it a natural fit for these situations. Having low-level access allows developers to finely tune how data structures are laid out in memory and how algorithms interact with resources. When dealing with resource-intensive programming, speed directly translates to reduced energy consumption and costs.

**Concurrency** - Access to massive clusters of cores only increases productivity if the code running on the system can efficiently utilize as many cores as possible at any given time. Rust's support for parallel and concurrent programming has huge advantages here. Rust's memory safety and "Fearless Concurrency" allow developers to write complex parallel programs confidently and securely.

## Conclusion

The complex nature of software development requires developers to choose tools wisely. The correct combination of infrastructure and programming language has huge implications for the success or failure of a software system.

Successful modern software systems need to be secure, performant, and flexible enough to meet the changing needs of the domain in which they operate. OCI's commitment to, and investment in, fine grain control, security, and optimization is echoed by the Rust team and is reflected in the language and ecosystem. This makes Rust an excellent choice for building complex software on top of OCI.

  [1]: https://www.rust-lang.org/
  [2]: https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html
  [3]: https://doc.rust-lang.org/std/sync/struct.Arc.html
  [4]: https://www.google.com/url?q=https://tokio.rs&sa=D&source=docs&ust=1666376402644471&usg=AOvVaw0J9DysWwPHFaz8IUfOLRu5
  [5]: https://doc.rust-lang.org/book/ch16-00-concurrency.html
  [6]: https://www.oracle.com/cloud/
  [7]: https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryoverview.htm
  [8]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm
  [9]: https://nickel-org.github.io/
  [10]: https://actix.rs/
  [11]: https://diesel.rs/
  [12]: https://docs.oracle.com/en-us/iaas/Content/Functions/Concepts/functionsoverview.htm
  [13]: https://fnproject.io/
  [14]: https://www.oracle.com/cloud/hpc/
