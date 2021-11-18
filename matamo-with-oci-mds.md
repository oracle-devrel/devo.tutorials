---
title: Use Matomo Website Analytics on OCI with MDS 
parent: [tutorials]
categories: [modernize]
thumbnail: assets/matamo-progress-bar.webp
tags:
- mysql
- analytics
- backend
date: 2021-11-18 11:11
description: Matamo, an alternative to Google Analytics, is becoming increasingly popular. This walkthrough shows you how to use this powerful tool with MySQL Database Service and Oracle Cloud Infrastructure.
author: frederic-descamps
---
[Matomo](https://matomo.org/) is a Google Analytics alternative for tracking metrics on your websites. If you follow my blog, you know how easy it is to deploy popular Open Source web solutions like WordPress, Joomla!, Drupal, Moodle, and Magento on Oracle Cloud Infrastructure (OCI).

All these solutions are using MySQL Database Service to store their data.

I’ve recently added a [new stack](https://github.com/lefred/oci-matomo-mds) to  deploy Matomo. Of course, this can be a standalone installation to collect all your analytics from self-hosted websites, but today I'll describe how to use it with an existing stack we've already deployed on OCI.

For this example, I deployed WordPress using the following stack: [oci-wordpress-mds](https://github.com/lefred/oci-wordpress-mds).

The first step is to [deploy Matomo on OCI](https://www.oracle.com/cloud/sign-in.html?redirect_uri=https%3A%2F%2Fcloud.oracle.com%2Fresourcemanager%2Fstacks%2Fcreate%3FzipUrl%3Dhttps%3A%2F%2Fgithub.com%2Flefred%2Foci-matomo-mds%2Freleases%2Fdownload%2Fv1.0.0%2Fstack_matomo_mds.zip).

In the second screen of the Stack’s wizard, we specify that we want to use an existing infrastructure. This way we won’t need to recreate our VCN, subnets, security lists, Internet Gateway, etc. --- we want share what we've already deployed for WordPress:

{% imgx assets/matamo-existing-infrastructure.webp "OCI panel where you can toggle whether or not to use existing infrastructure" "OCI panel" %}

As you can see for the majority of the input fields, we need to provide the OCID. These can be found on the OCI’s dashboard. For example the OCID for the MySQL Database can be found here:

{% imgx assets/matamo-ocid-commandwebp.webp "OCI dashboard with callouts highlighting the Copy OCID command" "OCI dashboard" %}

We do this for every resources we want to reuse.

Then we create an apply job for the stack and when done we can get the public IP and other necessary information in the output section:

{% imgx assets/matamo-output-info.webp "The Outputs page in OCI, where you can find IP address, username, and other information" "Outputs page" %}

We can then enter the public IP in a browser and finish the installation:

{% imgx assets/matamo-progress-bar.webp "Matamo dashboard with a halfway-finished progress bar" "Matamo dashboard" %}

It’s important to use the right connector/adapter: **MYSQLI**.

Then we follow the wizard and enter the required information.

When done, we can add our WordPress in Matomo to start tracking it. The first step is the retrieve its name (in our case, its public IP as I don’t use DNS):

{% imgx assets/matamo-wordpress-public-ip.webp "WordPress public IP is available to be copied from the OCI dashboard" "WordPress public IP" %}

Once added in Matomo, we can retrieve the javascript code used to track our website:

{% imgx assets/matamo-js-tracking-code.webp "JS tracking code" "JS tracking code" %}

We copy that code and we go into the admin dashboard of our WordPress site to modify the theme and add the previous code in the header file:

{% imgx assets/matamo-wp-editor.webp "WordPress theme editor dashboard" "WordPress theme editor dashboard" %}

{% imgx assets/matamo-wordpress-js-paste.webp "JS code pasted into WordPress editor" "JS Code" %}

And this is all we needed to be able to get analytics of our website we deployed on OCI.

{% imgx assets/matamo-dash-final-code.webp "Matomo dashboard" "Matomo dashboard" %}
