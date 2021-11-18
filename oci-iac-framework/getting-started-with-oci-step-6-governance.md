---
title: Governance
parent: [tutorials,oci-iac-framework]
tags: [open-source, terraform, iac, devops, beginner]
categories: [iac, opensource]
thumbnail: assets/landing-zone.png
date: 2021-10-18 20:00:00
description: Introduction to Governance as part of the OCLOUD framework
toc: true
author: kubemen
draft: true
---
{% imgx aligncenter assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

**Table of Contents**
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Governance](#governance)
- [Compartments](#compartments)
- [Cloud Costs](#cloud-costs)
- [Manage Cloud cost effectively (out of the box)](#manage-cloud-cost-effectively-out-of-the-box)
	- [Predictability and Control](#predictability-and-control)
	- [Visibility](#visibility)
		- [Deutsche Standardkontenrahmen](#deutsche-standardkontenrahmen)
			- [Standardkontenrahmen SKR 03](#standardkontenrahmen-skr-03)
			- [Standardkontenrahmen SKR 04](#standardkontenrahmen-skr-04)
	- [Unified Billing](#unified-billing)
	- [Invoices](#invoices)
	- [Payment Methods](#payment-methods)
- [Manage Cloud cost effectively (more advanced)](#manage-cloud-cost-effectively-more-advanced)
	- [Optimization](#optimization)
	- [Extensibility](#extensibility)
	- [Modern Cloud Economics](#modern-cloud-economics)

<!-- /TOC -->

---
# Compartments
An important item to think about in the beginning is how you will organize your tenants. Oracle Cloud Infrastructure offers a key feature in building up a virtual PC with a tenancy, and has introduced compartments to have a proper organizational structure so you can organize your infrastructure and use policies per compartments for a proper role and permission concept.  

When you first start working with Oracle Cloud Infrastructure, you need to think carefully about how you want to use compartments to organize and isolate your cloud resources. Compartments are fundamental to that process. Most resources can be moved between compartments. However, it's important to think through the compartment design for your organization up front, before implementing anything.

Compartments are tenancy-wide, across regions. When you create a compartment, it is available in every region that your tenancy is subscribed to. You can get a cross-region view of your resources in a specific compartment with the tenancy explorer.

After creating a compartment, you need to write at least one policy for it, otherwise no one can access it (except administrators or users who have permissions set at the tenancy level). When creating a compartment inside another compartment (up to six-levels of sub-compartments are supported), the compartment inherits access permissions from compartments higher up its hierarchy.

When you create an access policy, you need to specify which compartment to attach it to. This controls who can later modify or delete the policy. Depending on how you've designed your compartment hierarchy, you might attach it to the tenancy, a parent, or to the specific compartment itself.

To place a new resource in a compartment, you simply specify that compartment when creating the resource (the compartment is one of the required pieces of information to create a resource). Keep in mind that most IAM resources reside in the tenancy (this includes users, groups, compartments, and any policies attached to the tenancy) and can't be created in or managed from a specific compartment.  

The structure of compartment varies in most cases by the organizational structure of the company. Well-established and large companies have, in many cases, centralized services like a security or a network compartment. Smaller and newer companies could have a leaner and less complex setup and are organized by projects without central entities which are responsible for certain elements in the infrastructure.  

The flexibility and the features by OCI in using compartments to organize and isolate cloud resources gives you the ability to build up your organization, or a desired new setup of your tenancy to fulfill your requirement in the organization of your elements.  

We are supporting both centralized and federated application DevOps models. Most common models are dedicated DevOps teams aligned with a single workload. In the case of smaller workloads or COTS or 3rd party application, a single AppDevOps team is responsible for workload operation. Independent of this model every DevOps team manages several workload staging environments (DEV, UAT, PROD) deployed to individual landing zones/subscriptions. Each landing zone has a set of RBAC permissions managed with OCI IAM provided by the Platform SecOps team.

When the base is handed over to the DevOps team, the team is end-to-end responsible for the workload. They can independently operate within the security guardrails provided by the platform team. If dependency on central teams or functions are discovered, it is highly recommended to review the process and eliminated as soon as possible to unblock DevOps teams.

project-based setup:  
{% imgx assets/OCI-central-mgmt-per_project.png "project-based setup" %}

department-based setup:  
{% imgx assets/OCI-central-mgmt-functional_compartments.png "department-based setup" %}
Both setups are just examples and will require a discovery workshop with the customer to build the compartment structure based on his requirements.

The landing zone - as part of the base setup in step 2 - is intented to provided an initial setup as blueprint for a classical 3-tier web-application where each layer is logically seperated for each department with centralized management of IAM, network, and security.


# Cloud Costs

It is key to have a clear view on cloud cost. [Foundations: OCI Pricing and Billing][cost_course1] and [Billing and Cost Management][cost_course2] allow you to improve control and visibility over your cloud budgets, usage, and spend.

This document gives you some guidance how to manage Cloud cost effectively. You will be alerted based on your own business rules and are able to individually break down all your cloud usage.
See Jenet (Cloud cost controller) in our 4 minutes [Introduction to Oracle Cloud Infrastructure Cost Management video][cost_video1] to get an initial idea of effective cloud cost management.


{% imgx assets/jenet.jpg "Jenet is doing Cost Management" %}

In our example Jenet ist responsible for Cost Management. This consists of:
- Manage Cloud Budgets
- Stay on top of cloud spend
- Analyze usage for cost optimization

To do so Oracle provides Jenet Enterprise-grade Controls for Cost Management.

{% imgx assets/enterprise.grade.controls.jpg "Enterprise-grade Controls for Cost Management" %}


OCI provides you a comprehensive set of tools out of the box to manage Cloud cost effectively.

# Manage Cloud cost effectively (out of the box)

[Billing and Payment Tools Overview][cost_doku_tools_overview] Oracle Cloud Infrastructure provides various billing and payment tools that make it easy to manage your service costs.

## Predictability and Control

{% imgx assets/predictability.jpg 45% "Predictability" %}
{% imgx assets/predictability.1.jpg 45% "Allocate Budgets" %}

Budgets are set on cost-tracking tags or on compartments (including the root compartment) to track all spending in that cost-tracking tag or for that compartment and its children. Budgets can be used to set thresholds for your Oracle Cloud Infrastructure spending. You can set alerts on your budget to let you know when you might exceed your budget, and you can view all of your budgets and spending from one single place in the Oracle Cloud Infrastructure console.

{% imgx assets/control.jpg 45% "Control" %}
{% imgx assets/control.1.jpg 45% "Set Treshholds" %}

See [Budgets Overview][cost_doku_budgets] for more information.

Budgets help you track your Oracle Cloud Infrastructure (OCI) spending. They monitor costs at a compartment level or cost-tracking tag level. You can set alerts on a budget to receive an email notification based on an actual or forecasted spending threshold. Budget alerts also integrate with the Events service. You can use this integration and the Oracle Notifications service to send messages through PagerDuty, Slack, or SMS.

You can also use the integration with Events service to trigger functions that create quotas resulting in budgets with hard limits.

{% imgx assets/3steps.png ""You can create and enforced budget in three easy steps" %}

- Create a budget and alert
- Create a function
- Create a rule

As a result, you can prevent the creation of new Compute resources in your tenancy. Anyone who tries to create resources after crossing the budget is unable to do so and sees a message notifying them that the compartment quota was exceeded.

Source: [Enforced budgets on OCI using functions and quotas][cost_3steps1]


## Visibility

[Cost Analysis Dashboard][cost_doku_analysis] provides easy-to-use visualization to help you track and optimize your Oracle Cloud Infrastructure spending by
- Service (shown by default when the Cost Analysis page first opens)
- Service and Description
- Service and SKU (Part Number)
- Service and Tag (see [Oracle Cloud Infrastructure Tagging][cost_tagging] for more details)
- Compartment (see [Oracle Cloud Infrastructure Compartments][cost_compartments] for more details)
- Monthly Costs

To use Cost Analysis, the following policy statement is required:
```
Allow group <group_name> to read usage-report in tenancy
```

{% imgx assets/visibility.jpg 45% "Visibility" %}
{% imgx assets/visibility.1.jpg 45% "Export Usage Report" %}


A cost report is a comma-separated value (CSV) file that is similar to a usage report, but also includes cost columns. The report can be used to obtain a breakdown of your invoice line items at resource-level granularity. As a result, you can optimize your Oracle Cloud Infrastructure spending, and make more informed cloud spending decisions.

A usage report is a comma-separated value (CSV) file that can be used to get a detailed breakdown of resources in Oracle Cloud Infrastructure for audit or invoice reconciliation.

To use cost and usage reports, the following policy statement is required:
```
define tenancy usage-report as ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq
endorse group <group> to read objects in tenancy usage-report
```

For more information, see [Cost and Usage Reports Overview][cost_doku_usage_report]

### Deutsche Standardkontenrahmen

Ein Kontenrahmen ist ein Verzeichnis, das alle Kostenarten systematisch numerischen Konten für die Buchführung in einem Wirtschaftszweig zuordnet. Er dient als Richtlinie und Empfehlung für die Aufstellung eines konkreten Kontenplans in einem Unternehmen. Damit sollen einheitliche Buchungen von gleichen Geschäftsvorfällen erreicht und zwischenbetriebliche Vergleiche ermöglicht werden. (Quelle: [Wikipedia][cost_kontenrahmen])

- SKR 03 (für publizitätspflichtige Firmen – Prozessgliederungsprinzip)
- SKR 04 (für publizitätspflichtige Firmen – Abschlussgliederungsprinzip, Kontenrahmen nach dem Bilanzrichtliniengesetz (BiRiliG) unter Berücksichtigung der Neuerungen des Bilanzrechtsmodernisierungsgesetz(BilMoG))


Wir stellen hier für Sie eine Abbildung der Standardkontenrahmen SKR 03, SKR 04 als ["Defined Tags"][cost_kontenrahmen_definedtag] zur Verfügung. Diese Tags können Sie mit dem [**Cost Analysis Dashboard**][cost_doku_analysis] auswerten.

Um die dafür notwendigen Namespaces zu **verwalten** benötigen Sie folgende Berechtigungen

```
Allow group GroupA to use tag-namespaces in tenancy
```


Um die dafür notwendigen Namespaces **auszuwerten** benötigen Sie folgende Berechtigungen

```
Allow group GroupA to read tag-namespaces in tenancy
```



**Standardkontenrahmen SKR 03**

z.B. [DATEV-Kontenrahmen nach dem Bilanzrichtlinie-Umsetzungsgesetz Standardkontenrahmen - Prozessgliederungsprinzip (SKR 03)][cost_kontenrahmen_skr03example]

Die hier beispielhaft implementierten Konten stammen aus der Quelle [Software, Anschaffung und Abschreibung][cost_kontenrahmen_skr03example1].


Mapping Standardkontenrahmen zu Namespaces

| Namespace | Key  | Value                                                                                                 | Resources                          |
| --------- | ---- | ----------------------------------------------------------------------------------------------------- | ---------------------------------- |
| SKR03     | 0    | Anlage- und Kapitalkonten                                                                             |                                    |
| SKR03     | 0027 | EDV-Software                                                                                          | Entgeltlich erworbene Konzessionen, gewerbliche Schutzrechte und ähnliche Rechte und Werte sowie Lizenzen an solchen Rechten und Werten |
| SKR03     | 0044 | EDV-Software                                                                                          | Selbst geschaffene immaterielle Vermögensgegenstände |
| SKR03     | 1    | Finanz- und Privatkonten                                                                              |                                    |
| SKR03     | 2    | Abgrenzungskonten                                                                                     |                                    |
| SKR03     | 3    | Wareneingangs- und Bestandkonten                                                                      |                                    |
| SKR03     | 4    | Betriebliche Aufwendungen                                                                             |                                    |
| SKR03     | 4806 | Wartungskosten für Hard- und Software                                                                 | Sonstige betriebliche Aufwendungen |
| SKR03     | 4822 | Abschreibungen auf immaterielle Vermögensgegenstände                                                  | Abschreibungen auf immaterielle Vermögensgegenstände des Anlagevermögens und Sachanlagen |
| SKR03     | 4964 | Aufwendungen für die zeitlich befristete Überlassung von Rechten (Lizenzen, Konzessionen)             | Sonstige betriebliche Aufwendungen |
| SKR03     | 7    | Bestände an Erzeugnissen                                                                              |                                    |
| SKR03     | 8    | Erlöskonten                                                                                           |                                    |
| SKR03     | 8995 | Aktivierte Eigenleistungen zur Erstellung von selbst geschaffenen immateriellen Vermögensgegenständen | Andere aktivierte Eigenleistungen  |
| SKR03     | 9    | Vortrags- und statistische Konten                                                                     |                                    |

Implementierungsbeispiel:

```
resource "oci_identity_tag_namespace" "skr03_tag_namespace" {
# Required
#------------------------------------------------------------
compartment_id = var.compartment_id
description    = "Standardkontenrahmen - Prozessgliederungsprinzip"
name           = "SKR03"

# Optional
#------------------------------------------------------------
defined_tags = {"SKR03.0"    = "Anlage- und Kapitalkonten"                                                                             }
defined_tags = {"SKR03.0027" = "EDV-Software (Entgeltlich erworbene Konzessionen, gewerbliche Schutzrechte und ähnliche Rechte ...)"   }
defined_tags = {"SKR03.0044" = "EDV-Software (Selbst geschaffene immaterielle Vermögensgegenstände) "                                  }
defined_tags = {"SKR03.1"    = "Finanz- und Privatkonten"                                                                              }
defined_tags = {"SKR03.2"    = "Abgrenzungskonten"                                                                                     }
defined_tags = {"SKR03.3"    = "Wareneingangs- und Bestandkonten"                                                                      }
defined_tags = {"SKR03.4"    = "Betriebliche Aufwendungen"                                                                             }
defined_tags = {"SKR03.4806" = "Wartungskosten für Hard- und Software"                                                                 }
defined_tags = {"SKR03.4822" = "Abschreibungen auf immaterielle Vermögensgegenstände"                                                  }
defined_tags = {"SKR03.4964" = "Aufwendungen für die zeitlich befristete Überlassung von Rechten (Lizenzen, Konzessionen)"             }
defined_tags = {"SKR03.7"    = "Bestände an Erzeugnissen"                                                                              }
defined_tags = {"SKR03.8"    = "Erlöskonten"                                                                                           }
defined_tags = {"SKR03.8995" = "Aktivierte Eigenleistungen zur Erstellung von selbst geschaffenen immateriellen Vermögensgegenständen" }
defined_tags = {"SKR03.9"    = "Vortrags- und statistische Konten"                                                                     }
is_retired   = false
}
```

**Standardkontenrahmen SKR 04**

z.B. [DATEV-Kontenrahmen nach dem Bilanzrichtlinie-Umsetzungsgesetz Standardkontenrahmen - Abschlussgliederungsprinzip (SKR 04)][cost_kontenrahmen_skr04example]

Die hier beispielhaft implementierten Konten stammen aus der Quelle [Software, Anschaffung und Abschreibung][cost_kontenrahmen_skr03example1].

Mapping Standardkontenrahmen zu Namespaces

| Namespace | Key  | Value                                                                                                 | Resources                          |
| --------- | ---- | ----------------------------------------------------------------------------------------------------- | ---------------------------------- |
| SKR04     | 0    | Anlagevermögen (Bestand: Aktiv)                                                                       |                                    |
| SKR04     | 0135 | EDV-Software                                                                                          | Entgeltlich erworbene Konzessionen, gewerbliche Schutzrechte und ähnliche Rechte und Werte sowie Lizenzen an solchen Rechten und Werten |
| SKR04     | 0144 | EDV-Software                                                                                          | Selbst geschaffene immaterielle Vermögensgegenstände |
| SKR04     | 1    | Umlaufvermögen (Bestand: Aktiv)                                                                       |                                    |
| SKR04     | 2    | Eigenkapitalkonten (Bestand: Passiv)                                                                  |                                    |
| SKR04     | 3    | Fremdkapitalkonten (Bestand: Passiv)                                                                  |                                    |
| SKR04     | 4    | Betriebliche Erträge (Erfolg: Ertrag)                                                                 |                                    |
| SKR04     | 4825 | Aktivierte Eigenleistungen zur Erstellung von selbst geschaffenen immateriellen Vermögensgegenständen | Andere aktivierte Eigenleistungen  |
| SKR04     | 5    | Betriebliche Aufwendungen (Erfolg: Aufwand)                                                           |                                    |
| SKR04     | 6    | Betriebliche Aufwendungen (Erfolg: Aufwand)                                                           |                                    |
| SKR04     | 6200 | Abschreibungen auf immaterielle Vermögensgegenstände                                                  | Abschreibungen auf immaterielle Vermögensgegenstände des Anlagevermögens und Sachanlagen |
| SKR04     | 6495 | Wartungskosten für Hard- und Software                                                                 | Sonstige betriebliche Aufwendungen |
| SKR04     | 6835 | Mieten für Einrichtungen (bewegliche Wirtschaftsgüter)                                                | Cloud Ressourcen wie z.B. Compartment, Group, Policy, User, Network, Storage, Compute können hier verbucht werden. |
| SKR04     | 6837 | Aufwendungen für die zeitlich befristete Überlassung von Rechten (Lizenzen, Konzessionen)             | Sonstige betriebliche Aufwendungen |
| SKR04     | 7    | Weitere Erträge und Aufwendungen (Erfolg: Aufwand, Ertrag)                                            |                                    |
| SKR04     | 9    | Vortrags- und statistische Konten (Bestand: Rechnungsabgrenzung usw.)                                 |                                    |

Implementierungsbeispiel:

```
resource "oci_identity_tag_namespace" "skr04_tag_namespace" {
# Required
#------------------------------------------------------------
compartment_id = var.compartment_id
description    = "Standardkontenrahmen - Abschlussgliederungsprinzip"
name           = "SKR04"

# Optional
#------------------------------------------------------------
defined_tags = {"SKR04.0"    = "Anlagevermögen (Bestand: Aktiv)"                                                                       }
defined_tags = {"SKR04.1"    = "Umlaufvermögen (Bestand: Aktiv)"                                                                       }
defined_tags = {"SKR04.0135" = "EDV-Software (Entgeltlich erworbene Konzessionen, gewerbliche Schutzrechte und ähnliche Rechte ...)"   }
defined_tags = {"SKR04.0144" = "EDV-Software (Selbst geschaffene immaterielle Vermögensgegenstände) "                                  }
defined_tags = {"SKR04.2"    = "Eigenkapitalkonten (Bestand: Passiv)"                                                                  }
defined_tags = {"SKR04.3"    = "Fremdkapitalkonten (Bestand: Passiv)"                                                                  }
defined_tags = {"SKR04.4"    = "Betriebliche Erträge (Erfolg: Ertrag)"                                                                 }
defined_tags = {"SKR04.4825" = "Aktivierte Eigenleistungen zur Erstellung von selbst geschaffenen immateriellen Vermögensgegenständen" }
defined_tags = {"SKR04.5"    = "Betriebliche Aufwendungen (Erfolg: Aufwand)"                                                           }
defined_tags = {"SKR04.6"    = "Betriebliche Aufwendungen (Erfolg: Aufwand)"                                                           }
defined_tags = {"SKR04.6200" = "Abschreibungen auf immaterielle Vermögensgegenstände"                                                  }
defined_tags = {"SKR04.6495" = "Wartungskosten für Hard- und Software"                                                                 }
defined_tags = {"SKR04.6837" = "Aufwendungen für die zeitlich befristete Überlassung von Rechten (Lizenzen, Konzessionen)"             }
defined_tags = {"SKR04.7"    = "Weitere Erträge und Aufwendungen (Erfolg: Aufwand, Ertrag)"                                            }
defined_tags = {"SKR04.9"    = "Vortrags- und statistische Konten (Bestand: Rechnungsabgrenzung usw.)"                                 }
is_retired   = false
}
```



## Unified Billing

This topic describes how you can unify billing across multiple tenancies by sharing your subscription. You should consider sharing your subscription if you want to have multiple tenancies to isolate your cloud workloads, but you want to have a single Universal Credits commitment. For example, you have a subscription with a $150,000 commitment, but you want to have three tenancies, because the credits are going to be used by three distinct groups that require strictly isolated environments.
Two types of tenancies are involved when sharing a subscription in the Console:
- The parent tenancy (the one that is associated with the primary funded subscription).
- Child tenancies (those that are consuming from a subscription that is not their own).


Notable benefits of sharing a subscription includes:

- Sharing a single commitment helps to avoid cost overages and allows you to consolidate your billing.
- Enabling multi-tenancy cost management. You can analyze, report, and monitor across all linked tenancies. The parent tenancy has the ability to analyze and report across each of your tenancies through Cost Analysis and Cost and usage reports, and you can receive alerts through Budgets.
- Isolation of data. Customers with strict data isolation requirements can use a multi-tenancy strategy to continue restricting resources across their tenancies.

The remainder of this topic provides an overview of how to share your subscription between tenancies, and provides best practices on how to isolate workloads, in order to help you determine if you should use a single-tenancy or multi-tenancy strategy. You can unify billing across multiple tenancies by sharing your subscription between tenancies.
To use subscription sharing, the following policy statements are required:
```
Allow group linkUsers to use organizations-family in tenancy
Allow group linkAdmins to manage organizations-family in tenancy
```

For more information, see [Unified Billing Overview][cost_doku_unified_billing].


## Invoices

You can view and download invoices for your Oracle Cloud Infrastructure usage.

Oracle Order-to-Cash has launched a dedicated page [Customer Billing Support][cost_invoice] to support our customers in understanding the Oracle Cloud invoicing experience. When visiting [Customer Billing Support][cost_invoice], customers can access content targeting specific needs and easily submit billing inquiries. The web page content is as follows:
- Billing Support: Email or call Oracle’s global Collections offices.
- Videos: Brief animations detailing various aspects of the invoice process.
  - Billing Basics: This journey through Oracle Cloud billing basics covers the events that trigger the invoicing process and when to expect a bill.
  - Subscription Invoicing: A guide to billing for Oracle metered and non-metered subscriptions.
  - Overage and Bursting: This video explains how to avoid unexpected charges for Oracle Cloud services.
  - Dispute Process: In this guide through the Oracle dispute process, customers learn who to contact and how to resolve billing questions.
- FAQ: Consult our frequently asked questions regarding Cloud invoicing.
- Glossary: Basic terminology used for Cloud features and services.

For questions or any additional information, please contact [cloud_invoicing_us@oracle.com](mailto:cloud_invoicing_us@oracle.com) or see [Viewing Your Subscription Invoice][cost_doku_invoice].


## Payment Methods

The Payment Method section of the Oracle Cloud Infrastructure Console allows you to easily manage how you pay for your Oracle Cloud Infrastructure usage. For more information, see [Changing Your Payment Method][cost_doku_payment].


# Manage Cloud cost effectively (more advanced)

## Optimization
{% imgx assets/optimization.jpg 45% "Optimization" %}
{% imgx assets/optimization.1.jpg 45% "Optimization" %}

If you’re using any cloud, you might regularly ask yourself questions like, “Why is the bill so high this month?” or “What would it actually cost to move this application to the cloud?” If so, this blog is for you. Today, I aim to make you familiar with the practices you need to control and predict your cost without compromising your performance.

Whether you’re part of the finance department in charge of controlling the budget, a business decision-maker evaluating a new project, or a DevOps engineer thinking of new functionality for your application, cloud cost management is mission-critical and can make or break your business. Accessing limitless possibilities is leading to cloud exuberance, and it’s time to tame the beast.

- Tag everything from day 1
- Sharing is not caring
- Time is money
- Choose performance responsibly
- Focus your attention on the whales
- Consolidate your databases
- Listen to your advisor
- Involve your stakeholders and automate
- Adopt cloud native technologies and containers
- Compare prices and total cost of ownership

You find more details to do this in [10 effective ways to save cost in the cloud][cost_optimization2].

## Extensibility
{% imgx assets/extensibility.jpg 45% "Extensibility" %}

[Oracle Cloud Infrastructure Usage and Cost Reports to Autonomous Database Tool usage2adw][cost_usage2adw]

usage2adw is a tool which uses the Python SDK to extract the usage and cost reports from your tenant and load it to Oracle Autonomous Database. (DbaaS can be used as well) Authentication to OCI by User or instance principals.

It uses APEX for Visualization and generates Daily e-mail report.

Main Features
- Usage Current State
- Usage Over Time
- Cost Analysis
- Cost Over Time
- Rate Card for Used Products


[<img alt="Cost Report" src="https://github.com/oracle/oci-python-sdk/raw/master/examples/usage_reports_to_adw/img/screen_4.png" title="example of a Cost Report" width="80%">][cost_report]

## Modern Cloud Economics

 [Unlocking business value of cloud for enterprise workloads][cost_economics]. A C-Suite’s guide to build and execute the Enterprise Cloud Strategy that delivers cloud’s full business value potential.
 Commercial principles enable enterprises to continuously leverage the optimal commercial frameworks of cloud service  provider, based on the changing usage profiles and deployment requirements, thereby de-risking unexpected cost overruns as well as maximizing the combined financial productivity of on-premise licenses, annual license support, and cloud subscription. The principles are the following:
 - Delink  data  and  network  linear  usage  from  cost
 - Avoid service deployment lock-in
 - Re-purpose on-premise spend to acquire future cloud capabilities

{% imgx assets/economics.jpg 80% "Modern Cloud Economics Enablers of Oracle Cloud Infrastructure (OCI)" %}


**OCI enablers for Commercial principles**

 OCI offers a range of commercial enablers to optimize rate, de-risk cost overruns and maximize financial productivity across the investments in Oracle on-premise licenses and cloud subscriptions. The key enablers are:
 - Best price performance guarantee
 - Avoid service deployment lock-in
 - Re-purpose on-premise spend to acquire future cloud capabilities



---

[< workload][workload] | [+][home] | [vizualize >][vizualize]

<!--- Links -->
[home]:       index
[intro]:      getting-started-with-oci-intro.md
[provider]:   getting-started-with-oci-step-1-provider
[base]:       getting-started-with-oci-step-2-base
[db-infra]:   getting-started-with-oci-step-3-database-infrastructure
[app-infra]:  getting-started-with-oci-step-4-app-infrastructure
[workload]:   getting-started-with-oci-step-5-workload-deployment
[governance]: getting-started-with-oci-step-6-governance
[vizualize]:  step7-vizualize

[cost_3steps1]:                 https://blogs.oracle.com/cloud-infrastructure/post/enforced-budgets-on-oci-using-functions-and-quotas
[cost_optimization2]:           https://blogs.oracle.com/cloud-infrastructure/post/10-effective-ways-to-save-cost-in-the-cloud-part-1
[cost_invoice]:                 https://www.oracle.com/corporate/invoicing/
[cost_tagging]:                 https://www.youtube.com/watch?v=7l5vQtxJFFE
[cost_compartments]:            https://www.ateam-oracle.com/oracle-cloud-infrastructure-compartments
[cost_course1]:                 https://www.youtube.com/watch?v=-RGzG3F9G_s&list=PLKCk3OyNwIzuHYigVbdtDOZOfChcotfj2&index=10
[cost_course2]:                 https://www.youtube.com/watch?v=uBIOGMqvMos&list=PLKCk3OyNwIzvlfs9W4JtguJdg8aa9hLfO
[cost_video1]:                  https://www.youtube.com/watch?v=DsFl6jjaRrY
[cost_doku_tools_overview]:     https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/billingoverview.htm
[cost_doku_budgets]:            https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/budgetsoverview.htm#Budgets_Overview
[cost_doku_analysis]:           https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/costanalysisoverview.htm
[cost_doku_usage_report]:       https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/usagereportsoverview.htm#Cost_and_Usage_Reports_Overview
[cost_doku_unified_billing]:    https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/unified_billing_overview.htm#unified_billing_overview
[cost_doku_invoice]:            https://docs.oracle.com/en/cloud/get-started/subscriptions-cloud/mmocs/viewing-your-subscription-invoice.html
[cost_doku_payment]:            https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/changingpaymentmethod.htm#Changing_Your_Payment_Method
[cost_report]:                  https://github.com/oracle/oci-python-sdk/raw/master/examples/usage_reports_to_adw/img/screen_4.png
[cost_usage2adw]:               https://github.com/oracle/oci-python-sdk/tree/master/examples/usage_reports_to_adw
[cost_economics]:               https://www.oracle.com/a/ocom/docs/cloud/modern-cloud-economics-by-oracle-insight.pdf
[cost_kontenrahmen]:               https://de.wikipedia.org/wiki/Kontenrahmen
[cost_kontenrahmen_definedtag]:    https://docs.oracle.com/en-us/iaas/Content/Tagging/Tasks/managingtagsandtagnamespaces.htm
[cost_kontenrahmen_skr03example]:  https://www.datev.de/web/de/datev-shop/material/kontenrahmen-datev-skr-03/
[cost_kontenrahmen_skr03example1]: https://www.haufe.de/finance/haufe-finance-office-premium/software-anschaffung-und-abschreibung_idesk_PI20354_HI2997902.html
[cost_kontenrahmen_skr04example]:  https://www.datev.de/web/de/datev-shop/material/kontenrahmen-datev-skr-04/

<!-- /Links -->
