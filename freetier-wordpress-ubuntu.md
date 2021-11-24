---
title: "Free Tier: Install WordPress on an Ubuntu Instance"
parent: [tutorials]
toc: true
tags: [ubuntu, backend]
categories: [modernize]
thumbnail: assets/modernize-healthcare-ambulance.jpeg
date: 2021-11-24 9:45
description: This tutorial guides you through configuring WordPress on your Ubuntu OCI instance.
author: 
    name: Docs @ Oracle
draft: true
---
{% slides %}
In this tutorial, use an Oracle Cloud Infrastructure Free Tier account to set up an Ubuntu instance. Next, install an Apache web server, PHP 7, MySQL, and finally WordPress. After installation, access your new WordPress installation from the internet. This tutorial covers all the steps necessary to set up a virtual network, a compute instance, and connect the host to the internet. Key tasks include how to:

* Set up a compartment for your development work.
* Install your Ubuntu Linux instance and connect it to your Virtual Cloud Network (VCN).
    * Set up an Oracle Cloud Infrastructure virtual cloud network and related network services required for your host to connect to the internet.
    * Set up `ssh` encryption keys to access your Ubuntu Linux Server.
* Configure ingress rules for your VCN.
* Configure Apache, PHP 7, MySQL, and WordPress on your VM.
* Connect to your instance from the internet.

Here's a simplified diagram of the setup for your Linux VM.

{% imgx assets/wordpress-apache-diagram.png "OCI Apache network diagram" %}

For additional information, see:

* [Start for Free](https://www.oracle.com/cloud/free/)
* [Free Tier: Install Apache and PHP on an Ubuntu Instance](https://docs.oracle.com/iaas/developer-tutorials/tutorials/apache-on-ubuntu/01oci-ubuntu-apache-summary.htm)

## Before you Begin

To successfully complete this tutorial, you must have the following:

### Requirements

* An Oracle Cloud Infrastructure Free Tier account. [Start for Free](https://www.oracle.com/cloud/free/).
* A MacOS, Linux, or Windows computer with `ssh` support installed.

## 1. Set up a Compartment for Development

Configure a compartment for your development.

### Create a compartment

Create a compartment for the resources that you create in this tutorial.

*  Log in to the Oracle Cloud Infrastructure Console.
* Open the navigation menu and click Identity & Security. Under Identity, click Compartments.
* Click Create Compartment.
* Fill in the following information:
    * Name: <your-compartment-name>
    * Description: Compartment for <your-description>.
    * Parent Compartment: <your-tenancy>(root)        
* Click Create Compartment.

Reference: [Create a compartment](https://docs.oracle.com/iaas/Content/Identity/Tasks/managingcompartments.htm#To)

## 2. Install your Ubuntu Linux Instance

Use the Create a VM Instance wizard to create a new compute instance.

The wizard does several things when installing the instance:

* Creates and installs a compute instance running Ubuntu Linux.
* Creates a VCN with the required subnet and components needed to connect your Ubuntu Linux instance to the internet.
* Creates an `ssh` key pair you use to connect to your instance

### Review Installation Steps

To get started installing your instance with the Create a VM Instance wizard, follow these steps:

1. From the main landing page, select Create a VM Instance wizard. 

{% imgx assets/wordpress-apache-quickactions.png "Screenshot of the Create VM Instance wizard" %}

The Create Compute Instance page is displayed. It has a section for Placement, Image and shape, Networking, Add SSH keys, and Boot volume.
2. Choose the Name and Compartment.
    Initial Options: 
    * Name: <name-for-the-instance>
    * Create in compartment: <your-compartment-name>
    Enter a value for the name or leave the system supplied default.
3. Review the Placement settings, and click the Show advanced options link.
    Take the default values. Your data might look similar to the following:

    Availability domain:

    * Availability domain: AD-1
    * Capacity type: On-demand capacity
    * Fault domain: Let Oracle choose the best fault domain

    For Free Tier, use Always Free Eligible option for availability domain.

4. Review the Image and shape settings.
    * Select the latest Ubuntu image.
        * Click Change Image.
        * Select the latest Ubuntu image.
        * Click Select Image. Your image is displayed, for example your data looks similar to the following: 
            * Image: Canonical Ubuntu 20.04
            * Image build: 2020.12.11-0
        * Take the default values for Shape. For example, your data looks similar to the following:
            * Shape: VM.Standard.E2.1.Micro
            * OCPU count: 1
            * Memory (GB): 1
            * Network bandwidth (Gbps): 0.48
        For Free Tier, use Always Free Eligible shape options.

5. Review the Networking settings. Take the default values provided by the wizard.

    The following is sample data. The actual values change over time or differ in a different data center.

    * Virtual cloud network: vcn-<date>-<time>
    * Subnet: vcn-<date>-<time>
    * Assign a public IPv4 address: Yes

6. Review the Add SSH keys settings. Take the default values provided by the wizard.
    * Select the Generate a key pair for me option.
    * Click Save Private Key and Save Public Key to save the private and public SSH keys for this compute instance.

    If you want to use your own SSH keys, select one of the options to provide your public key.

    Put your private and public key files in a safe location. You cannot retrieve keys again after the compute instance has been created.

7. Review the Configure boot volume settings. Take the default values provided by the wizard. Leave all check boxes unchecked.

8. Click Create to create the instance. Provisioning the system might take several minutes.

    You have successfully created an Ubuntu Linux instance.

## 3. Enable Internet Access

The Create a VM Instance wizard automatically creates a VCN for your VM. You add an ingress rule to your subnet to allow internet connections on port 80.

### Create an Ingress Rule for your VCN

Follow these steps to select your VCN's public subnet and add the ingress rule.

1.  Open the navigation menu and click Networking, and then click Virtual Cloud Networks. 
2.  Select the VCN you created with your compute instance. 
3.  With your new VCN displayed, click <your-subnet-name> subnet link.
    The public subnet information is displayed with the Security Lists at the bottom of the page. A link to the Default Security List for your VCN is displayed.
4.  Click the Default Security List link.
     The default Ingress Rules for your VCN are displayed.
5.  Click Add Ingress Rules.
     An Add Ingress Rules dialog is displayed.
6.  Fill in the ingress rule with the following information.
    * Stateless: Checked
    * Source Type: CIDR
    * Source CIDR: 0.0.0.0/0
    * IP Protocol: TCP
    * Source port range: (leave-blank)
    * Destination Port Range: 80
    * Description: Allow HTTP connections

     Click Add Ingress Rule. Now HTTP connections are allowed. Your VCN is configured for Apache server.

7.  Click Add Ingress Rule. Now HTTP connections are allowed. Your VCN is configured for Apache server.
     You have successfully created an ingress rule that makes your instance available from the internet.

## 4. Install and Configure Apache, PHP 7, MySQL, and WordPress

Next install and configure Apache web server and PHP to run on your Ubuntu Linux instance.

### Configure the Ubuntu Firewall

Connect to your Ubuntu instance and configure your firewall settings. Follow these steps:

1. Log into your free tier account.
2. Open the navigation menu and click Compute. Under Compute, click Instances.
3. Click the link to the instance you created in the previous step.
    From the Instance Access section, write down the Public IP Address the system created for you. You use this IP address to connect to your instance.
4. Open a Terminal window.
5. Change into the directory where you stored the ssh encryption keys you created in part one.
6. Connect to your VM with this SSH command. 

    ```console
    ssh -i <your-private-key-file> ubuntu@<your-public-ip-address>
    ```

    Since you identified your public key when you created the VM, this command logs you into your VM. You can now issue `sudo` commands to install and start your server.
7. Update firewall settings.
    Next, update your iptables configuration to allow HTTP traffic. To update iptables, run the following commands.

    ```console
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
    ```

    ```console
    sudo netfilter-persistent save
    ```

The commands add a rule to allow HTTP traffic and saves the changes to the iptables configuration files.

### Install Apache Server

1. Install Apache Server. 

    ```console
    sudo apt update
    ```

    ```console
    sudo apt -y install apache2
    ```

2. Next, start Apache.

    ```console
    sudo systemctl restart apache2
    ```

3. You can now test your server.

    You can test your server from the command line with curl localhost. Or, you can connect your browser to the public IP address assigned to your VM: 
    
    `http://<your-public-ip-address>`. The page looks similar to: 

    {% imgx assets/wordpress-apache-ubuntu-default.png "Apache 2 Ubuntu default page" %}

### Install PHP

1. Install PHP and then some helpful modules with the following commands. 

    ```console
    sudo apt -y install php
    ```

    ```console
    sudo apt -y install php-mysql php-curl php-gd php-zip
    ```

2. Verify installation and restart Apache. 

    ```console
    php -v
    ```

    ```console
    sudo systemctl restart apache2
    ```

3. Add a PHP test file to your VM. 

    ```console
    sudo vi /var/www/html/info.php
    ```

4. In the file, input the following text and save the file: 

    ```php
    <?php
    phpinfo();
    ?>
    ```

5. Connect to `http://<your-public-ip-address>/info.php`. 

    The browser produces a listing of PHP configuration on your VM. 

    {% imgx assets/wordpress-apache-php-ubuntu-details.png "A table listing the PHP configuration on your VM" %}
    
    You have successfully installed Apache and PHP 7 on your Oracle Cloud Infrastructure instance.

    After you are done testing, delete the `info.php` file.

### Configure your Apache HTML Directory

Set up your Apache server to read and write from the `/var/www/html` directory.

1. Add your username to the `www-data`group so you can edit the `/var/www/html` directory.

    ```console
    sudo adduser $USER www-data
    ```

2. Now change the ownership of the content directory. 

    ```console
    sudo chown -R www-data:www-data /var/www/html
    ```

3. Change permissions on the files and directory.     

    ```console
    sudo chmod -R g+rw /var/www/html
    ```

4. Reboot your machine for changes to take effect.

### Install and Configure MySQL Server and Client

Next, you install and configure the MySQL server and client so it can be used with WordPress.

1. Install the MySQL Server package. 

    ```console
    sudo apt -y install mysql-server
    ```

    This step can take some time.

2. Next, perform a secure configuration of MySQL. 

    ```console
    sudo mysql_secure_installation
    ```
    
    Produces this output:

    ```console
    Securing the MySQL server deployment.
                            
    Connecting to MySQL using a blank password.
    ```

3. Turn on Password Validation: 

    ```console
    VALIDATE PASSWORD COMPONENT can be used to test passwords
    and improve security. It checks the strength of password
    and allows the users to set only those passwords which are
    secure enough. Would you like to set up VALIDATE PASSWORD component?
    
    Press y|Y for Yes, any other key for No:    
    ```

4. Select `Y`.
5. Select the password validation level. 

    ```console
    There are three levels of password validation policy:

    LOW    Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file

    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:  
    ```

6.  Select a level.
7. Set the root password. 
        
    ```console
    Please set the password for root here.

    New password: 

    Re-enter new password: 

    Estimated strength of the password: 100 
    Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :
    ```

8. Select the remaining security options.

    ```console
    Remove anonymous users? (Press y|Y for Yes, any other key for No) : 
    Disallow root login remotely? (Press y|Y for Yes, any other key for No) : 
    Remove test database and access to it? (Press y|Y for Yes, any other key for No) : 
    Reload privilege tables now? (Press y|Y for Yes, any other key for No) : 
    Success.

    All done! 
    ```

9. Log in to MySQL. 

    ```console
    sudo mysql
    ```

    You are given a MySQL prompt.

10. List the default databases. 

    ```console
    mysql> show databases;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    | performance_schema |
    | sys                |
    +--------------------+
    4 rows in set (0.01 sec)
    ```

11. Create a user for MySQL. 

    ```console
    mysql> CREATE USER '<your-user-name>'@'localhost' IDENTIFIED BY '<your-password>';
    Query OK, 0 rows affected (0.01 sec)
    ```

12. Make the user an admin. 

    ```console
    mysql> GRANT ALL PRIVILEGES ON *.* TO '<your-user-name>'@'localhost';
    Query OK, 0 rows affected (0.01 sec)
    ```

13. Create your WordPress database. 

    ```console
    mysql> create database wpdb;
    Query OK, 1 row affected (0.01 sec)
    ```

14. Check the result. 

    ```console
    mysql>show databases;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    | performance_schema |
    | sys                |
    | wpdb               |
    +--------------------+
    5 rows in set (0.00 sec)
    ```

15. Flush privileges to clear cached memory. 

    ```console
    mysql> FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.00 sec)

    mysql> exit;
    Bye
    ```

### Install and Configure WordPress

Download and follow these steps to install WordPress on your server.

1. Open a terminal window and create a `tmp` directory.
2. Download the WordPress Linux zip from https://wordpress.org/download/ and unzip. 

    ```console
    wget <url-for-download>.gz
    ```

    ```console
    tar xvfz <download-file-name>.gz
    ```

    The command creates a `wordpress` directory with the PHP code for WordPress in it.

3. Copy the contents of the wordpress directory to the `/var/www/htm`l directory. 

    ```console
    cp -R /home/<your-username>/tmp/wordpress/* /var/www/html
    ```

    The contents of the `wordpress` directory are copied into the `/var/www/html` directory. This command is a sample. Your command differs depending on the name of your directories.

4. Change into to the `/var/www/html` directory. 

    ```console
    cd /var/www/html
    ```

5. Rename the default `index.html` file. 

    ```console
    mv index.html index.html.bk
    ```

    Now `index.php` is loaded by default when your root directory is accessed.

6. Rename the `wp-config-sample.php` file. 

    ```console
    mv wp-config-sample.php wp-config.php
    ```

7. Update the values for your MySQL set up. 
    
    ```console
    vi wp-config.php
    ```

8. Run the installation script by opening a browser and this URL: `http://<your-public-ip-address>/wp-admin/install.php`

    Create an administrator account for your WordPress blog. Ensure you write down the information from the install page. You need it to log into your WordPress blog.

9. Open your new blog at: `http://<your-public-ip-address>`

    Finish any other configuration you need for WordPress. Here is a link to help:

    * [First Steps with WordPress](https://wordpress.org/support/article/first-steps-with-wordpress/)

    You have set up a WordPress blog on an Oracle Cloud Infrastructure (OCI) compute instance.

## What's Next

You have successfully installed and deployed an Apache web server on Oracle Cloud Infrastructure using a Linux instance.

To explore more information about development with Oracle products, check out these sites:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
{% endslides %}
