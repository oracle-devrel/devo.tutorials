---
title: Making calls to the OCI API using Postman
parent: tutorials
tags:
- api
- oci
- postman
thumbnail: assets/pexels-adis-bacinovic-7103901.jpg
date: 2022-01-04 07:19
description: Learn how to make calls directly to the OCI API using Postman.
categories:
- devops
author:
  name: tim-clegg
mrm: FIXME
---

{% imgx alignright assets/pexels-adis-bacinovic-7103901.jpg 800 534 "Mail box" %}

*Photo credit: Photo by [Adis Bacinovic](https://www.pexels.com/@adis-bacinovic-29729722?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels) from [Pexels](https://www.pexels.com/photo/close-up-shot-of-a-mailbox-7103901/?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels)*

Often times when I'm building an automated solution, I'll look at the [documentation for the OCI Terraform Provider](https://registry.terraform.io/providers/hashicorp/oci/latest/docs).  Terraform is my typical go-to-tool these days for automating OCI infrastructure, so it's a logical place to start.  Thankfully the OCI Terraform Provider does a good job of sticking pretty close to the OCI API (the terminology it uses, etc.).  Sometimes this just doesn't cut it, and I have to dig a level deeper.  This is where I typically dive into the [OCI API docs](https://docs.oracle.com/en-us/iaas/api/#/).

## The OCI API
OCI has a terrific API.  In case you've not had the pleasure of perusing it, check it out: [https://docs.oracle.com/en-us/iaas/api/#/](https://docs.oracle.com/en-us/iaas/api/#/).  It's worth a look and digging into.

To interact with the OCI API, there's an involved signing process, which means that you can't just easily "curl" it with off-the-shelf curl.  There are [plenty of exmaples](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/signingrequests.htm) however, making it easier than ever to interact with the OCI API with your favorite language.  I've shared a quick-and-dirty way to interact with the OCI API using Ruby in [another article](https://blogs.oracle.com/developers/post/making-quick-and-dirty-rest-calls-to-the-oci-api-in-ruby), which gives a fast way to access the OCI API with Ruby.  The kicker is that this isn't very easy for me to explore the OCI API.

## Interacting with the OCI API
This is where tools like [Paw](https://paw.cloud) and [Postman](https://www.postman.com) shine.  They're built to make it really easy to interact with APIs.  This is what I needed to have handy... a tool that allowed me to easily (and quickly) interact with the OCI API.  I opted to go with Postman, as it doesn't require a purchase (at least for the bare-bones functionality).

I started searching for some different options around how to get Postman to send the needed format and stumbled across this [great article](https://www.ateam-oracle.com/post/invoking-oci-rest-apis-using-postman), which covered exactly what I was looking for!  I followed the directions, essentially doing the following:

## First try
1. Cloning the [repo](https://github.com/ashishksingh/postman_collection_for_oci_rest/blob/master/OCI_REST_COLLECTION.postman_collection.json)
2. Importing the `OCI_Environment` environment
3. Setting the values for the `tenancyId`, `authUserId`, `keyFingerprint` and `privateKey` variables (only setting the `Current Value`, not the `Initial Value` for each).
4. Imported the `OCI_REST_INITIALIZATION` collection
5. Run the `ONE_TIME_INITIALIZATION_CALL` call within the `OCI_REST_INITIALIZATION` collection
6. Import the `OCI_REST_COLLECTION`
7. Modify the `GET_OCI_ANNOUNCEMENTS` call for the proper endpoint and `compartmentId`

At this point I tried to run `GET_OCI_ANNOUNCEMENTS`, but didn't have any success.  I validated all of my credentials and they were correct... What?!  Why?!

I noticed that my API key had a password... but I hadn't entered it anywhere.  This is when I face-palmed myself, realizing that I'd failed to set the `passphrase` variable (again, just the `Current value`).  After doing that, it worked great!

Ugh.  Some of the simplest things can present the greatest challenges!

## Finally working
To summarize, here are the steps I took that worked for me:

1. Cloning the [repo](https://github.com/ashishksingh/postman_collection_for_oci_rest/blob/master/OCI_REST_COLLECTION.postman_collection.json)
2. Importing the `OCI_Environment` environment
3. Setting the values for the `tenancyId`, `authUserId`, `keyFingerprint`, `privateKey` and `passphrase` variables (only setting the `Current Value`, not the `Initial Value` for each).
4. Imported the `OCI_REST_INITIALIZATION` collection
5. Run the `ONE_TIME_INITIALIZATION_CALL` call within the `OCI_REST_INITIALIZATION` collection
6. Import the `OCI_REST_COLLECTION`
7. Modify the `GET_OCI_ANNOUNCEMENTS` call for the proper endpoint and `compartmentId`

With that out of the way, I moved forward.  I was thrilled by the ability to easily make calls, but I needed the ability to move between different OCI environments easily.

## Multiple Postman Environments
Postman Environments are designed to allow you to quickly switch as-needed.  I wanted to leverage a different Postman Environment for each different OCI tenancy I needed to access, while using this handy-dandy script.  I tried duplicating the `OCI_Environment` Postman Environment, making sure that the values got moved with it, but that didn't seem to work.  Eventually I found that I was copying the private key contents from one Environment to another, and that the formatting was being stripped/changed (within Postman).  The solution was to copy the key contents and paste a fresh copy into the new Environment.  Voila!  It worked...

## Refactoring the script
Now, I *should* have submitted a PR... but I'm writing it here so I can share it for now... to get this super awesome script to work with variables, there's a few small modifications that could be made:

| Original line | New line |
|---------------|----------|
| `var host = pm.request.url.host.join(".") ;` | `var host = pm.variables.replaceIn(pm.request.url.host.join("."));` |
| `var escapedTarget = encodeURI(request.url.split(pm.request.url.host.join("."))[1]);` | `var escapedTarget = encodeURI(pm.variables.replaceIn(request.url.split(pm.request.url.host.join(".")))[1]);` |
| `body = pm.request.body.raw;` | `body = pm.variables.replaceIn(pm.request.body.raw);` |

The above few changes seem to allow me to use variables, which allows me to greatly extend it.

## Refactored call
Let's refactor the example given in the code, the `GET_OCI_ANNOUNCEMENTS` call.  Start by adding the following variables:

| Variable Lives In (Type) | Variable Name | Variable Value |
| `OCI_REST_COLLECTION` (Collection) | `oci_domain` | `oraclecloud.com` |
| `OCI_Environment` (or whatever you're using) (Environment) | `oci_region` | `<the OCI region you're talking to>` |

Now go to the `GET_OCI_ANNOUNCEMENTS` GET call and modify the request path to be: `https://announcements.{{oci_region}}.{{oci_domain}}/20180904/announcements?compartmentId={{tenancyId}}`.  This tells it to use the OCI region specified in the Environment, as well as the tenancyId (also specified in the Environment) and the OCI domain name that's set in the Collection.

## Conclusion
As usual, something that seemed so cut-and-dry ended up being quite a bit more involved.  But we've got a solution now and a way to interact with the OCI API using Postman on our local computer.  Yay!