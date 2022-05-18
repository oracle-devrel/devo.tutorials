---
title: Why Infrastructure as Code?
parent:
- tutorials
- tf-101
sidebar: series
tags:
- open-source
- terraform
- iac
- devops
- get-started
categories:
- iac
- opensource
thumbnail: assets/terraform-101.png
date: 2021-09-28 08:13
description: Heard about Infrastructure as Code (IaC) but not sure what it's about
  or why you should care? This tutorial's for you!
toc: true
author: tim-clegg
redirect_from: "/collections/tutorials/1-why-iac/"
mrm: WWMK211117P00010
xredirect: https://developer.oracle.com/tutorials/tf-101/1-why-iac/
---
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

Terraform. Infrastructure-as-Code (IaC). Automation. DevOps. DevSecOps. So many buzz words floating around. What's the big deal anyway? And which one is right for me?  
There are lots of different ways to manage IT resources and cloud infrastructure. But what makes Terraform so great? And why should you care about IaC? IaC might not be for everyone, but it's for *almost* everyone.

This tutorial will cover many of the common ways to manage IT resources, explore the upsides and downsides of each, and get you a little more familiar with IaC.

For additional information, see:

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)
* [About the User Interfaces of the Oracle Integration Oracle Cloud Infrastructure (OCI) Console](https://docs.oracle.com/en/cloud/paas/integration-cloud/integration-cloud-auton/user-interfaces-oracle-integration-cloud-1.html)
* [Working with the Command Line Interface (CLI)](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
* [IaC tools](https://cool.devo.build/topics/iac)

## So many Ways to manage

Let's start with the basics. When there are IT resources to manage, what are some of the common options?

* GUI (aka Oracle Cloud Infrastructure (OCI) Console)
* Command Line Interface (CLI)
* API
* IaC tools

### GUIs

In many applications, most of us start with the GUI. If you work within the Oracle Cloud Infrastructure (OCI), you're probably already familiar with the [OCI Console](https://www.oracle.com/cloud/sign-in.html). Overall, GUIs are typically pretty fancy, fun, and easy to use. But while they can be entertaining and great for initially learning a system or platform, they're not always the most scalable or efficient. Also, GUIs require time and manual user intervention, unless you're using something to automate the pointing-and-clicking, such as [Selenium](https://www.selenium.dev) (a fairly niche edge case). Things only "work" when someone's there to click a button. It's difficult (read: *impossible*) to rapidly manage resources using a GUI. Just the time it takes to point, click, and wait for the browser to update isn't really ideal when you're trying to handle a critical situation.

On occasion, another downside to consider with GUIs is how difficult it can be to roll back a system should things go sideways. Many of us know all too well how rolling back a change can involve lots of pointing-and-clicking just to undo the changes that were previously made. In the end, there's more time and human involvement spent in the UI than actually fixing the problem. It's definitely not the best all-around solution. For the most part, GUIs can be great for learning and playing around, but definitely not ideal for maintaining anything beyond a lab or sandbox environment.

### CLIs

CLIs are a little bit better than GUIs for helping you manage critical issues. Instead of pointing-and-clicking, commands are directly issued into the application. When you get down to it, CLIs are really just a text user interface. Most CLIs allow for running "headless", meaning they don't require continuous user input (all input can be provided at runtime). One benefit is that it's easier to use CLIs with automated workflows, so it's definitely a step in the right direction. By themselves though, it's impossible to embed any sort of logic when using CLIs, unless there's some sort of scripting (shell scripts, Ruby, Python, etc.) involved. This means that it's great to send a single command (or even a series of commands), but it can be difficult to maintain a high level of assurance without more involved scripting logic being used with the CLI.

### APIs

Now we're talking! Who doesn't love APIs? At the end of the day, almost everything interacts with the underlying APIs. Most GUIs, CLIs, and even IaC tools interact with APIs to do what they do. Whether you use curl, [Postman](https://www.postman.com), [Paw](https://paw.cloud), or other tools, you're typically interacting with a single API endpoint. There's still an inherent lack of logic though, unless you use some sort of scripting or application to add it.

We've all written small scripts or apps that interact with APIs to achieve certain outcomes. This is terrific, but it's still pretty manually intensive to create. For many of us, it can still take a bit of time to custom-build a script or app for each type of management need. While this gives an extreme amount of customizability (the sky's the limit with what you can do), it's really not practical or scalable in the long run.

All cloud providers present an API for managing the platform and OCI is no exception. OCI provides a versatile [API interface](https://docs.oracle.com/en-us/iaas/api/) for both developers and users to utilize when interacting with the system. But the beauty here lies in OCI's flexibility, and the API is only one of serveral options open to you. There are other tools such as [Upbound](https://www.upbound.io) that offer a great twist for having a single interface managing multiple backend interfaces.

### IaC tools

When you really need to tailor your environment and maximize control over how it performs, IaC tools are what you need. IaC tools are designed from the ground-up to manage infrastructure resources using code. Resources are defined within the code, with the tool itself providing the necessary structure and logic to quickly and easily build a definition of what you need or want an environment to be. The basic "scaffolding" (logic elements, API interactions, etc.) are all abstracted, allowing you to focus on describing the resources you need or want to exist in the environment.

By far, this is one of the easiest and fastest ways to build and maintain cloud environments. But this isn't just limited to the cloud, on-premesis resources can often be managed with IaC tools as well. Are you using multiple cloud providers? Even more reason to utilize IaC in managing your IT infrastructure.

With IaC, it's common to use Git on the back-end. Git allows you to get a deep history of changes and its robust version control system enables easy and rapid rollbacks. Additionally, if you use Git for storing the code definitions, you're able to use standard processes and tools to monitor/approve/manage changes before they're made. Whether using policy-as-code (such as [Open Policy Agent](https://www.openpolicyagent.org), with implementations such as [Policy-as-Code on OCI using Open Policy Agent](https://github.com/oracle-devrel/oci-pac-opa)) or a manual pull request (PR)/merge request (MR) review process, you can have a really solid review/approval/compliance mechanism (not to mention yet another audit trail that's separate from the cloud/platform itself).

#### Infrastructure management

One of the most common and popular IaC tools is [HashiCorp Terraform](https://www.terraform.io). Other tools, such as [Pulumi](https://www.pulumi.com), are also available, but the common goal of each is the programmatic management of infrastructure.

#### Configuration management

Sometimes infrastructure isn't your major concern and what you really need are tools that predominantly operate in the realm of configuration management, such as [Ansible](https://www.ansible.com) or [Chef](https://www.chef.io)/[Cinc](https://cinc.sh). These are all options for managing infrastructure as well, but you may be better off with tools that focus exclusively on *infrastructure management*. For OCI's part, it's certainly no exception in supporting many of these different platforms.

## IaC and Terraform

In the rest of this series, we're going to target using Terraform to manage OCI infrastructure. Why Terraform? It's fairly mature at this point, widely adopted, and has support for a wide variety of cloud platforms, including OCI. Additionally, there are plenty of resources available and Terraform enjoys strong user support, making it an ideal tool. Terraform is mainly targeted at managing infrastructure and not so much the configuration management side of things. But it's super powerful when combined with a traditional configuration management tool like Ansible.

## What's Next

By now, you should be a little more familiar with IaC and ready to get started with Terraform!

Until your next lesson, happy coding! Take a look at the [next lesson](2-experiencing-terraform) in the Terraform 101 series and go through a very quick experience in using Terraform. From there, you'll dive into several aspects of how Terraform works.

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
