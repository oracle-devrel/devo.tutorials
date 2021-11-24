---
title: Modernizing the Healthcare platform with a GraalVM Proof of Value
parent: [tutorials]
tags: [graalvm, devops]
categories: [clouddev, modernize]
thumbnail: assets/modernize-healthcare-ambulance.jpeg
date: 2021-11-24 10:11
description: Ali makes the case for GraalVM in the healthcare industry by diving deep into a couple strategic solutions.
author:
  name: Ali Mukadam
  home: https://lmukadam.medium.com
  bio: For the past 16 years, Ali has held technical presales, architect and industry consulting roles in BEA Systems and Oracle across Asia Pacific, focusing on middleware and application development. Although he pretends to be Thor, his real areas of expertise are Application Development, Integration, SOA (Service Oriented Architecture) and BPM (Business Process Management).
  linkedin: alimukadam
---

{% imgx alignright assets/modernize-healthcare-ambulance.jpeg  “Stock ambulance visual” %}

Imagine a Fortune 5 company, empowering millions of people worldwide with the information, guidance, and tools to make personal health choices, setting  out to work on two parallel streams for modernizing their HealthCare platform’s Cloud-Native tech stack.

* **Stream 1**: Existing Microservices comprise Java 8 + Spring + OpenJDK JIT as JRE, to be containerized in a Hybrid Cloud platform.

* **Stream 2**: New Microservices with Kotlin + SpringBoot + OpenJDK 11 / GraalVM JIT, to be containerized in a Public Cloud platform.

## Tactical Solution — just-in-time with Stream 1:

* Lift and Shift Stream 1 from existing Hotspot JIT to GraalVM JIT
* Evaluate memory footprint, execution time improvement, and peak throughput with GraalVM
* Benchmark Stream 1 with GraalVM JIT vs HotSpot JIT on performance heuristics
* Endurance Testing with business-critical Healthcare API for benchmarking

## Strategic Solution — ahead-of-time with Stream 2:

* Application re-writes are planned and primarily targeted for the Public Cloud Platform
* Stream 2 tech stack is being considered with GraalVM Enterprise as an option depending on the outcome of Stream 1 benchmarking results
* Serverless (initial thoughts) has got some excitement for GraalVM’s Native-Image due to memory footprint and cold-startup optimization

{% imgx  assets/modernize-healthcare-api-exchange.png “Brand logos for FHIR and Cloud Native Computing Foundation” %}

## Healthcare Context

Interoperable healthcare IT enables clinicians to improve care coordinations and ensure that the information available to view in the healthcare services is part of a practitioners’ workflow. 

In terms of the technology stack, here are some considerations and goals:

1. Huge employee base, hundreds of APIs, and countless integrations and external systems
2. Optimize healthcare technology in order to provide a scalable tech infrastructure
3. Eliminate Local Resource Constraints for Building Cloud-Native Applications
4. Implement patterns and practices defined by DevOps and Cloud Centre of Excellence

### Support for Open Healthcare Standards

HL7 FHIR is a standard for health care data exchange published by HL7 (HL7 and its members provide a framework for the exchange, integration, sharing, and retrieval of electronic health information).

The CNCF Cloud Native Computing Foundation serves as the vendor-neutral home for many of the fastest-growing open-source projects

{% imgx assets/modernize-healthcare-hl7r.png  “HL7 Logo” %}

## Research and Evaluation Proof of Value

The engineering team identified key Proof-of-Value initiatives to optimize the existing tech stack with GraalVM without code changes, iteratively running performance loads with identified heuristics, benchmark observations, and comparisons. Initial performance load on GraalVM and benchmarking it against conventional JDKs (OpenJDK) for feasibility analysis. This included two rounds for performance evaluation.

 As a leading healthcare company (Fortune #5), the peak season is typically at the start of the year for all health plans renewables in the US, hence the priority at that time was to support business peak load in tech frozen state for 1–2 months. This resumed towards the end of Q1 2021.

### GraalVM EE v21.x on JDK8

Actual load runs on Dev Environment Sandbox.

Load Configuration Details:

* Concurrency: 100 users
* Ramp-up: 4 seconds
* Duration: 4 hours, 14400 seconds

The Clinical API was subjected to a medium spike load as part of the warm-up phase and peak throughput phase.

{% imgx assets/modernize-healthcare-load-test.png "Load Test Configuration" %}
{% imgx assets/modernize-healthcare-responsetimegraph.png "Response Time Graph" %}
{% imgx assets/modernize-healthcare-summary-report.png "Summary report of results" %}

The evaluation results are summarized in the table below. GraalVM performed better than Open JDK8 in most of the runs and gets better for longer runs.

{% imgx assets/modernize-healthcare-perform-characteristics.png  “Performance characteristics of GraalVM Enterprise vs. other runtimes” %}

## Conclusion

This collaboration has been mutually beneficial. Specfically, from learning about the implications of GraalVM in the healthcare domain by optimizing its workflow and improving patient outcomes and experience.

To learn more and get started with GraalVM, visit https://www.oracle.com/graalvm

Thanks to Pratik Prakash, Senior Member of Engineering at UnitedHealth Group, and Amitpal Singh Dhillon, Regional Director for Oracle Labs in Asia-Pacific & Japan, for their help in writing this blog post.
