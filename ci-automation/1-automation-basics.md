---
title: Automation Basics
parent:
- tutorials
- ci-automation
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
thumbnail: assets/ci-automation.png
date: 2023-02-01 08:13
description: Heard about Infrastructure as Code (IaC) but not sure what it's about
  or why you should care? Tinkered with with OCI CLI but never really peeled back the layers? Well you're in the right place!
toc: true
author: eli-schilling
redirect_from: "/collections/tutorials/1-automation-basics/"
mrm: 
xredirect: https://developer.oracle.com/tutorials/ci-automation/1-automation-basics/
slug: 1-automation-basics
---
{% imgx aligncenter assets/ci-automation.png 400 400 "Automating Container Instances" "Container Instances Automation Tutorial Series" %}

What is the importance of automating infrastructure deployment and management? One key tenet of automation is to create consistent, repeatable capabilities that minimize / mitigate the potential for error. Whether you are just experimenting or working towards the implementation of error-free deployment activities, automation can help to realize those goals.

While there are a myriad of choices when it comes to managing cloud infrastructure, it is best to select a tool that **a)** you're comfortable with, and **b)** can streamline your management tasks while reducing ongoing level of effort.

In this tutorial we will focus on automating common tasks for OCI Container Instances, while discussing pros and cons of some alternate options.

For additional information, see:

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)
* [About the User Interfaces of the Oracle Integration Oracle Cloud Infrastructure (OCI) Console](https://docs.oracle.com/en/cloud/paas/integration-cloud/integration-cloud-auton/user-interfaces-oracle-integration-cloud-1.html)
* [Working with the Command Line Interface (CLI)](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
* [Terraform 101 series](https://developer.oracle.com/tutorials/tf-101)

## Before you begin

This tutorial assumes you already have some Terraform and/or OCI CLI experience. While not necessarily required, it would be beneficial that you check out the related tutorials first. Or just dive right in here, and use the other tutorials as a reference.

* [Terraform 101 series](https://developer.oracle.com/tutorials/tf-101)
* [OCI CLI Playground](https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/view-workshop?wid=650&clear=RR,180)

### CLIs

CLIs are a little bit better than GUIs for helping you manage critical issues. Instead of pointing-and-clicking, commands are directly issued into the application. When you get down to it, CLIs are really just a text user interface. Most CLIs allow for running "headless", meaning they don't require continuous user input (all input can be provided at runtime). One benefit is that it's easier to use CLIs with automated workflows, so it's definitely a step in the right direction. By themselves though, it's impossible to embed any sort of logic when using CLIs, this is where some sort of scripting (shell scripts, Ruby, Python, etc.) can add significant benefit. After determining the set of CLI commands to run, you can utilize the scripting tool of choice to implement logic and create repeatable automation activities.

### IaC tools

When you really need to tailor your environment and maximize control over how it performs, IaC tools are what you need. IaC tools are designed from the ground-up to manage infrastructure resources using code. Resources are defined within the code, with the tool itself providing the necessary structure and logic to quickly and easily build a definition of what you need or want an environment to be. The basic "scaffolding" (logic elements, API interactions, etc.) are all abstracted, allowing you to focus on describing the resources you need or want to exist in the environment.

By far, this is one of the easiest and fastest ways to build and maintain cloud environments. But this isn't just limited to the cloud; on-premesis resources can often be managed with IaC tools as well. Are you using multiple cloud providers? Even more reason to utilize IaC in managing your IT infrastructure.

With IaC, it's common to use Git on the back-end. Git allows you to get a deep history of changes and its robust version control system enables easy and rapid rollbacks. Additionally, if you use Git for storing the code definitions, you're able to use standard processes and tools to monitor/approve/manage changes before they're made. Whether using policy-as-code (such as [Open Policy Agent](https://www.openpolicyagent.org), with implementations such as [Policy-as-Code on OCI using Open Policy Agent](https://github.com/oracle-devrel/oci-pac-opa)) or a manual pull request (PR)/merge request (MR) review process, you can have a really solid review/approval/compliance mechanism (not to mention yet another audit trail that's separate from the cloud/platform itself).

#### Infrastructure management

One of the most common and popular IaC tools is [HashiCorp Terraform](https://www.terraform.io). Other tools, such as [Pulumi](https://www.pulumi.com), are also available, but the common goal of each is the programmatic management of infrastructure.

#### Configuration management

Sometimes infrastructure isn't your major concern and what you really need are tools that predominantly operate in the realm of configuration management, such as [Ansible](https://www.ansible.com) or [Chef](https://www.chef.io)/[Cinc](https://cinc.sh). These are all options for managing infrastructure as well, but you may be better off with tools that focus exclusively on *infrastructure management*. For OCI's part, it's certainly no exception in supporting many of these different platforms.

## CLI and IaC (Terraform)

For the remainder of this series we are going to explore the capabilities of CLI and IaC for deploying and managing infrastructure. We'll compare the pros and cons of each so you can ultimately make the decision regarding which fits best for your particular situation.

## What's Next

By now, you should have a basic understanding of how to configure the tools (Command Line Interface and Terraform) illustrated in this tutorial. You're ready to dive right in and start automating.

Until your next lesson, happy coding! Take a look at the [next lesson](2-automated-deployment-cli) in the Container Instances Automation 101 series, and go through the process of deploying resources using the OCI CLI. After that, you'll experiment with Terraform before moving on to some more advanced use cases.

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)