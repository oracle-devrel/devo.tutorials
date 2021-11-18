---
title: Why Infrastructure as Code?
parent: [tutorials, tf-101]
sidebar: series
tags:
- open-source
- terraform
- iac
- devops
- beginner
categories:
- iac
- opensource
thumbnail: assets/terraform-101.png
date: 2021-09-28 08:13
description: Heard about Infrastructure as Code (IaC) but not sure what it's about
  or why you should care?  This tutorial's for you!
toc: true
author: tim-clegg
redirect_from: "/collections/tutorials/1-why-iac/"
---
{% imgx aligncenter assets/terraform-101.png 400 400 "Terraform 101" "Terraform 101 Tutorial Series" %}

Terraform.  Infrastructure-as-Code (IaC).  Automation.  DevOps.  DevSecOps.  So many buzz words are floating around... what's the big deal anyway?  There are lots of different ways to manage IT resources and cloud infrastructure.  What makes Terraform so great?  Why should you care about IaC?  IaC might not be for everyone, but it is for *almost* everyone.

## So Many Ways to Manage

Let's start with the basics.  When there are IT resources to manage, what are some of our common options?

* GUI (aka Console)
* Command-Line Interface (CLI)
* API
* IaC tools

### GUIs

Most of us start with the GUI.  In Oracle Cloud Infrastructure (OCI) this is the [OCI Console](https://www.oracle.com/cloud/sign-in.html).  GUIs are typically pretty fancy, fun, and easy to use.  While they can be entertaining and great for initially learning a system/platform, they're not always the most scalable or efficient.  UIs require time and manual user intervention (unless you're using something to automate the pointing-and-clicking, such as [Selenium](https://www.selenium.dev), but that's a pretty niche edge case).  Things only "work" when someone's there to click a button.  It's difficult (read: *impossible*) to rapidly manage resources using a UI.  Just the time it takes to point-and-click, plus wait for the browser to update... it's not super fast.

Another downside to consider with GUIs is that it's a bit more difficult to roll back should something go sideways.  Rolling back typically involves lots of pointing-and-clicking, undoing the changes that were previously made.  More time and human involvement.  Yeck.  Great for learning and playing around, but certainly not ideal for maintaining anything beyond a lab/sandbox environment.

### CLIs

CLIs are marginally better than a GUI.  Instead of pointing-and-clicking, commands are issued.  CLIs are really a text user interface.  Most CLIs allow for running "headless", meaning they do not require user input (all input can be provided at runtime).  One benefit here is that it's easier to use CLIs with automated workflows.  It's a step in the right direction.  Unless there's some sort of scripting (shell scripts, Ruby, Python, etc.) used, it's impossible to embed any sort of logic when using CLIs.  This means that it's great to send a single command (or even a string of commands), however it can be difficult to maintain a high level of assurance when using CLIs (without more involved scripting logic being used with the CLI).

### APIs

Who doesn't love APIs?  At the end of the day, almost everything interacts with the underlying APIs.  Most GUIs, CLIs, and even IaC tools interact with APIs to do what they do.  Whether you use curl, [Postman](https://www.postman.com), [Paw](https://paw.cloud), or other tools, you're typically interacting with a single API endpoint.  There's still an inherent lack of logic (unless you use some sort of scripting/application to add this).

Many of us have written small scripts/apps that interact with APIs to achieve certain outcomes.  This is terrific, but it's pretty manually intensive to create.  For many of us, it takes a short bit to custom-build a script/app for each type of management need.  While this gives an extreme amount of customizability (the sky's the limit with what you can do), it's really not practical or scalable.

All cloud providers present an API for managing the platform.  OCI is no exception, providing a terrific [API interface](https://docs.oracle.com/en-us/iaas/api/) for developers and users to utilize when interacting with OCI.  It's certainly one option.  There are other tools such as [Upbound](https://www.upbound.io) that offer a great twist for having a single interface managing multiple backend interfaces.

### IaC Tools

These are tools that are designed from the ground-up to manage infrastructure resources using code.  Resources are defined in code, with the tool itself providing the necessary structure and logic to quickly and easily build a definition of what you need/want an environment to be.  The basic "scaffolding" (logic elements, API interactions, etc.) are all abstracted, allowing you to focus on describing the resources you need/want to exist in the environment.

This is by far one of the easiest and fastest ways to build and maintain cloud environments.  This isn't limited to cloud - on-premesis resources can often be managed with IaC tools.  Are you using multiple cloud providers?  Even more reason to utilize IaC in managing your IT infrastructure.

With IaC, we're often using git on the back-end, allowing us to get a great history of changes (which can also allow for easy and rapid rollbacks).  Using git for storing the code definitions, we're able to use pretty standard processes and tools to monitor/approve/manage changes before they're made.  Whether using policy-as-code (such as [Open Policy Agent](https://www.openpolicyagent.org), with implementations such as [Policy-as-Code on OCI using Open Policy Agent](https://github.com/oracle-devrel/oci-pac-opa)) or a manual pull request (PR)/merge request (MR) review process, you can have a really solid review/approval/compliance mechanism (not to mention yet another audit trail that's separate from the cloud/platform itself).

One of the most common and popular IaC tools is [HashiCorp Terraform](https://www.terraform.io), with other tools (such as [Pulumi](https://www.pulumi.com)) also being available.  The end goal with these tools is to manage infrastructure programmatically.

Some like to use tools that are predominantly in the realm of configuration management (such as [Ansible](https://www.ansible.com), [Chef](https://www.chef.io)/[Cinc](https://cinc.sh), etc.  These are certainly options for managing infrastructure, but you may be better off with tools that focus on *infrastructure management* (and less about *configuration management*).  OCI is no exception in supporting many of these different platforms.

In the rest of this series, we're going to target using Terraform to manage OCI infrastructure.  Why Terraform?  It's fairly mature at this point, widely adopted and has support for a wide variety of platforms.  Many cloud platforms (including OCI) and IT systems support using Terraform to manage resources.  There are plenty of examples, platforms and strong user support for it, making it an ideal tool.  Terraform is targeted at managing infrastructure, not so much the configuration management side of things.  And it's super powerful when combined with a traditional configuration management tool like Ansible.

This series will take you through how to harness the power of infrastructure-as-code (IaC) in your environment.  If this is your first time using Terraform, you're a bit rusty, or you're just looking to fill any potential gaps in your knowledge, this should be a worthwhile time investment.  It's fairly short, but will take you through the basics of how Terraform works, then into an actual working example.  During the journey, you'll find several key resources which you'll find invaluable as you continue to work with Terraform to manage your OCI environment.

A picture is worth a thousand words.  Going through this tutorial, you'll be able to better understand why IaC is so cool and has gained so much traction.  You'll also learn how to harness IaC to improve the efficiency of managing your environment, and that alone is worth the time.

Until our next lesson, happy coding!  Take a look at the [next lesson](2-experiencing-terraform) to go through a very quick experience in using Terraform.  From there we'll dive into several aspects of how Terraform works.
