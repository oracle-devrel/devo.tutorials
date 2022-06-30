---
title: Using OCI Cloud Shell & Bastion with MySQL Database Service
parent: tutorials
tags:
- oci
- mysql
- always-free
categories:
- frameworks
- cloudapps
thumbnail: assets/sql-dolphin.png
date: 2021-10-26 16:48
description: Recently, Oracle added a Bastion Service to OCI. This tutorial walks
  you through using this service with OCI Cloud Shell.
author: lefred
mrm: WWMK211125P00026
xredirect: https://developer.oracle.com/tutorials/oci-shell-bastion-mysql/
slug: oci-shell-bastion-MySQL
---

In 2021, Oracle added a Bastion Service to Oracle Cloud Infrastructure (OCI). Along with it, the OCI Dashboard now features the ability to use a browser-based terminal: Cloud Shell.  

Today, we'll show you how to use these two components to connect from a browser to a MDS DB System.  

Key topics covered in this tutorial:  

- Setting up a Bastion Service
- Starting a Cloud Shell
- Initiating a Bastion Session
- Connecting to MDS

Let's get started!

## Find the MySQL DBs IP address

First, we need the MySQL DB System’s IP:  

{% imgx aligncenter assets/system-details-IP.jpg 2480 1366 "System details in OCI with IP address highlighted" %}

So, in this example, the MDS Instance we want to connect to has an IP of 10.0.0.99.

## Set up the Bastion Service

Next, we'll create a new Bastion Service that will allow us to create a SSH Tunnel to our MySQL DB System.

### Connect to the Bastion Service Dashboard

The Bastion Service’s dashboard is located in **Identity & Security**:

{% imgx aligncenter assets/identity-security-dash.jpg 2356 1214 "Identity and Security dashboard, where access Bastion" %}

>**Note:** If this is the first time you create a Bastion, the list will be empty and you just need to create one:  
{:.notice}

{% imgx aligncenter assets/create-bastion-button.jpg 2470 896 "The 'Create Bastion' button if you've not created one before" %}

### Set up the VCN

Now, we need to select the Virtual Cloud Network (VCN), the subnet, and a block of allowed IPs. Since we don't know the IP of the Cloud Shell, we'll just use `0.0.0.0/0`:  

{% imgx aligncenter assets/configuring-bastion.jpg 2486 1794 "With Bastion selected, begin to configure its instance" %}

>**Note:** If you don't like to use 0.0.0.0/0, you need to add the public IP used by Cloud Shell with \32:  
{:.notice}

```console
curl ifconfig.me
```

Sample output:  

```console
1XX.XXX.XXX.XXX
```

## Create a session

Now that the Bastion is created, we need to create a session that will be used to create the SSH Tunnel to MDS.  

But before creating the session, we'll start the Cloud Shell and generate a SSH Key we will use for the tunnel’s session.  We'll take a look at that in the next section.  

## Cloud Shell

To Start Cloud Shell, you just select the **shell** icon at the top right corner of the OCI Dashboard:  

{% imgx aligncenter assets/cloud-shell-button.jpg 738 190 "Click the Cloud Shell button to get started" %}

>**Note:** This will open the Cloud Shell in the browser. It may take some time to open the first time.  
{:.notice}

### Create SSH key

In the Cloud Shell, we can now create the SSH Key we need using the following command:  

````console
ssh-keygen -t rsa
````

As you can see below, the public key we need will be stored in `~/.ssh/id_rsa.pub`:

{% imgx aligncenter assets/public-key-location.jpg 1844 1098 "The public key is stored in ~/.ssh/id_rsa.pub:" %}

## Bastion Session

Now that we have all we need to create the Bastion Session for the SSH Tunnel, we can go back to the Bastion we created earlier and create a new session:  

{% imgx aligncenter assets/create-new-bastion-session.jpg 2514 1322 "Create a new Bastion session" %}

After you select **Creation Session**, you will need to do the following:  

- set the **SSH port forwarding session** as *Type*
- add the MySQL Database System’s IP
- paste in the SSH Public Key

Once the session is created (which may take upwards of two hours), you will have something that looks like this:

{% imgx aligncenter assets/dotted-menu-button.jpg 1942 498 "Click the vertical, dotted item" %}

### Locate the ssh command

If you select the **kebob** icon (the 3 vertical dots), you can view or copy the ssh command we need to run in Cloud Shell:

{% imgx aligncenter assets/view-ssh-command.jpg 2516 1904 "Copy the ssh command" %}

>**Notes:**
>
>- **`-i <privateKey>`** is not really required since we only have one single key for the moment.
>- The error message **`bind: Cannot assign requested address`** is not a problem.  
>   This message only displays because because the Cloud Shell tries to bind on ipv6 too. If you want to avoid it, just add **`-4`** between ssh and **`-i`** like this:
>
>     ```console
>     ssh -4 -i
>     ```
>
>- Note the **`&`** at the end of the main ssh command.
{:.notice}

## Connecting to MDS

And finally, we can connect to MySQL Database Service’s instance from Cloud Shell simply by using the MySQL Shell:  

{% imgx aligncenter assets/cloud-connect-from-shell.jpg 2536 2070 "Server version highlighted in shell" %}

As you can see, it’s easy to connect from Cloud Shell once the Tunnel is ready!  

>**Recommendation:** To **Dump & Load data** to/from MDS, we recommend using a dedicated compute instance with multiple cores instead of Cloud Shell.
{:.notice}

## What's next

To explore more information about development with Oracle products:

- [Oracle Developers Portal](https://developer.oracle.com/)
- [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
