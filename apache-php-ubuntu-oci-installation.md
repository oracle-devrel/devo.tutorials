---
title: Get Started with Apache and PHP on Ubuntu and OCI
parent: tutorials
tags:
- always-free
- get-started
- open-source
- apache
- php
- ubuntu
- nodejs
- front-end
thumbnail: assets/apache-php-ubuntu-Apache_Diagram.png
date: 2021-10-21 01:00
description: Using Free Tier OCI to install PHP and Apache on an Ubuntu Linux instance,
  then connecting the instance to the internet for further development.
author:
  twitter: lefred
  github: lefred
  linkedin: lefred
redirect_from: "/collections/tutorials/apache-php-ubuntu-oci-installation/"
---
{% slides %}

In this tutorial, you use an Oracle Cloud Infrastructure (OCI) Free Tier account to set up a compute instance on the latest version of Ubuntu. Then, you will install an Apache web server and PHP and access your new server from the internet. Finally, this tutorial covers all the steps necessary to set up a virtual network for your host and connect the host to the internet.

Key tasks include how to:

* Set up a compartment for your development work.
* Install your Ubuntu instance and connect it to your Virtual Cloud Network (VCN).
    * Set up an Oracle Cloud Infrastructure virtual cloud network and related network services required for your host to connect to the internet.
    * Set up `ssh` encryption keys to access your Ubuntu server.
* Configure ingress rules for your VCN.
* Configure Apache and PHP 7 on your instance.
* Connect to your instance from the internet.

Here is a simplified diagram of the setup for your Linux VM.

![] ![]({% imgx aligncenter assets/apache-php-ubuntu-Apache_Diagram.png 1200 578 "" "Within OCI is the Compute VM, connected to the VCN, connected to the Internet" %})

For additional information, see:

* [Start for Free]({{ site.urls.always_free }})
* [Launch your first Linux VM](https://docs.oracle.com/iaas/Content/GSG/Reference/overviewworkflow.htm)
* [Create a VCN](https://docs.oracle.com/iaas/Content/GSG/Tasks/creatingnetwork.htm)

## Requirements

To successfully complete this tutorial, you must have the following:

* An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.

## 1. Set up a Compartment for Development

First, you will configure a compartment for your development.

### Create a Compartment

Create a compartment for the resources that you create in this tutorial.

1. Log in to the Oracle Cloud Infrastructure **Console**.
2. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Compartments**.
3. Click **Create Compartment**.
4. Fill in the following information:
    * **Name:** `<your-compartment-name>`
    * **Description:** `Compartment for <your-description>.`
    * **Parent Compartment:** `<your-tenancy>(root)`
5. Click **Create Compartment**.

**Reference: Create a compartment**

## 2. Install your Ubuntu Linux Instance

Use the **Create a VM Instance** wizard to create a new compute instance.

The wizard does several things when installing the instance:

* Creates and installs a compute instance running Ubuntu Linux.
* Creates a VCN with the required subnet and components needed to connect your Ubuntu Linux instance to the internet.
* Creates an `ssh` key pair you use to connect to your instance.

### Review Installation Steps

To get started installing your instance with the **Create a VM Instance** wizard, follow these steps:

1. From the main landing page, select **Create a VM Instance** wizard. ![]({% imgx aligncenter assets/apache-php-ubuntu-01action-menu.png 1200 423 "" "Quick Actions in the VM Instance Wizard, choose Create a VM Instance" %}) 

    The **Create Compute Instance** page is displayed. It has a section for **Placement**, Image and shape, **Networking**, **Add SSH keys**, and **Boot volume**.

2. Choose the **Name** and **Compartment**.

    **Initial Options**

    * **Name:** `<name-for-the-instance>`
    * **Create in compartment:** `<your-compartment>`

    Enter a value for the name or leave the system supplied default.

3. Review the **Placement** settings, and click the **Show advanced options** link.

    Take the default values. Your data might look similar to the following:

    **Availability domain**

    * **Availability domain:** AD-1
    * **Capacity type:** On-demand capacity
    * **Fault domain:** Let Oracle choose the best fault domain 

    > Note: For Free Tier, use **Always Free Eligible** option for availability domain.
    {:.notice}

4. Review the Image and shape settings. 

    1. Select the latest Ubuntu image.

        1. Click Change Image.
        2. Select the latest Ubuntu image.
        3. Click Select Image. Your image is displayed, for example your data looks similar to the following: 

        **Image**

        * **Image:** Canonical Ubuntu 20.04
        * **Image build:** 2020.12.11-0

    2. Take the default values for **Shape**.

    For example, your data looks similar to the following:

    **Shape**

    * **Shape:** VM.Standard.E2.1.Micro
    * **OCPU count:** 1
    * **Memory (GB):** 1
    * **Network bandwidth (Gbps):** 0.48

    > Note: For Free Tier, use **Always Free Eligible** shape options.
    {:.notice}

5. Review the **Networking** settings. Take the default values provided by the wizard.

    > **Note:** The following is sample data. The actual values change over time or differ in a different data center.
    >* **Virtual cloud network:** vcn-<date>-<time>
    >* **Subnet:** vcn-<date>-<time>
    >* **Assign a public IPv4 address:** Yes
    {:.notice}

6. Review the **Add SSH keys** settings. Take the default values provided by the wizard.

    * Select the Generate a key pair for me option.
    * Click Save Private Key and Save Public Key to save the private and public SSH keys for this compute instance.

    If you want to use your own SSH keys, select one of the options to provide your public key.

    > **Note:** Put your private and public key files in a safe location. You cannot retrieve keys again after the compute instance has been created.
    {:.notice}

7. Review the **Boot volume** settings. Take the default values provided by the wizard.

    Leave all check boxes **unchecked**.

8. Click **Create** to create the instance. Provisioning the system might take several minutes.

    You have successfully created an Ubuntu Linux instance to run your Apache Web Server.

## 3. Enable Internet Access

The **Create a VM Instance** wizard automatically creates a VCN for your VM. You add an ingress rule to your subnet to allow internet connections on port 80.

### Create an Ingress Rule for your VCN


Follow these steps to select your VCN's public subnet and add the ingress rule.

1. Open the navigation menu and click **Networking**, and then click **Virtual Cloud Networks**.
2. Select the VCN you created with your compute instance.
3. With your new VCN displayed, click **`<your-subnet-name>`** subnet link.

    The public subnet information is displayed with the Security Lists at the bottom of the page. A link to the **Default Security List** for your VCN is displayed.

4. Click the **Default Security List** link.

    The default **Ingress Rules** for your VCN are displayed.

5. Click **Add Ingress Rules**.

    An **Add Ingress Rules** dialog is displayed.

6. Fill in the ingress rule with the following information.

    Fill in the ingress rule as follows:

    * **Stateless:** Checked
    * **Source Type:** CIDR
    * **Source CIDR:** 0.0.0.0/0
    * **IP Protocol:** TCP
    * **Source port range:** (leave-blank)
    * **Destination Port Range:** 80
    * **Description:** Allow HTTP connections

    Click **Add Ingress Rule**. Now HTTP connections are allowed. Your VCN is configured for Apache server.

7. Click **Add Ingress Rule**.

    Now HTTP connections are allowed. Your VCN is configured for Apache server.

    You have successfully created an ingress rule that makes your instance available from the internet.

## 4. Set up Apache and PHP

Next install and configure Apache web server and PHP to run on your Ubuntu Linux instance.

### Install and Configure Apache and PHP

To install and set up Apache and PHP, perform the following steps:

1. Open the navigation menu and click **Compute**. Under **Compute**, click **Instances**.
2. Click the link to the instance you created in the previous step. 

    From the **Instance Details** page look under the **Instance Access** section, the **Public IP Address** field. Write down the public IP address the system created for you. You use this IP address to connect to your instance.

3. Open a **Terminal** or **Command Prompt** window.
4. Change into the directory where you stored the `ssh` encryption keys you created before.
5. Connect to your instance with this SSH command.

    ```console
    ssh -i <your-private-key-file> ubuntu@<x.x.x.x>
    ```

    Since you identified your public key when you created the instance, this command logs you into your instance. You can now issue `sudo` commands to install and start your server.

6. Install Apache Server.

    ```console
    sudo apt update
    sudo apt -y install apache2
    ```

7. Next start Apache.

    ```console
    sudo systemctl restart apache2
    ```

8. Update firewall settings.

    The Ubuntu firewall is disabled by default. However, you still need to update your `iptables`configuration to allow HTTP traffic. Update `iptables` with the following commands.

    ```console
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
    sudo netfilter-persistent save
    ```

    The commands add a rule to allow HTTP traffic and saves the changes to the `iptables`configuration files.

9. You can now test your server.

    You can test your server from the command line with `curl localhost`. Or, you can connect your browser to your public IP address assigned to your instance: **http://`<x.x.x.x>`**. The page looks similar to: ![]({% imgx aligncenter assets/apache-php-ubuntu-06apache-ubun.png 1200 444 "" "Default Apache2 Ubuntu welcome page" %})

10. Install PHP 7 with the following commands.

    ```console
    sudo apt -y install php libapache2-mod-php
    ```

11. Verify installation and restart Apache.

    ```console
    $ php -v
    $ sudo systemctl restart apache2
    ```

12. Add a PHP test file to your instance.

    Create the file:

    ```console
    sudo vi /var/www/html/info.php
    ```

13. In the file, input the following text and save the file:

    ```console
    <?php
    phpinfo();
    ?>
    ```

14. Connect to **http://`<your-public-ip-address>/`info.php**.

    The browser produces a listing of PHP configuration on your instance similar to the following. 

    ![]({% imgx aligncenter assets/apache-php-ubuntu-07php.png 1200 942 "" "PHP configuration information screen" %})

    > **Note:** After you are done testing, remove **info.php** from your system.
    {:.notice}

    Congratulations! You have successfully installed Apache and PHP 7 on your Oracle Cloud Infrastructure instance.

## What's Next

You have successfully installed and deployed an Apache web server and PHP on Oracle Cloud Infrastructure using a Linux instance.

To explore more information about development with Oracle products, check out these sites:

  * [Oracle Developers Portal](https://developer.oracle.com/)
  * [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

{% endslides %}
