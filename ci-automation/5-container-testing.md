---
title: Automated Deployment and Testing with Container Instances
parent:
- tutorials
- ci-automation
sidebar: series
tags:
- open-source
- iac
- devops
- get-started
categories:
- iac
- opensource
thumbnail: assets/ci-automation.png
date: 2023-02-01 12:00
description: With the critical components of automated provisioning securely embedded in your brain, its time to put this knowledge into practice. This article will walk through the process of leveraging Container Instances within your CI/CD pipeline for automated testing activities.
toc: true
author: eli-schilling
redirect_from: "/collections/tutorials/1-automation-basics/"
mrm: 
xredirect: https://developer.oracle.com/tutorials/ci-automation/1-automation-basics/
slug: 5-container-testing.md
---
{% imgx aligncenter assets/ci-automation.png 400 400 "Automating Container Instances" "Container Instances Automation Tutorial Series" %}



Basic idea:
1. Push code to DevOps Repo
2. Trigger Build Pipeline
3. Deliver image to Artifact Repository
4. Create new CI resource
5. Automated validation
6. Destroy CI resource

Consider writing this from the perspective of moving from manual to automated.
At first we did it all by hand, seemed insurmountable to move to DevOps, taking one bite at a time it was feasible.