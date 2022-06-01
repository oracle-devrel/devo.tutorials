---
title: Making calls to the Oracle Cloud API using Postman
parent: tutorials
tags:
- api
- oci
- postman
thumbnail: assets/pexels-adis-bacinovic-7103901.jpg
date: 2022-02-03 07:19
description: Learn how to make calls directly to the OCI API using Postman.
categories:
- devops
author: tim-clegg
mrm: WWMK220203P00028
xredirect: https://developer.oracle.com/tutorials/making-calls-to-oci-api-with-postman/
---

{% imgx alignright assets/pexels-adis-bacinovic-7103901.jpg 800 534 "Mail box" %}

*Photo credit: Photo by [Adis Bacinovic](https://www.pexels.com/@adis-bacinovic-29729722?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels) from [Pexels](https://www.pexels.com/photo/close-up-shot-of-a-mailbox-7103901/?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels)*

> This post is the author’s “notes from the field,” a personal exploration of the topic, filled with all of the journey’s pitfalls and little “Aha!” moments. It’s not meant to be a tutorial, but to illustrate the patterns and troubleshooting mindset it sometimes takes to successfully run a thing. Follow along and enjoy.
{:.notice}

Often when I'm building an automated solution, I'll look at the [documentation for the OCI Terraform Provider]. Terraform is my typical go-to tool these days for automating OCI infrastructure, so it's a logical place to start. Thankfully, the OCI Terraform Provider does a good job of sticking pretty close to the OCI API, so much of the terminology will be the same between the two. Sometimes, though, the Terraform documentation doesn't have all of the details I need and I have to go a level deeper. This is the point where I typically dive into the [OCI API docs].

## The OCI API

OCI has a terrific API. Really. In case you haven't had the pleasure of perusing it, check out the [full API details]. It's definitely worth digging in to.  

The OCI API does have one or two idiosyncrasies, though, especially the signing process. It can be somewhat involved, which means that you can't just easily "curl" it with off-the-shelf curl. Fortunately, there are [plenty of examples], making it easier than ever to interact with the OCI API with your favorite language. I've also shared a quick-and-dirty way to interact with the OCI API using Ruby in [another article]. Even with these tools, it still isn't easy yet for me to fully explore the OCI API.

## Interacting with the OCI API

This is where tools like [Paw] and [Postman] shine. They're both built to make it really easy to interact with APIs, and the type of apps I like to have on hand when I need to easily (and quickly) interact with the OCI API. Of the two, I opted to go with Postman since it doesn't require a purchase (at least for the bare-bones functionality).  

I started searching for some different options on how to get Postman to send the necessary format and stumbled across this [great article] which covered exactly what I was looking for. I followed the directions, which are summarized in the sections below.

## First try

1. Clone the [repo]
2. Import the `OCI_Environment` environment
3. Set the values for the `tenancyId`, `authUserId`, `keyFingerprint`, and `privateKey` variables  
   (only setting the `Current Value`, not the `Initial Value` for each)
4. Import the `OCI_REST_INITIALIZATION` collection
5. Run the `ONE_TIME_INITIALIZATION_CALL` call within the `OCI_REST_INITIALIZATION` collection
6. Import the `OCI_REST_COLLECTION`
7. Modify the `GET_OCI_ANNOUNCEMENTS` call for the proper endpoint and `compartmentId`

At this point, I tried to run `GET_OCI_ANNOUNCEMENTS`, but didn't have any success. I validated all of my credentials and they were correct... What?!  Why?!  

I noticed that my API key had a password, but I hadn't entered it anywhere. This is when I face-palmed myself, realizing that I'd failed to set the `passphrase` variable (again, just the `Current value`). After doing that, it worked great!  

Ugh. Some of the simplest things can present the greatest challenges!

## Finally working

To summarize, here are the steps I took that worked for me:  

1. Clone the [repo]
2. Import the `OCI_Environment` environment
3. Set the values for the `tenancyId`, `authUserId`, `keyFingerprint`, `privateKey`, and **`passphrase`** variables  
   (only setting the `Current Value`, not the `Initial Value` for each)
4. Import the `OCI_REST_INITIALIZATION` collection
5. Run the `ONE_TIME_INITIALIZATION_CALL` call within the `OCI_REST_INITIALIZATION` collection
6. Import the `OCI_REST_COLLECTION`
7. Modify the `GET_OCI_ANNOUNCEMENTS` call for the proper endpoint and `compartmentId`

Which is almost identical to the first pass, except this time I made sure to set the `Current Value` of the `passphrase` variable.  

With that out of the way, I was able to move forward. I was thrilled by the ability to easily make calls, but what I really needed was the ability to quickly switch between different OCI environments.

## Multiple Postman Environments

One of the great things about Postman Environments is that they're designed to allow you to quickly switch as needed. My intention was to leverage a different Postman Environment for each OCI tenancy I needed to access through a handy custom script. I tried duplicating the `OCI_Environment` in the Postman Environment, making sure that the values got moved with it, but that didn't seem to work. Eventually, I discovered that I was copying the private key contents from one Environment to another, and that the formatting was being stripped/changed (within Postman). The solution was to copy the key contents and paste a fresh copy into the new Environment. Voila! Success!

## Refactoring the script

Now, I *should* have submitted a PR, but I'm including it here so I can share it for now. To get this super-awesome script to work with variables, there are a few small modifications that could be made:  

| Original line | New line |
|---------------|----------|
| `var host = pm.request.url.host.join(".") ;` | `var host = pm.variables.replaceIn(pm.request.url.host.join("."));` |
| `var escapedTarget = encodeURI(request.url.split(pm.request.url.host.join("."))[1]);` | `var escapedTarget = encodeURI(pm.variables.replaceIn(request.url.split(pm.request.url.host.join(".")))[1]);` |
| `body = pm.request.body.raw;` | `body = pm.variables.replaceIn(pm.request.body.raw);` |

The above few changes seem to permit me to use variables, which allows me to greatly extend the script.

## Refactored call

Now that we've sorted out the script, let's refactor the example given in the code, changing the `GET_OCI_ANNOUNCEMENTS` call. Start by adding the following variables:  

| Variable Lives In (Type) | Variable Name | Variable Value |
| -- | :--: | :--: |
| `OCI_REST_COLLECTION` (Collection) | `oci_domain` | `oraclecloud.com` |
| `OCI_Environment` (or whatever you're using) (Environment) | `oci_region` | `<the OCI region you're talking to>` |

Next, go to the `GET_OCI_ANNOUNCEMENTS` GET call and modify the request path to be:  

`https://announcements.{{oci_region}}.{{oci_domain}}/20180904/announcements?compartmentId={{tenancyId}}`  

This tells it to use the OCI region specified in the Environment, as well as the `tenancyId` (also specified in the Environment) and the OCI domain name that's set in the Collection.

## Conclusion

As usual, something that seemed so cut and dry ended up being quite a bit more involved. But, we've got a solution now, and a way to interact with the OCI API using Postman on our local computer. Yay!

<!--- Links -->

[documentation for the OCI Terraform Provider]: https://registry.terraform.io/providers/hashicorp/oci/latest/docs
[OCI API docs]: https://docs.oracle.com/en-us/iaas/api/#/
[full API details]: https://docs.oracle.com/en-us/iaas/api/#/
[plenty of examples]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/signingrequests.htm
[another article]: https://blogs.oracle.com/developers/post/making-quick-and-dirty-rest-calls-to-the-oci-api-in-ruby
[Paw]: https://paw.cloud
[Postman]: https://www.postman.com
[great article]: https://www.ateam-oracle.com/post/invoking-oci-rest-apis-using-postman
[repo]: https://github.com/ashishksingh/postman_collection_for_oci_rest/blob/master/OCI_REST_COLLECTION.postman_collection.json
