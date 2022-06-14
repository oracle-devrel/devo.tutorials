---
title: Kubernetes - Deploy a Node Express Application
parent: tutorials
tags:
- OCI
- open-source
- nodejs
- front-end
- kubernetes
thumbnail: assets/deploy-a-node-express-application-Node-K8s-diagram.png
date: 2021-09-30 01:00
description: How to deploy a Node Express application to a Kubernetes cluster on OCI.
redirect_from: "/collections/tutorials/deploy-a-node-express-application/"
mrm: WWMK211117P00058
xredirect: https://developer.oracle.com/tutorials/deploy-a-node-express-application/
---
{% slides %}
In this tutorial, you'll use an Oracle Cloud Infrastructure (OCI) account to set up a Kubernetes cluster. Then, you'll deploy a Node Express application to your cluster.

Key tasks include how to:

* Set up a Kubernetes cluster on OCI.
* Set up OCI CLI to access your cluster.
* Build a Node Express application and Docker Image.
* Push your image to the Oracle Cloud Infrastructure Registry (OCIR).
* Deploy your Node.js Docker application to your cluster.
* Connect to your application from the internet.

  {%imgx assets/deploy-a-node-express-application-Node-K8s-diagram.png 1254 517 "Deploy a node express application to the internet." %}

For additional information, see:

* [Kubernetes Documentation]
* [OCI Container Engine for Kubernetes]
* [OCI Container Registry]
* [Getting started with OCI Cloud Shell]

## Prerequisites

To successfully perform this tutorial, you'll need to have the following:

### For Container Registry, Kubernetes, and Load Balancers

* A **paid** Oracle Cloud Infrastructure account.  
  See: [Signing Up for Oracle Cloud Infrastructure]

### For building applications and Docker images

* One of the following local environments:
  * A MacOS or Linux machine.
  * A Windows machine with Linux support.  
    For example:  
    * [Windows Subsystem for Linux]
    * [Oracle Virtual Box]
* You have access to root either directly or using sudo. By default in OCI, you are connected as an `opc` user with sudo privilege.
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* The following applications on your local environment:
  * JDK 11 and set JAVA_HOME in .bashrc.
  * Python 3.6.8+ and pip installer for Python 3
  * Kubernetes Client 1.11.9+
  * Apache Maven 3.0+
  * Docker 19.0.3+
  * Git 1.8+
  * Node.js 10+

> **Note:** If you don't want to set up the required applications in your local environment, you can use OCI **Cloud Shell** instead. The advantage of using Cloud Shell is that all the required tools to manage your application are already installed and ready to use.  
> If you'd like to go this route, follow the steps in the [Kubernetes Using Cloud Shell: Deploy a Spring Boot Application] guide.
>  
{:.notice}

### Get the Applications for Linux on OCI Free Tier

If you prefer your deployment without commitments or are just seeing if OCI is right for you, we've got you covered! You can use an *OCI Free Tier Linux compute instance* to manage your deployment. The following sections will tell you how to install all of the software required for this tutorial.

#### Install a Linux Instance

We'll start off by installing a Linux VM with an **Always Free** compute shape on Oracle Cloud Infrastructure. Below, we'll outline the steps for both an Oracle Linux and an Ubuntu VM.  

>**Note:** For this, you'll need a machine with `ssh` support to connect to your Linux instance.
{:.notice}

* To [install an Oracle Linux VM]
  * Follow sections 2 and 3.
    Section 2: if you have a paid account, choose your **compute options** based on your offerings.
  * Section 4: to connect to your instance, follow steps 1-5.
    **Skip the Apache instructions**.
* To [install an Ubuntu VM]
  * Follow sections 2 and 3.
  * Section 2: if you have a paid account, choose **compute options** based on your offerings.
  * Section 4: to connect to your instance, follow steps 1-5.
    * **Skip the Apache instructions.**
    * To update the firewall settings, in section 4, perform step 8.

## Install Node.js on your system

Let's start digging into the heart of this tutorial and get Node.js installed in your environment.  

To install Node.js and Node Package Manager (NPM), run the following commands on the appropriate system:

### Oracle Linux

1. Get and install any new versions of previously-installed packages:  

      ```console
      sudo yum update
      ```

1. Set up the Yum repo for Node.js.
1. Install the `nodejs` package:  

      ```console
      sudo yum install -y oracle-nodejs-release-el7
      sudo yum install -y nodejs
      ```

### Ubuntu

1. Get and install any new versions of previously-installed packages:  

      ```console
      sudo apt update
      ```

1. Install the `nodejs` and the `npm` packages:  

      ```console
      sudo apt install -y nodejs
      sudo apt install -y npm
      ```

1. Verify the installation:  

      ```console
      node -v
      npm -v
      ```

## Optional setups

### Configure the firewall

> **Note:** If you want to perform browser-based testing of your Node application, make **port 3000** available on your Linux instance.
{:.notice}

#### On Oracle Linux

```console
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload
```

#### On Ubuntu Linux

```console
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 3000 -j ACCEPT
sudo netfilter-persistent save
```

### Create an Ingress Rule for your VCN

Follow these steps to select your VCN's public subnet and add the ingress rule:  

1. Open the navigation menu and select **Networking**.
1. Select **Virtual Cloud Networks**.
1. Select the VCN you created with your compute instance.
1. With your new VCN displayed, select **`<your-subnet-name>`** subnet link.  
   You will see:  
   * The public subnet information displayed with the **Security Lists** at the bottom of the page.
   * A link to the **Default Security List** for your VCN.
1. Select the **Default Security List** link.

   The default **Ingress Rules** for your VCN are displayed.

1. Select **Add Ingress Rules**.

   An **Add Ingress Rules** dialog is displayed.

1. Fill in the ingress rule with the following information:

      ```console
      Stateless: Checked
      Source Type: CIDR
      Source CIDR: 0.0.0.0/0
      IP Protocol: TCP
      Source port range: (leave-blank)
      Destination Port Range: 3000
      Description: Allow HTTP connections
      ```

1. Select **Add Ingress Rule**.

At this point, HTTP connections are allowed and your VCN is configured for Node Express.

Congratulations! You've successfully created an ingress rule that makes your instance available from the internet.

## Install Python 3 and Pip 3

1. Verify your current installation:  

      ```console
      python3 --version
      ```

1. For Python 3, run the following commands:

    * Oracle Linux:  

        ```console
        sudo yum update

        sudo yum install -y python3
        ```

    * Ubuntu:  

        ```console
        sudo apt update

        sudo apt install -y python3
        ```

1. Verify the pip installation for Python3:  

      ```console
      pip3 -V
      ```

    Sample output if pip for Python3 is installed:  

      ```console
      pip <version> from xxx/lib/python3.x/site-packages/pip   (python 3.x)
      ```

1. To install Pip for Python 3, run the following commands:  

    * Oracle Linux:  

        ```console
        sudo yum update

        sudo yum install -y python3-pip
        ```

    * Ubuntu:  

        ```console
        sudo apt update

        sudo apt install -y python3-pip
        ```

1. Verify the pip for Python 3 installation:  

      ```console
      pip3 -V
      ```

## Install Kubernetes Client

1. Verify your current installation:  

      ```console
      kubectl version --client
      ```

    If you have Kubernetes, then the version is `<major-version>.<minor-version>`.  

    For example, if you have Kubernetes version 1.20, you'll get the following:  

    ```console
    version.Info{Major:"1", Minor:"20"...
    ```

1. To install he `kubectl` client, refer to the following links:  
   * [Install Kubernetes client on Linux]
   * [Install Kubernetes client on MacOS]
1. Verify the installation:  

      ```console
      kubectl version --client
      ```

## Install Docker

1. Verify your current installation:  

      ```console
      docker -v
      ```

    * Oracle Linux

        ```console
        sudo yum install docker-engine
           
        sudo systemctl start docker

        sudo systemctl enable docker
        ```

        > **Note:** The last command enables Docker to start on reboots.
        {:.notice}

    * Ubuntu Linux

      To install Docker on Ubuntu Linux, refer to the [Get Docker] guide.

1. Verify the installation:  

      ```console
      docker -v
      ```

## Prepare

We're finally here! It's time to prepare your environment to create and deploy your application.

### Check your Service Limits

1. Log in to the OCI **Console**.
2. Open the navigation menu and select **Governance and Administration**.
3. Under **Governance**, select **Limits, Quotas and Usage**.
4. Find your service limit for **Regions**

   1. **Filter** for the following options:  

      * **Service:** Regions
      * **Scope:** Tenancy
      * **Resource:** Subscribed region count
      * **Compartment:** `<tenancy-name>` (root)

   1. Find service limit:

      * **Limit Name:** `subscribed-region-count`
      * **Service Limit:** minimum 2
5. Find your available **Compute** **core count** for the **VM.Standard.E3.Flex** shape

   1. **Filter** for the following options:

      * **Service:** Compute
      * **Scope:** `<first-availability-domain>`. Example: `EMlr:US-ASHBURN-AD-1`
      * **Resource:** **Cores** for **Standard.E3.Flex** and BM.Standard.E3.128 Instances
      * **Compartment:** `<tenancy-name>` (root)

   1. Find available core count:

      * **Limit Name:** `standard-e3-core-ad-count`
      * **Available:** minimum 1

   1. Repeat for **Scope:** `<second-availability-domain>` and `<third-availability-domain>`. Each region must have at least one core available for this shape.  

      > **Note:** This tutorial creates three compute instances with a **VM.Standard.E3.Flex** shape for the cluster nodes. To use another shape, filter for its **core count**.  
      > For example, for **VM.Standard2.4**, filter for **Cores for Standard2 based VM and BM Instances** and get the **count**.
      {:.notice}
6. Find out if you have **50 GB** of **Block Volume** available:

   1. **Filter** for the following options:

      * **Service:** Block Volume
      * **Scope:** `<first-availability-domain>`. Example: `EMlr:US-ASHBURN-AD-1`
      * **Resource** Volume Size (GB)
      * **Compartment:** `<tenancy-name>` (root)

   1. Find available block volume storage:

      * **Limit Name:** `total-storage-gb`
      * **Available:** minimum 50

   1. Repeat for **Scope:** `<second-availability-domain>` and `<third-availability-domain>`. Each region must have at least 50 GB of block volume available.
7. Find out how many **Flexible Load Balancers** you have available

    **Filter** for the following options:

      * **Service:** LBaaS
      * **Scope:** `<your-region>`. Example: `us-ashburn-1`
      * **Resource:** `<blank>`
      * **Compartment:** `<tenancy-name>` (root)

    Find the number of available flexible load balancers:

      * **Limit Name:** `lb-flexible-count`
      * **Available:** minimum 1

    >**Note:** This tutorial creates a load balancer with a **flexible** shape. To use another bandwidth, filter for its **count**, for example **100-Mbps bandwidth** or **400-Mbps bandwidth**.
    {:.notice}

**Reference:** For a list of all shapes, see [VM Standard Shapes]

### Create an Authorization Token

1. In the Console's top navigation bar, select the **Profile** menu (your avatar).
2. Select your **username**.
3. Select **Auth Tokens**.
4. Select **Generate Token**.
5. Give the token a description.
6. Select **Generate Token**.
7. Copy the token and **save** it.
8. Select **Close**.

> **Note:** It's crucial that you've made sure to save your token right after you create it since you'll have *no access to it later*.
{:.warn}

### Gather Required Information

1. Collect the following credential information from the OCI **Console**:
    * **Tenancy name:** `<tenancy-name>`
        * Select your **Profile** menu (your avatar) and find your **Tenancy:`<tenancy-name>`**.
    * **Tenancy namespace:** `<tenancy-namespace>`
        * Select your **Profile** menu (your avatar).
        * Select **Tenancy:`<tenancy-name>`**.
        * Copy the value for **Object Storage Namespace**.

        > **Note:** For some accounts, **`tenancy name`** and **`namespace`** differ. Ensure that you use **`namespace`** in this tutorial.
        {:.notice}

    * **Tenancy OCID:** `<tenancy-ocid>`
        * Select your **Profile** menu (your avatar), then select **Tenancy:`<tenancy-name>`**, and copy `OCID`.
    * **Username:** `<user-name>`
        * Select your **Profile** menu (your avatar).
    * **User OCID:** `<user-ocid>`
        * Select your **Profile** menu (your avatar), then select **User Settings**, and copy `OCID`.

1. Find your region information.

    * **Region:** `<region-identifier>`
        * In the Console's top navigation bar, find your region.
          **Example:** **US East (Ashburn)**.
        * Find your **Region Identifier** from the table in [Regions and Availability Domains].
          **Example:** `us-ashburn-1`.
    * **Region Key:** `<region-key>`
        * Find your **Region Key** from the table in [Regions and Availability Domains].
          **Example:** `iad`

1. Copy your authentication token from the [Create an Authentication Token](#create-an-authorization-token) section.  

    **Auth Token:** `<auth-token>`

## Set up OCI Command Line Interface

### Install a Python Virtual Environment and Wrapper

The Python `virtualenv` creates a folder that contains all the executables and libraries for your project.

The `virtualenvwrapper` is an extension of `virtualenv`. It provides a set of commands which makes working with virtual environments much  easier. Not only that, it also conveniently places all of your virtual environments in one place. One particularly useful (and sanity-saving) feature is that `virtualenvwrapper` provides *tab-completion of environment names*.

1. Install `virtualenv`:

      ```console
      pip3 install --user virtualenv
      ```

2. Install `virtualenvwrapper`:

      ```console
      pip3 install --user virtualenvwrapper
      ```

3. Find the location of the `virtualenvwrapper.sh` script:

      ```console
      grep -R virtualenvwrapper.sh
      ```

    **Example paths:**

    * Linux example:  
      `/home/ubuntu/.local/bin/virtualenvwrapper.sh`
    * MacOS example:  
      `/usr/local/bin/virtualenvwrapper.sh`

4. Configure the virtual environment wrapper in `.bashrc`:

      ```console
      sudo vi .bashrc
      ```

   1. Amend the following text with the updated information noted below:  

         ```console
         # set up Python env
         export WORKON_HOME=~/envs
         export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
         export VIRTUALENVWRAPPER_VIRTUALENV_ARGS=' -p /usr/bin/python3 '
         source <path-to-virtualenvwrapper.sh>
         ```

      Updated information:  

      * Replace `<path-to-virtualenvwrapper.sh>` with its appropriate value.
      * Based on the location of Python3 binaries in your environment, update `/usr/bin/python3` to its correct location.

   1. Save the file.

5. Activate the commands in the current window:

      ```console
      source ~/.bashrc
      ```

   **Example output:**

      ```console  
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/premkproject
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/postmkproject
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/initialize
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/premkvirtualenv
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/postmkvirtualenv
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/prermvirtualenv
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/postrmvirtualenv
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/predeactivate
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/postdeactivate
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/preactivate
      virtualenvwrapper.user_scripts creating /home/ubuntu/envs/postactivate
      ```

### Install OCI CLI

1. Start a virtual environment:

      ```console
      workon cli-app
      ```

1. Confirm the name of your virtual environment.  
   If you are, `cli-app` will appear immediately the left of your command prompt.

   **Example:** `(cli-app) ubuntu@<ubuntu-instance-name>:~$`

1. Install OCI CLI:

      ```console
      pip3 install oci-cli
      ```

1. Test the installation:  

      ```console
      oci --version
      ```

   If everything is set up correctly, the fllowing command will return the correct version:  

      ```console
      oci --help
      ```

#### Configure the OCI CLI

1. Enter the following command in your **virtual environment**:  

      ```console
      oci setup config
      ```

1. Enter your answers from the [Gather Required Information](#gather-required-information) section:  

   * **Location for your config [`$HOME/.oci/config`]:** `<take-default>`
   * **User OCID:** `<user-ocid>`
   * **Tenancy OCID:** `<tenancy-ocid>`
   * **Region (e.g., *us-ashburn-1*):** `<region-identifier>`

1. **OpenSSL API encryption keys -** Enter the following information to set up your keys:

   * **Generate a new API Signing RSA key pair? [Y/n]:** Y
   * **Directory for your keys [$HOME/.oci]:** `<take-default>`
   * **Name for your key [oci_api_key]** `<take-default>`

   >**Note:**  
   >Your private key is: `oci_api_key.pem`
   >Your public key is: `oci_api_key_public.pem`.
   {:.notice}

1. Deactivate the virtual environment:

    ```console
    deactivate
    ```

   After you deactivate the virtual environment, you should notice that the `(cli-app)` prefix in your environment is no longer displayed.

### Add the Public Key to your User Account

1. Activate the `cli-app` environment:

      ```console
      workon cli-app
      ```

1. Display the public key:

      ```console
      cat $HOME/.oci/oci_api_key_public.pem
      ```

1. Copy the public key.

1. Add the public key to your user account:

    * Go to the Console.
    * Select your **Profile** menu (your avatar), and then select **User Settings**.
    * Select **API Keys**.
    * Select **Add API Key**.
    * Select **Paste Public Key**.
    * Paste value from previous step, including the lines with `BEGIN PUBLIC KEY` and `END PUBLIC KEY`.
    * Select **Add**.

### Some useful tips

* **Quickly activate the OCI CLI -** Whenever you want to use the OCI CLI, all you have to do is run: `workon cli-app`
* **Quickly deactivate your current working environment -** Whenever you change project names, `workon` deactivates your current working environment. This way, you can quickly switch between environments.
{:.notice}

## Set Up a Cluster

In this section, we'll install and configure management options for your Kubernetes cluster. Later, we'll deploy your application to this cluster.

### Add Compartment Policy

>**Note:** If your username is in the **Administrators** group, you can skip this section.
{:.notice}

If your username is not in the **Administrator** group, you'll need to have your administrator add the following policy to your tenancy:

```console
allow group <the-group-your-username-belongs> to manage compartments in tenancy
```

Why this added step? With this additional privilege, you'll be able to create a compartment for all the resources in your tutorial.

### Steps to add the Compartment Policy

1. In the top navigation bar, open the **Profile** menu.
2. Select your *username*.
3. In the left pane, select **Groups**.
4. In a notepad, copy the **Group Name** to which your *username* belongs.
5. Open the navigation menu and slect **Identity & Security**.  
   Under **Identity**, select **Policies**.
6. Select your compartment from the **Compartment** drop-down.
7. Select **Create Policy**.
8. Fill in the following information:
    * **Name:** `manage-compartments`
    * **Description:** "Allow the group `<the-group-your-username-belongs>` to list, create, update, delete and recover compartments in the tenancy."
    * **Compartment:** `<your-tenancy>(root)`
9. For **Policy Builder**, select **Customize (Advanced)**.
10. Paste in the following policy: allow group `<the-group-your-username-belongs>` to manage compartments in tenancy
11. Select **Create**.

**Reference:** The `compartments` resource-type can be found in the [Verbs + Resource-Type Combinations for IAM] guide.

## Create a Compartment

Here, you'll use your tenancy privileges to create a compartment for the resources that you create in this tutorial:

1. Log in to the OCI **Console**.
2. Open the navigation menu and select **Identity & Security**.  
   Under **Identity**, select **Compartments**.
3. Select **Create Compartment**.
4. Fill in the following information:

   * **Name:** `<your-compartment-name>`
   * **Description:** `Compartment for <your-description>.`
   * **Parent Compartment:** `<your-tenancy>(root)`

5. Select **Create Compartment**.

**Reference:** [Create a compartment]

## Add Resource Policy

If your username is in the **Administrators** group, you can skip this section. Otherwise, have your administrator add the following policy to your tenancy:

```console
allow group <the-group-your-username-belongs> to manage all-resources in compartment <your-compartment-name>
```

With this privilege, you can **manage all resources** in your **compartment**, essentially giving you administrative rights in that compartment.

### Steps to add the Resource Policy

1. Open the navigation menu and select **Identity & Security**.  
   Under **Identity**, select **Policies**.
2. Select your compartment from the **Compartment** drop-down.
3. Select **Create Policy**.
4. Fill in the following information:
    * **Name:** `manage-<your-compartment-name>-resources`
    * **Description:** `Allow users to list, create, update, and delete resources in <your-compartment-name>.`
    * **Compartment:** `<your-tenancy>(root)`
5. For **Policy Builder**, select the following choices:
    * **Policy use cases:** `Compartment Management`
    * **Common policy templates:** `Let compartment admins manage the compartment`
    * **Groups:** `<the-group-your-username-belongs>`
    * **Location:** `<your-tenancy>(root)`
6. Select **Create**.

**Reference:** [Common Policies]

### Create a Cluster with 'Quick Create'

Next, we'll create a cluster with default settings and a new set of network resources through the **Quick Create** workflow.

1. Sign in to the OCI **Console**.
2. Open the navigation menu and select **Developer Services**.  
   Under **Containers & Artifacts**, select **Kubernetes Clusters (OKE)**.
3. Select **Create Cluster**.
4. Select **Quick Create**.
5. Select **Launch Workflow**.
   The **Create Cluster** dialog is displayed.
6. Fill in the following information:
    * **Name:** `<your-cluster-name>`
    * **Compartment:** `<your-compartment-name>`
    * **Kubernetes Version:** `<take-default>`
    * **Kubernetes API Endpoint:** Public Endpoint
      With this selected, the Kubernetes cluster will be hosted in a public subnet with an auto-assigned public IP address.
    * **Kubernetes Worker Nodes:** Private Workers
      With this selected, the Kubernetes worker nodes are hosted in a private subnet.
    * **Shape:** `VM.Standard.E3.Flex`
    * **Number of Nodes:** 3
    * **Specify a custom boot volume size:** *Clear the check box.*
7. Select **Next**.
   Once you do, all your choices are displayed. Take a moment to review them to ensure that everything is configured correctly.
8. Select **Create Cluster**.
   The services setup for your cluster is displayed.
9. Select **Close**.
10. And... get yourself a cup of coffee! Creating the cluster will definitely take a few minutes.  

When this process completes, you'll have successfully created a Kubernetes cluster!

## Set Up Local Access to Your Cluster

After you create a Kubernetes cluster, you'll need to be able to reach it. In this section, we'll set up your local system to access the cluster.

1. Sign in to the OCI **Console**.
2. Open the navigation menu and select **Developer Services**.  
   Under **Containers & Artifacts**, select **Kubernetes Clusters (OKE)**.
3. Select the link to `<your-cluster>`.  
   The information about your cluster is displayed.
4. Select **Access Cluster**.
5. Select **Local Access**.
6. Follow the steps provided in the dialog.  
   We've included a copy of the steps here for your reference:

   > **Note:** If you are not in your virtual environment, enter: `workon cli-app` **before** you run `kubectl` commands.
   {:.notice}

   1. Check your `oci` CLI version:  

         ```console
         oci -v
         ```

   1. Make a `.kube` directory if it doesn't already exist:  

         ```console
         mkdir -p $HOME/.kube
         ```

   1. Create a `kubeconfig` file for your setup.  
      Use the information from **Access Your Cluster** dialog.

         ```console
         oci ce cluster create-kubeconfig <use data from dialog>
         ```

   1. Export the `KUBECONFIG` environment variable:  

         ```console
         export KUBECONFIG=$HOME/.kube/config
         ```

      > **Note:** If you want to have the environment variable start in a new shell, then add `export KUBECONFIG=$HOME/.kube/config` to your `~/.bashrc` file.
      {:.notice}

7. Test your cluster configuration with the following commands:

   * List clusters:  

       ```console
       kubectl get service
       ```

   * Get deployment details:  

       ```console
       kubectl describe deployment
       ```

       Output: "No resources found in default namespace."  
       This is expected since no application is deployed.

   * Get pods:  

       ```console
       kubectl get pods
       ```

       Output: "No resources found in default namespace."  
       This is expected since no application is deployed.

   > **Note:** To look at a different cluster, specify a different config file on the command line. Example:
   >
   > ```console
   > kubectl --kubeconfig=</path/to/config/file>
   > ```
   >
   {:.notice}

With your cluster access set up, you're finally ready to prepare your application for deployment.

## Build a Local Application

Before we deploy your application, we'll need to set up a few things. First, we'll build a local application and then create a Docker image for the application.

### Create a Local Application

Create your Node.js application.

1. Start an OCI CLI session.
1. Create a directory for your application.

      ```console
      mkdir node-hello-app
      cd node-hello-app
      ```

1. Create a `package.json` file:  

      ```console
      vi package.json
      ```

1. In the `package.json` file, input the following text, updating the `author` and `repository` fields:  

      ```json
      {
            "name": "node-hello-app",
            "version": "1.0.0",
            "description": "Node Express Hello application",
            "author": "Example User <username@example.com>",
            "main": "app.js",
            "scripts": {
                "start": "node app.js"
            },
            "repository": {
                "type": "git",
                "url": "git://github.com/username/repository.git"
            },
            "dependencies": {
                "express": "^4.0.0"
            },
            "license": "UPL-1.0"
      }          
      ```  

1. Save the file.

1. Install the NPM packages:  

      ```console
      npm install
      ```

1. Create a "Hello, World!" application.

   1. Create the file:

         ```console
         vi app.js
         ```

   2. In the file, input the following text:  

         ```javascript
         const express = require('express')
         const app = express()
         port = 3000

         app.get('/', function (req, res) {
            res.send('<h1>Hello World from Node.js!</h1>')
         })

         app.listen(port, function() {
            console.log('Hello World app listening on port ' + port);
         })
         ```

You have successfully set up your Node.js app!

## Run the local application

Let's make sure that your application is working properly.

1. Run your Node.js application:

      ```console
      node app.js
      ```

   The Node Express server starts and displays:  

      ```console
        Hello World app listening on port 3000
      ```

1. Test the application:  
    * To test with `curl`, run:

        ```console
        curl -X GET http://localhost:3000
        ```

    * To test with your browser, connect a browser window to: `http://<your-ip-address>:3000`:

        The page should display:  

        ```html
        <h1>Hello World from Node.js!</h1>
        ```

1. Stop the running application.

   Press **Ctrl+C** to stop your application in the terminal window you started with.

That's it! You've successfully created a Hello World application using Node.js and Express.

**Reference:** For detailed information on this example, see [Getting Started with Express].

## Build a Docker Image

Next, create a Docker image for your Node.js Express application.

1. Ensure that you're in the `node-hello-app` directory.

1. Build a Docker image:  

      ```console
      docker build -t node-hello-app .
      ```

   You should see the following message:  

      ```console  
      [INFO] BUILD SUCCESS
      Successfully tagged node-hello-app:latest
      ```

1. Run the Docker image:  

      ```console
      docker run --rm -p 3000:3000 node-hello-app:latest
      ```

1. Test the application.

      ```console
      curl -X GET http://localhost:3000
      ```

   The app should return:  

      ```html
      <h1>Hello World from Node.js!</h1>
      ```

1. Stop the running application.

Congratulations! You've successfully created a Node.js Express image.

## Deploy Your Docker Image

In this section, we'll push your Node.js Express image to OCI Container Registry and then use the image to deploy your application.

> **Note:** Before you can push a Docker image into a registry repository, **the repository must exist in your compartment**. If the repository does not exist, the Docker push command will not work correctly.
{:.warn}

### Create a Docker Repository

1. Open the navigation menu and select **Developer Services**.  
   Under **Containers & Artifacts**, select **Container Registry**.
2. In the left navigation, select `<your-compartment-name>`.
3. Select **Create Repository**.
4. Create a **private repository** with your choice of repo name:

      ```console
      <repo-name> = <image-path-name>/<image-name>
      ```

   **Example:** `node-apps/node-hello-app`

   > Note: The slash in a repository name **does not represent a hierarchical directory structure**. The optional `<image-path-name>` helps to organize your repositories.
   {:.notice}

You are now ready to push your local image to Container Registry.

## Push Your Local Image

With your local Docker image created, push the image to the Container Registry.  

Follow these steps:  

1. Open your OCI CLI session.
1. Log in to OCI Container Registry:

      ```console
      docker login <region-key>.ocir.io
      ```

   You are prompted for your login name and password:

   * **Username:** `<tenancy-namespace>/<user-name>`
   * **Password:** `<auth-token>`

1. List your local Docker images:  

      ```console
      docker images
      ```

   The Docker images on your system are displayed. Identify the image you created in the [last section](#build-a-docker-image): `node-hello-app`

1. **Tag** your local image with the **URL for the registry** plus the **repo name**, so you can push it to that repo:  

      ```console
        docker tag <your-local-image> <repo-url>/<repo-name>
      ```

   * Replace **`<repo-url>`** with:  
   `<region-key>.ocir.io/<tenancy-namespace>/`

   * Replace **`<repo-name>`** with:  
   `<image-folder-name>/<image-name>` from the **Create a Docker Repository** section.

   Here is an example after combining both:  

     ```console
     docker tag node-hello-app iad.ocir.io/my-namespace/node-apps/node-hello-app
     ```

   In this example, the components are:  

   * **Repo URL:** `iad.ocir.io/my-namespace/`
   * **Repo name:** `node-apps/node-hello-app`

   > **Note:** OCI Container Registry now supports creating a registry repo in *any* compartment rather than only in the root compartment (tenancy). To push the image to the repo you created, combine the registry URL with the exact repo name. OCI Container Registry matches based on the unique repo name and pushes your image.
   {:.notice}

1. Check your Docker images to see if the image is **copied**:  

      ```console
      docker images
      ```

   * The tagged image has **the same image ID** as your local image.
   * The tagged image name is: `<region-key>.ocir.io/<tenancy-namespace>/<image-path-name>/<image-name>`

1. Push the image to Container Registry:  

      ```console
      docker push <copied-image-name>:latest
      ```

   **Example:**

      ```console
      docker push iad.ocir.io/my-namespace/node-apps/node-hello-app:latest
      ```

1. Open the navigation menu and select **Developer Services**.  
   Under **Containers & Artifacts**, select **Container Registry**.

1. Find your image in the **Container Registry** after the push command is complete.

## Deploy the Image

We're finally here! The moment of truth. With your image in Container Registry, you can now deploy your image and app:  

1. **Create a registry secret for your application -** This secret authenticates your image when you deploy it to your cluster.

   To create your secret, fill in the information in this template:  

      ```console
      kubectl create secret docker-registry ocirsecret --docker-server=<region-key>.ocir.io  --docker-username='<tenancy-namespace>/<user-name>' --docker-password='<auth-token>'  --docker-email='<email-address>'
      ```

   After the command runs, you get a message similar to: `secret/ocirsecret created`.

1. **Verify that the secret is created -** Issue the following command:  

      ```console
      kubectl get secret ocirsecret --output=yaml
      ```

   The output includes information about your secret in yaml format.

1. **Host URL -** Determine the host URL to your registry image using the following template:  

      ```console
      <region-code>.ocir.io/<tenancy-namespace>/<repo-name>/<image-name>:<tag>
      ```

   **Example:**

      ```console
      iad.ocir.io/my-namespace/node-apps/node-hello-app:latest
      ```

1. On your system, create a file called `node-app.yaml`.

    Include the text below and replace the following placeholders:

    * `<your-image-url>`
    * `<your-secret-name>`

      ```yaml
      apiVersion: apps/v1
         kind: Deployment
         metadata:
           name: node-app
         spec:
           selector:
             matchLabels:
               app: app
           replicas: 3
           template:
             metadata:
               labels:
                 app: app
             spec:
               containers:
               - name: app
                 image: <your-image-url>
                 imagePullPolicy: Always
                 ports:
                 - name: app
                   containerPort: 3000
                   protocol: TCP
               imagePullSecrets:
                 - name: <your-secret-name>
         ---
         apiVersion: v1
         kind: Service
         metadata:
           name: node-app-lb
           labels:
             app: app
           annotations:
             service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
             service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
             service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "100"
         spec:
           type: LoadBalancer
           ports:
           - port: 3000
           selector:
             app: app
      ```

   > Note: In the `node-app.yaml` file, the code after the dashes adds a flexible load balancer.
   {:.notice}
1. Deploy your application with the following command:  

      ```console
      kubectl create -f node-app.yaml
      ```

   **Sample output:**

      ```console
      deployment.apps/node-app created
      service/node-app-lb created
      ```

## Test Your App

After you deploy your app, it might take the load balancer a few seconds to load.

1. Check if the load balancer is live:  

      ```console
      kubectl get service
      ```

1. Repeat the command until load balancer is assigned an IP address.

   > **Note:** While waiting for the load balancer to deploy, you can check the status of your cluster with these commands:
   >
   > * Get each pods status: `kubectl get pods`
   > * Get app status: `kubectl get deployment`
   {:.notice}

1. Use the load balancer IP address to connect to your app in a browser:

      ```console
      http://<load-balancer-IP-address>:3000
      ```

   The browser should display `<h1>Hello World from Node.js!</h1>`

1. **[OPTIONAL]** Undeploy your application from the cluster  
   To remove your application, run this command:  

      ```console
      kubectl delete -f node-app.yaml
      ```

   **Sample output:**

      ```console
      deployment.apps/node-app deleted
      service "node-app-lb" deleted
      ```

   Your application is now removed from your cluster.

## What's Next

We've accomplish a lot in this tutorial! You've successfully created a Hello World application, deployed it to a Kubernetes cluster, and made it accessible on the internet using the Node Express framework.

Check out these sites to explore more information about development with Oracle products:

[Oracle Developers Portal]
[Oracle Cloud Infrastructure]
{% endslides %}

<!--- links -->

[Kubernetes Documentation]: https://kubernetes.io/docs/home/
[OCI Container Engine for Kubernetes]: https://docs.oracle.com/iaas/Content/ContEng/Concepts/contengoverview.htm
[OCI Container Registry]: https://docs.oracle.com/iaas/Content/Registry/Concepts/registryoverview.htm
[Getting started with OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm

[Signing Up for Oracle Cloud Infrastructure]: https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm

[Windows Subsystem for Linux]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[Oracle Virtual Box]: https://www.virtualbox.org/

[Kubernetes Using Cloud Shell: Deploy a Spring Boot Application]: https://docs.oracle.com/iaas/developer-tutorials/tutorials/spring-on-k8s-cs/01oci-spring-cs-k8s-summary.htm

[install an Oracle Linux VM]: https://docs.oracle.com/iaas/developer-tutorials/tutorials/apache-on-oracle-linux/01oci-ol-apache-summary.htm#create-oracle-linux-vm
[install an Ubuntu VM]: https://docs.oracle.com/iaas/developer-tutorials/tutorials/helidon-on-ubuntu/01oci-ubuntu-helidon-summary.htm#create-ubuntu-vm

[Install Kubernetes client on Linux]: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux
[Install Kubernetes client on MacOS]: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/
[Get Docker]: https://docs.docker.com/get-docker/

[VM Standard Shapes]: https://docs.oracle.com/iaas/Content/Compute/References/computeshapes.htm#vmshapes__vm-standard

[Verbs + Resource-Type Combinations for IAM]: https://docs.oracle.com/iaas/Content/Identity/Reference/iampolicyreference.htm#Identity

[Create a compartment]: https://docs.oracle.com/iaas/Content/Identity/Tasks/managingcompartments.htm#To

[Common Policies]: https://docs.oracle.com/iaas/Content/Identity/Concepts/commonpolicies.htm

[Getting Started with Express]: https://expressjs.com/en/starter/hello-world.html

[Regions and Availability Domains]: https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm

[Oracle Developers Portal]: https://developer.oracle.com/
[Oracle Cloud Infrastructure]: https://www.oracle.com/cloud/
