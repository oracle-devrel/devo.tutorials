---
title: Getting Started with MySQL HeatWave on AWS
parent:
- tutorials
tags: 
- mysql
- database
- heatwave
- aws
categories:
- cloudapps
thumbnail: assets/a-mysqglhw-devrel0622-thmb001.png
date: 2022-06-16 17:00
description: Getting your OCI tenancy ready to connect to MySQL HeatWave on AWS. We will create a compute instance, DB System, and endpoint. We also began to provision MySQL HeatWave on AWS.
author: Victor Agreda
mrm: WWMK220224P00058
---
We live in a multi-cloud world, and that's why MySQL HeatWave for Amazon Web Service makes so much sense if you need a massively parallel, high performance, in-memory query accelerator for the MySQL Database Service. A combination that accelerates MySQL performance by orders of magnitude for combined analytics and transactional workloads (OLAP and OLTP). The MySQL Database Service is built on MySQL Enterprise Edition, which allows developers to quickly create and deploy secure cloud native applications using the world's most popular open source database.  

Oracle designed this so developers can focus on the important things, like managing data, creating schemas, and providing highly-available applications. MySQL HeatWave for Amazon Web Services (AWS) is a fully managed service, developed and supported by the MySQL team in Oracle. Oracle automates tasks such as backup, recovery, and database and operating system patching. "Worry less, crunch more," as we say!  

If you’ve never heard of HeatWave, think of it as a database query accelerator with boost buttons. As in The Fast and the Furious, when you want to pull ahead of the competition, you hit the NO2 and get the speed you need, right when you need it. And of course, this efficiency means it’s a little less expensive to run those big queries. One of the incredible things about Oracle MySQL HeatWave is the ability to [run analytics](https://www.oracle.com/mysql/heatwave/) directly against your existing transactional data, so there's no need to shuffle that data off to a separate system when you need to perform massively parallel analysis.  

To get started, we'll create a compartment and install MySQL Shell due to its extended capabilities over vanilla MySQL and create a small database so we can eventually connect it to HeatWave for analysis. Note that this is working within Oracle Cloud, but we’ll cover AWS setup in another tutorial to show you how you can leverage HeatWave in a multi-cloud scenario. What a time to be alive!  

Let's look at how to get started. If you're already developing in Oracle Cloud (OCI), you'll find it's relatively easy to get going, as HeatWave on AWS is integrated with OCI's Identity and Access Management system. When you sign up for HeatWave on AWS, you'll be directed to the OCI login page where you must sign in with an OCI Cloud Account. After signing in, you'll be directed to the OCI Console to complete the MySQL HeatWave on AWS sign-up process. When signing into the HeatWave Console, you are directed to OCI for authentication and then back to the HeatWave Console. To keep things simple, billing is still managed and monitored in OCI.  

Since we're just getting started, let's begin truly at the beginning and create a compute instance with the proper access rules and see how to create a HeatWave cluster in OCI. If you're already using AWS, we'll cover that in a separate tutorial.

## PREREQUISITES

- An OCI account and Oracle Cloud Account name
- Admin access
- A compatible browser (Chrome 69+, Safari 12.1+, or Firefox 62+ or any browser that is Oracle Jet-approved)

## OVERVIEW

MySQL HeatWave on AWS uses predefined Oracle Identity Cloud Service (IDCS) groups and policies to control user access to MySQL HeatWave on AWS and the type of access. You should have the ability to create and modify policies, users, and the like. Also, we are assuming you're creating the database and administering it, or at least getting the prep work done. Look at you, a one-stop shop!  

1. Create a Compartment
2. Create a a VCN and configure for database access
3. Create users and groups (if you haven't already)
4. Create a Bastion Host compute instance
5. Connect and Install MySQL Shell
6. Create a MySQL database
7. Create a DB System with HeatWave-compatible shape
8. Activate HeatWave on AWS

Wondering why this is a "bastion host"? You can read more about bastions in this [article](https://www.oracle.com/security/cloud-security/bastion/).  

>**NOTE**: Once you’re connecting databases and analytics, there’s a better production method for connecting, and that’s creating a Private Access Channel (OAC), which you can learn all about in the article, [How to create OAC instances on OCI Native using multiple stripes or instances of IDCS](https://blogs.oracle.com/analytics/post/how-to-create-oac-instances-on-oci-native-using-multiple-stripes-or-instances-of-idcs)
{:.notice}

In our example, we’re using a quick and dirty approach to set things up to use HeatWave.  

Now let’s get started with the basics! We begin by slicing off a piece of the cloud as our own little homestead. There are a couple of ways to do this, but one of the simplest is to create a Compartment (you could also start with a Compute instance). This is a “place for your stuff” within your tenancy and is quite flexible. As you might imagine, we need to create a group of users who can administer our system, and Identity and Access Management (IAM) is where you’ll go to configure this for any compartments you create.

## Create a Compartment

{% imgx assets/create-compartment-hwaws-devrel0266va.png %}

**Menu:** Home > Identity & Security > Compartments  

I could have set all of this up in my root compartment, but a new compartment is better way to organize things.  

Creating compartments is a simple matter, and a necessary starting point to organize and configure your work. I've named mine something clever, like *my_heatwave_testing* so I know what it's for.

## Create a VCN and configure for database access

**Menu:** Home > Networking > Virtual Cloud Networks  

1. Create VCN and subnets using **Virtual Cloud Networks > Start VCN Wizard > Create a VCN with Internet Connectivit**y.

   {% imgx assets/start_a_vcn_wizard-devrel0622va.png %}

   The handy wizard will walk you through creating a network interface for your system, although there are lots of ways to configure this, let’s not get distracted. Notice that I chose the compartment I set up earlier, my_heatwave_testing -- because that's important!

   {% imgx assets/vcn_config_screen2-devrel0622va.png %}

1. Now let's configure the VCN's security list to allow traffic through MySQL Database Service ports.  
   Click on the **Private Subnet** for the VCN you created, then click the **Security List** for it.

   {% imgx assets/vcn_edit_subnet_s1-devrel0622va.png %}

1. Now click **Add Security** list.  

   1. We'll add some ingress rules needed to enable the right ports, `3306` and `33060`.  
      Here's the details:

         ```console
         Source CIDR: 0.0.0.0/0

         Destination Port Range: 3306,33060

         Description: MySQL Port
         ```

   2. And click **Add Ingress Rules**.

      {% imgx assets/vcn_ingress_rules_example-devrel0622va.png %}

      Looking good so far!

## Create users and groups (if you haven't already)

We’ll need to set permissions and limit access somewhat, even in our “quick and dirty” example, but you can [read all about managing groups here](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managinggroups.htm). Usually we'll create a group, create policies, then add users to the group.  

Let’s make friends with the **Identity and Security** options.  

1. Create a group for your users.  
   In my example I’ve created a group called database_user (just to be confusing, as I should have named it database_admins, but this was just a clever ploy to keep you on your toes).  

2. Add users to the group.  
   In our example, we’ll add ourselves to this group that will administer our compute instance running MySQL-shell.  

   Of course, for a group you’ll first create all the users you need, add those into the group needing access at the levels you determine, and rest assured that you can set them loose with appropriate access controls.  

3. We allow access by setting policies, allowing one group to have full access (admins), and a group with limited access (database users, for example).  

   For MySQL HeatWave on AWS, there are some specific policy statements we can use, detailed in the charts below.  

   {% imgx assets/hw_policy_aws_statements-devrel0622va.png %}

   This is just making it possible to configure and administrate our compartment, and defines the scope of the access applied to the database instance.  


For more on adding users and setting policies in OCI, refer to [this documentation](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/addingusers.htm#Add).

## Create a Bastion Host Compute Instance

**MENU:** Main > Compute > Instances  

Be sure to select the compartment you set up earlier, under **List Scope**.  

{% imgx assets/compute_hw_listscope_compartment-devrel0622va.png %}

{% imgx assets/create_instance_hw_devrel_0522-0622va.png %}

### Create Instance

Click **Create Instance** (easy, right?)  

Name it something useful, and right now we'll leave the Availability Domain, Fault Domain, Image, and Shape as-is. You can use a free-tier compute!  

We’re going to use Oracle Linux, but one of the niceties here are the choices of compute shapes and Linux distributions to choose from. There’s even a developer distro, which comes pre-configured with key frameworks. For our purposes, we’ll want to make sure it’s set up to work with HeatWave. Plus, we'll use a Bastion Host for better security. Bastions provide "restricted and time-limited access to target resources that don't have public endpoints," and you can [read all about them in this overview article](https://docs.oracle.com/en-us/iaas/Content/Bastion/Concepts/bastionoverview.htm).  

{% imgx assets/create_compute_hw_devrel0522aa.png %}

#### Launching a Linux instance

If you want to know more, [here's a tutorial on launching a Linux instance](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/launchinginstance.htm), but I'll walk you through the basics now. Bear in mind that our compute instance can be pretty minimal, and there are free tier shapes that could work ([our always-free tier VM](https://www.oracle.com/cloud/free/) is quite generous).  

{% imgx assets/compute_network_hw_devrel0522aa.png %}

### Networking

Scrolling down, you'll see the **Networking** section. Here you'll want to make sure to use the [VCN you created previously](#create-a-vcn-and-configure-for-database-access), as well as make sure you're in the proper compartment.  

### Generate SSH keys

And of course, during this process you’ll generate SSH keys so you can access your computer instance remotely. You can do this within the Cloud Shell in OCI’s dashboard, or the SSH client of your choice.  

#### Let Oracle make it easy

Also, the path of least resistance for creating a key pair will be letting Oracle generate one. The key pair will allow you to log in remotely and install MySQL-shell, etc.  

>**NOTE:** In many labs we’ll have you use the Cloud Shell, which is a convenient command line interface available directly in the OCI dashboard. I’m old school, so I’m just using Terminal on my Mac. You can use the SSH client of your choice, of course!
{:.notice}

For more information see:  

- [Install Node Express on an Oracle Linux Instance](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/node-on-ol/01oci-ol-node-summary.htm#install-node-ol)
- [A video on working with SSH keys](https://www.youtube.com/watch?v=LMvYOSkXF1k).

### Obtain public IP for compute instance

Of course, you'll need the public IP for your compute instance, which is found in **Compute > Instances > Instance details**. Under **Instance Access** you'll find the public IP and username (opc) you'll need to connect, with a handy **copy** button.  

{% imgx assets/heres-public-ip-hw-oci-fy23-devrel.png %}

Now, we'll be able to [connect via SSH or the Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/accessinginstance.htm), and since you have a public IP, you can just ssh in to your compartment and the OCI Linux compute instance.  

As always, keep the private key in a safe place and `chmod 400` the private key to keep it from being modified (and throwing a warning).  

### Provision the Instance

Go ahead and click **Create**.  

It'll take a moment for the provisioning to finish up, but when it's done the large square icon will turn green, meaning all systems are GO!

## Connect and install MySQL Shell

To connect, let's use the handy Cloud Shell. It's a little Linux terminal embedded in the OCI dashboard (and it's adorable).  

1. In the upper-right corner, click the **Cloud Shell** prompt icon and a command line will open at the bottom of the browser.  

   {% imgx assets/cloudshelliconhwtesting-devrel0622va.png %}

1. Drag and drop the previously saved private key into the cloud shell, uploading it to your home directory.  

   {% imgx assets/cloudshelluploadprivkey_hwdevrel-devrel0622va.png %}

1. Under Instance Access, you'll see the public IP address, and the handy **Copy** button. Copy the public IP.  

1. Now let's ssh in, first protecting the private key file.  

      ```console
      chmod 400 <private-key-filename>.key
      ```

1. Then use your public IP address and username opc:  

      ```console
      ssh -i <private-key-file-name>.key opc@<compute_instance_public_ip>
      ```

1. If asked to accept the fingerprint, type *yes* and hit **enter**.  
   You've been added to the list of known hosts, congrats. We're in! If you see Tron, wave.  

1. Now we install MySQL Shell; pretty easy these days. In my case, I used SSH to log into my compute instance (don’t forget you’ll need your private key) and used yum to install what I needed.  

   Install the MySQL Client on the compute instance using the following command:  
   `sudo yum install mysql-shell`  

1. Once we create our HeatWave-compatible DB System, we'll connect to to it using the MySQL Client:  
   `mysqlsh --host <DBSystemEndpointIPAddress> -u <Username> -p`  

For more information see:  

- [Learning about MySQL Shell](https://dev.mysql.com/doc/mysql-shell/8.0/en/).

- [Learning about connecting database systems](https://docs.oracle.com/en-us/iaas/mysql-database/doc/connecting-db-system.html#GUID-70023ABD-5418-4C1F-975F-F3E2ABC0F93E).

## Create a DB System

Remember a little while ago when we mentioned the endpoint for your DB System? Let's set that up now.  

**MENU:** Menu > Databases > DB Systems  

{% imgx assets/createdbsys_warn_devrel_0522va.png %}

>**NOTE:** Notice that the system warns you if you haven't already set up users, a VCN, and so on. That's nice.  
>Also, don't forget to check which compartment you'll create this in, again under **List Scope** on the left.
{:.notice}

1. Click **Create DB System**.  

   Double-check the compartment, give it a name, and select HeatWave (of course).

1. You'll create admin credentials.  
   Be sure to save those somewhere handy but safe!

1. In **Configure Networking**, you'll use the compute instance created earlier, but we'll use the private subnet. Leave the default domain.
1. Go to **Configure Hardware**.  

   Confirm that in the **Configure Hardware** section, the selected shape is `MySQL.HeatWave.VM.Standard.E3`.  

   Also, confirm that:  

   - CPU Core Count: 16,
   - Memory Size: 512 GB,
   - Data Storage Size: 1024

1. In the **Configure Backup** section you may leave the default backup window of 7 days.  

1. Keep scrolling and click **Show Advanced Options**.  

   1. Go to the **Networking** tab.  
      In the **Hostname** field, enter the exact name of your DB System.  

   1. Make sure port configuration corresponds to the following:  

      - MySQL Port: 3306
      - MySQL X Protocol Port: 33060

1. And... click **Create**!  

   This time a yellow hexagon will appear, and eventually it'll turn green and your DB System will be up and running. Make some tea or grab some water, you've done a lot.

## Create a MySQL database

Now, you'll want to create your database and import any data you need. HeatWave is really designed for big data sets needing fast analysis, so even though I’m importing the tiniest database ever, you can load up as much as you like (provided you have the storage for it). Plus, queries can be run in the cluster without offloading to a separate database. Whether you're deploying to OCI or AWS, we got you.  

Finally, the fun part! Import a .sql file.

### From the command line

Type: `mysql -u username -p database_name < file.sql`  

Where:  

- `username` refers to your MySQL username.
- `database_name` refers to the database you want to import.
- `file.sql` is your file name.
- If you've assigned a password, type it now and press **Enter**.

For more information:  

- [Here's a video on importing using the command line](https://www.youtube.com/watch?v=gvcBDA2wJJ4).  

### Using mysqldump

Lots of fans of mysqldump out there, so here’s how that works (using a made-up database for magazines):  

1. To import a .sql file with mysqldump, use the `mysqlimport` command with the following flags and syntax:
`$ mysqlimport -u magazine_admin -p magazines_production ~/backup/database/magazines.sql`
   - `-u` and `-p` are needed for authentication, and is then followed by the name of the database you want to import into.
   - You'll need to specify the path to your SQL dump file that will contain your import data: `~/backup/database/magazines.sql`
   - You won't need to use `>` or `<` for importing, but you will need them for exporting in the next guide.
   - This will prompt a password request.
1. Your file will be automatically imported.

Now that we have some data, we probably want to DO stuff with it, including visualize it in various ways. Let's add some analytics to accomplish this -- and continue our journey to the really big show, HeatWave. This is where things get really interesting, and you can see how Oracle has created a vast menu of options for your data needs.  

The key is that you have a database running on OCI, and that database now has an endpoint which we can connect to HeatWave for analytics.

## Activate HeatWave on AWS

Remember the DB System we just created? Now we can activate MySQL HeatWave in AWS and connect our DB System to a HeatWave Cluster to run queries on!  

1. You'll go to <http://cloud.mysql.com/>, where you'll see the welcome page.  
   Enter your Oracle Cloud Account name and click **Continue**.  

1. Click **Enable MySQL HeatWave on AWS**.  
   This takes you to a Admin page where you will go through a brief setup process. You may have to upgrade your account to paid with a credit card, and once complete, you'll go to the OCI Console. Try not to time this for the last minute, as provisioning may take a moment.  

1. From the OCI Console navigation menu, select **Databases**.  

   MySQL HeatWave on AWS appears on the Home tab under the Featured label.  

1. Under **MySQL HeatWave on AWS**, click **Administration**, and you'll go back to the setup.  

1. Now click **Provision** to (of course) provision MySQL on AWS. 
   After the provisioning operation is completed, a message appears stating that MySQL HeatWave on AWS is ready and you are presented with options to open the MySQL HeatWave console, set up users, and view billing information.

## Summary - so far

What we've done so far, all on OCI, is set up a Virtual Cloud Network with ports for MySQL use, created a Bastion Compute instance, then set up a MySQL database, and now we have an endpoint for our HeatWave on AWS instance, and HeatWave should be provisioned on AWS.  

Want to know more? Join the discussion in our [public Slack channel](https://bit.ly/devrel_slack)!
