---
title: How to Deploy a Python Flask Application in a Kubernetes cluster
parent: tutorials
tags:
- oci
- open-source
- kubernetes
- flask-cloud-shell
- python
thumbnail: assets/flask-shell-diagram.png
date: 2021-10-11 01:00
description: Setting up a Kubernetes cluster using Oracle Cloud, and deploying a Python
  application with Flask framework using Cloud Shell.
redirect_from: "/collections/tutorials/deploy-flask-app-cloud-shell/"
---
{% slides %}

In this tutorial, you use an Oracle Cloud Infrastructure account to set up a Kubernetes cluster. Then, you create a Python application with a Flask framework. Finally, you deploy your application to your cluster using Cloud Shell.

Key tasks include how to:

  * Create a Compartment.
  * Set up a Kubernetes cluster on OCI.
  * Build a Python application in a Flask framework.
  * Create a Docker image.
  * Push your image to OCI Container Registry.
  * Use Cloud Shell to deploy your Docker application to your cluster.
  * Connect to your application from the internet.
![A diagram of the components needed to run a Flask app on Kubernetes cluster, on Oracle Cloud Infrastructure](assets/flask-shell-diagram.png)

For additional information, see:

  * [More on Kubernetes](https://kubernetes.io/docs/home/)
  * [OCI Container Engine](https://docs.oracle.com/iaas/Content/ContEng/Concepts/contengoverview.htm)
  * [OCI Container Registry](https://docs.oracle.com/iaas/Content/Registry/Concepts/registryoverview.htm)
  * [Cloud Shell](https://docs.oracle.com/iaas/Content/API/Concepts/cloudshellintro.htm)

## Before You Begin

To successfully perform this tutorial, you must have the following:

### Requirements

  * A **Free trial** or a **paid** Oracle Cloud Infrastructure account. You can sign up [here](https://signup.cloud.oracle.com/?language=en&sourceType=:ow:de:te::::RC_WWMK210625P00048:Free&intcmp=:ow:de:te::::RC_WWMK210625P00048:Free).
  * Cloud Shell or the following 
     * JDK 8+
     * Python 3.6.8+
     * Kubectl 1.18.10+
     * Apache Maven 3.5+
     * Docker 19.0.11+

> The advantage of using Cloud Shell is all the required tools to manage your application are already installed and ready to use.
{:.notice}

## Prepare

Prepare your environment to create and deploy your application.

### Check your Service Limits

  1. Log in to the Oracle Cloud Infrastructure **Console**.
  2. Open the navigation menu, and click Governance and Administration. Under Governance, click Limits, Quotas and Usage.
  3. Find your service limit for **Regions**:
     * **Filter** for the following options:
       * **Service:** Regions
       * **Scope:** Tenancy
       * **Resource:** Subscribed region count
       * **Compartment:** `<tenancy-name>` (root)
     * Find service limit:
       * **Limit Name:** `subscribed-region-count`
       * **Service Limit:** minimum 2
  4. Find your available **Compute** **core count** for the **VM.Standard.E2.1** shape:
     * **Filter** for the following options:
       * **Service:** Compute
       * **Scope:** `<first-availability-domain>`. Example: `EMlr:US-ASHBURN-AD-1`
       * **Resource:** **Cores** for Standard.E2 based VM and BM Instances
       * **Compartment:** `<tenancy-name>` (root)
     * Find available core count:
       * **Limit Name:** `standard-e2-core-count`
       * **Available:** minimum 1
     * Repeat for **Scope:** `<second-availability-domain>` and `<third-availability-domain>`. Each region must have at least one core available for this shape.
  5. Find out if you have **50 GB** of **Block Volume** available:
     * **Filter** for the following options:
       * **Service:** Block Volume
       * **Scope:** `<first-availability-domain>`. Example: `EMlr:US-ASHBURN-AD-1`
       * **Resource** Volume Size (GB)
       * **Compartment:** `<tenancy-name>` (root)
     * Find available core count:
       * **Limit Name:** `total-storage-gb`
       * **Available:** minimum 50
     * Repeat for **Scope:** `<second-availability-domain>` and `<third-availability-domain>`. Each region must have at least 50 GB of block volume available.
  6. Find out how many **Flexible Load Balancers** you have available:
     * **Filter** for the following options:
       * **Service:** LBaaS
       * **Scope:** `<your-region>`. Example: `us-ashburn-1`
       * **Resource:** <blank>
       * **Compartment:** `<tenancy-name>` (root)
     * Find the count for the following shapes
       * **Limit Name:** `lb-flexible-bandwidth-count`
       * **Available:** minimum 1


> This tutorial creates three compute instances with a **VM.Standard.E2.1** shape for the cluster nodes. To use another shape, filter for its **core count**. For example, for **VM.Standard2.4**, filter for **Cores for Standard2 based VM and BM Instances** and get the **count**.
> - For a list of all shapes, see [VM Standard Shapes](https://docs.oracle.com/iaas/Content/Compute/References/computeshapes.htm#vmshapes__vm-standard).
{:.notice}

> This tutorial creates a load balancer with a **flexible** shape. To use another bandwidth, filter for its **count**, for example **100-Mbps bandwidth** or **400-Mbps bandwidth**.
{:.notice}

### Create an Authorization Token

  1. In the Console's top navigation bar, click the **Profile** menu (your avatar).
  2. Click your username.
  3. Click Auth Tokens.
  4. Click Generate Token. 
  5. Give it a description.
  6. Click Generate Token.
  7. Copy the token and **save** it.
  8. Click Close.

      > **Ensure that you save your token** right after you create it. You have no access to it later.
      {:.notice}

### Gather Required Information


  1. Collect the following credential information from the Oracle Cloud Infrastructure **Console**.

     * **Tenancy name:** `<tenancy-name>`
       * Click your **Profile** menu (your avatar) and find your **Tenancy:<tenancy-name>**.
     * **Tenancy namespace:** `<tenancy-namespace>`
       * Click your **Profile** menu (your avatar).
       * Click **Tenancy: <tenancy-name>**.
       * Copy the value for **Object Storage Namespace**.

      >For some accounts, tenancy name and namespace differ. Ensure that you use namespace in this tutorial.
      {:.notice}

     * **Tenancy OCID:** `<tenancy-ocid>`
       * Click your **Profile** menu (your avatar), then click **Tenancy:<tenancy-name>**, and copy OCID.
     * **Username:** `<user-name>`
       * Click your **Profile** menu (your avatar).
     * **User OCID:** `<user-ocid>`
       * Click your **Profile** menu (your avatar), then click **User Settings**, and copy OCID.

  2. Find your region information.

     * **Region:** `<region-identifier>`
       * In the Console's top navigation bar, find your region. Example: **US East (Ashburn)**.
       * Find your **Region Identifier** from the table in [Regions and Availability Domains](https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm). 
       * Example: `us-ashburn-1`.
     * **Region Key:** `<region-key>`
       * Find your **Region Key** from the table in [Regions and Availability Domains](https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm). 
       * Example: `iad`

  2. Copy your authentication token from **Create an Authentication Token** section.

     * **Auth Token:** `<auth-token>`


## Set Up a Cluster

Install and configure management options for your Kubernetes cluster. Later, deploy your application to this cluster.

### Add Compartment Policy

If your username is in the **Administrators** group, then skip this section. Otherwise, have your administrator add the following policy to your tenancy:
 
    allow group <the-group-your-username-belongs> to manage compartments in tenancy

With this privilege, you can create a compartment for all the resources in your tutorial.

### Steps to Add the Policy

  1. In the Console's top navigation bar, open the **Profile** menu (your avatar).
  2. Click your username.
  3. In the left pane, click Groups.
  4. In a notepad, copy the **Group Name** that your username belongs.
  5. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Policies**.
  6. Click Create Policy.
  7. Fill in the following information:

     * **Name:** `manage-compartments`
     * **Description:** `Allow the group <the-group-your-username-belongs> to list, create, update, delete and recover compartments in the tenancy.`
     * **Compartment:** `<your-tenancy>(root)`

  8. For **Policy Builder**, click Show Manual Editor.
  9. Paste in the following policy:

    
    allow group <the-group-your-username-belongs> to manage compartments in tenancy

  10. Click Create.

**Reference**

The `compartments` resource-type in [Verbs + Resource-Type Combinations for IAM](https://docs.oracle.com/iaas/Content/Identity/Reference/iampolicyreference.htm#Identity)

### Create a Compartment

Create a compartment for the resources that you create in this tutorial.

  1. Log in to the Oracle Cloud Infrastructure **Console**.
  2. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Compartments**.
  3. Click Create Compartment.
  4. Fill in the following information:
     * **Name:** `<your-compartment-name>`
     * **Description:** `Compartment for <your-description>.`
     * **Parent Compartment:** `<your-tenancy>(root)`
  5. Click Create Compartment.

**Reference:** [Create a compartment](https://docs.oracle.com/iaas/Content/Identity/Tasks/managingcompartments.htm#To)

### Add Resource Policy

If your username is in the **Administrators** group, then skip this section. Otherwise, have your administrator add the following policy to your tenancy:

```  
allow group <the-group-your-username-belongs> to manage all-resources in compartment <your-compartment-name>
```

With this privilege, you can **manage all the resources** in your **compartment**, essentially giving you administrative rights in that compartment.

### Steps to Add the Policy

  1. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Policies**.
  2. Select your compartment from the Compartment list.
  3. Click Create Policy.
  4. Fill in the following information:

     * **Name:** `manage-<your-compartment-name>-resources`
     * **Description:** `Allow users to list, create, update, and delete resources in <your-compartment-name>.`
     * **Compartment:** `<your-tenancy>(root)`

  5. For **Policy Builder**, select the following choices:

     * **Policy use cases:** `Compartment Management`
     * **Common policy templates:** `Let compartment admins manage the compartment`
     * **Groups:** `<the-group-your-username-belongs>`
     * **Location:** `<your-tenancy>(root)`

  6. Click Create.

**Reference**

[Common Policies](https://docs.oracle.com/iaas/Content/Identity/Concepts/commonpolicies.htm)

### Create a Cluster with 'Quick Create'

Create a cluster with default settings and new network resources through the 'Quick Create' workflow.

  1. Sign in to the Oracle Cloud Infrastructure **Console**.
  2. Open the navigation menu and click **Developer Services**. Under **Containers & Artifacts**, click**Kubernetes Clusters (OKE)**.
  3. Click Create Cluster.
  4. Select Quick Create.
  5. Click Launch Workflow.
  6. The **Create Cluster** dialog is displayed. Fill in the following information.

     * **Name:** `<your-cluster-name>`
     * **Compartment:** `<your-compartment-name>`
     * **Kubernetes Version:** `<take-default>`
     * **Kubernetes API Endpoint:** Public Endpoint 
      The Kubernetes cluster is hosted in a public subnet with an auto-assigned public IP address.
     * **Kubernetes Worker Nodes:** Private Workers 
      The Kubernetes worker nodes are hosted in a private subnet.

     * **Shape:** VM.Standard.E2.1
     * **Number of Nodes:** 3
     * **Specify a custom boot volume size:** Clear the check box.

  7. Click **Next**.
  All your choices are displayed. Review them to ensure that everything is configured correctly.

  8. Click **Create Cluster**.
  The services set up for your cluster are displayed.

  9. Click **Close**.
  10. Get a cup of coffee. It takes a few minutes for the cluster to be created.

You have successfully created a Kubernetes cluster.

### Configure Cloud Shell to Access to Your Cluster

After you create a Kubernetes cluster, set up your local system to access the cluster.

  1. Sign in to the Oracle Cloud Infrastructure **Console**.
  2. Open the navigation menu and click **Developer Services**. Under **Containers & Artifacts**, click**Kubernetes Clusters (OKE)**.
  3. Click the link to **`<your-cluster>`**.

The information about your cluster is displayed.

  4. Click Access Cluster.
  5. Click Cloud Shell Access. Follow the steps in the dialog. The following steps are provided for your reference.
  6. From the main menu, click the Cloud Shell icon (![](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/common/k8s-cs/images/cloud_shell_icon.png)) and start a session.
  7. Check your `oci` CLI version and verify that Cloud Shell is working.
      ```console  
      oci -v
      ```
  8. Make your `.kube` directory if it doesn't exist.
      ```console
      mkdir -p $HOME/.kube
      ```
  9.  Create kubeconfig file for your setup. Use the information from **Access Your Cluster** dialog.
      ```console
      oci ce cluster create-kubeconfig <use data from dialog>
      ```

  10. Test your cluster configuration with the following command.
        ```console
        kubectl get service
        ```

> If the `config` file is not stored in its default location (`~/.kube/config`), you must export the`KUBECONFIG` environment variable to point to the location. 
> 
>   _export KUBECONFIG=$HOME/<new-location>/config_
{:.notice} 
  
> When working with more than one cluster, you specify a specific config file on the command line.
> Example:
>    kubectl --kubeconfig=</path/to/config/file> <some-command>
{:.notice}


With your cluster access setup, you are now ready to prepare your application for deployment.

## Build your Docker Application

Next, set up the Flask framework on Cloud Shell. Then, create and run a Python application. 

### Create a Local Application

Create your Flask application.

  1. Install Flask.
      ```console
      pip3 install --user Flask
      ```

  2. Create a directory for your application.
      ```console
      mkdir python-hello-app
      ```

  3. Change to the `python-hello-app` directory.
      ```console
      cd python-hello-app
      ```

  4. Create a "Hello, World!" application.
     - Create the file:
  
      ```console
      vi hello.py
      ```
     - In the file, input the following text:
  
      ```python
      from flask import Flask
      app = Flask(__name__)

      @app.route('/')
      def hello_world():
          return '<h1>Hello World from Flask!</h1>'

      if __name__ == "__main__":
          app.run(host="0.0.0.0", port=int("5000"), debug=True)
      ```

  5. Save the file.

### Run the Local Application

Run your Flask application.

  1. Run the Python program.
      ```console
      export FLASK_APP=hello.py
      export FLASK_ENV=development
      python3 hello.py
      ```

      Produces the following output:
          
      * Serving Flask app 'hello' (lazy loading)
      * Environment: development
      * Debug mode: on
      * Running on all addresses.
      WARNING: This is a development server. Do not use it in a production deployment.
      * Running on http://x.x.x.x:5000/ (Press CTRL+C to quit)
      * Restarting with stat
      * Debugger is active!
      * Debugger PIN: xxx-xxx-xxx                    

  2. Move the app to the background.

     * Hit **Ctrl z**.
     * Enter the following command: `bg`

  3. Test the app using `curl`.

      In Cloud Shell terminal, enter the following code:
      ```console
      curl -X GET http://localhost:5000
      ```
      Output:
      ```html 
      <h1>Hello World from Flask!</h1>
      ```
  4. Stop the running application.

      When you are done testing, get the process ID for your application.
      ```console
      ps -ef
      ```
      Stop the process.
      ```console
      kill <your-pid>
      ```

You have successfully created a local Python application with the Flask framework.

**References:**

For more information on Flask, see [Flask Documentation](https://flask.palletsprojects.com/).

### Build a Docker Image

Next, create a Docker image for your Flask application.

  1. First, ensure you are in the `python-hello-app` directory.
  2. Create the configuration file `Dockerfile`:

      ```console
      vi Dockerfile
      ```

      In the file, input the following text and save the file:
      ```dockerfile   
      FROM python:3.9-slim-buster
      ADD hello.py /
      COPY . /app
      WORKDIR /app
      RUN pip3 install Flask
      EXPOSE 5000
      CMD [ "python3", "./hello.py" ]
      ```
  3. Build a Docker image: 
      ```console
      docker build -t python-hello-app .
      ```
      You get a success message.
      ```console
      [INFO] BUILD SUCCESS
      Successfully tagged python-hello-app:latest
      ```
  4. Run the Docker image: 
      ```console
      docker run --rm -p 5000:5000 python-hello-app:latest &
      ```
  5. Test the application using the `curl` command:
      ```console
      curl -X GET http://localhost:5000
      ```

      If you get `<h1>Hello World from Flask!</h1>`, then the Docker image is running. Now you can push the image to Container Registry.

  6. Stop the running application.
      When you are done testing, get the process ID for your application.
      ```console
      ps -ef
      ```
      Stop the process.
      ```console
      kill <your-pid>
      ```
Congratulations! You have successfully created a Python Flask Docker image.

  

## Deploy Your Docker Image

With your Python image created, now you can deploy it.

### Create a Docker Repository

  1. Open the navigation menu and click **Developer Services**. Under **Containers & Artifacts**, click**Container Registry**.
  2. In the left navigation, select `<your-compartment-name>`.
  3. Click Create Repository.
  4. Create a **private repository** with your choice of repo name:
      ```
      <repo-name> = <image-path-name>/<image-name>
      ```

      Example: `flask-apps/python-hello-app`

You are now ready to push your local image to Container Registry.


> Before you can push a Docker image into a registry repository, **the repository must exist in your compartment**. If the repository does not exist, the Docker push command does not work correctly.
> The slash in a repository name **does not represent a hierarchical directory structure**. The optional `<image-path-name>` helps to organize your repositories.
{:.notice}

### Push Your Local Image

With your local Docker image created, push the image to the Container Registry.

Follow these steps.

  1. Open a terminal window.
  2. Log in to Container Registry:
      ```console    
      docker login <region-key>.ocir.io
      ```

      You are prompted for your login name and password.

        * **Username:** `<tenancy-namespace>/<user-name>`
        * **Password:** `<auth-token>`

  3. List your local Docker images:
      ```console    
      docker images
      ```
      The Docker images on your system are displayed. Identify the image you created in the last section: `python-hello-app`

  4. **Tag** your local image with the **URL for the registry** plus the **repo name**, so you can push it to that repo.

      ```console    
      docker tag <your-local-image> <repo-url>/<repo-name>
      ```
      Replace `<repo-url>` with:
      ```
      <region-key>.ocir.io/<tenancy-namespace>/
      ```
      Replace `<repo-name>` with `<image-folder-name>/<image-name>` from the *Create a Docker Repository* section.  
  
      Here is an example after combining both:
      ```console  
      docker tag python-hello-app iad.ocir.io/my-namespace/flask-apps/python-hello-app
      ```
      In this example, the components are:

       * **Repo URL:** `iad.ocir.io/my-namespace/`
       * **Repo name:** `flask-apps/python-hello-app`

      >OCI Container Registry now supports creating a registry repo in any compartment rather than only in the root compartment (tenancy). To push the image to the repo you created, combine the registry URL with the exact repo name. OCI Container Registry matches based on the unique repo name and pushes your image.
      {:.notice}

  5. Check your Docker images to see if the image is **copied**.
      ```console
      docker images
      ```
     * The tagged or the **copied image** has **the same image ID** as your local image.
     * The **copied image name** is:
      
      ```    
      <region-key>.ocir.io/<tenancy-namespace>/<image-folder-name>/<image-name>
      ```

  6. Push the image to Container Registry.
      ```console  
      docker push **<copied-image-name>**:latest
      ```
      Example:
      ```console
      docker push iad.ocir.io/my-namespace/flask-apps/python-hello-app:latest
      ```
  7. Open the navigation menu and click **Developer Services**. Under **Containers & Artifacts**, click**Container Registry**.

      Find your image in Container Registry after the push command is complete.

### Deploy the Image

With your image in Container Registry, you can now deploy your image and app.

1. Create a registry secret for your application. This secret authenticates your image when you deploy it to your cluster.

   To create your secret, fill in the information in this template .

   ```console   
   kubectl create secret docker-registry ocirsecret \
     --docker-server=<region-key>.ocir.io  \
     --docker-username='<tenancy-namespace>/<user-name>' \
     --docker-password='<auth-token>'  \
     --docker-email='<email-address>'
   ```
   After the command runs, you get a message similar to: `secret/ocirsecret created`.

2. Verify that the secret is created. Issue the following command:

   ```console   
   kubectl get secret ocirsecret --output=yaml
   ```
   The output includes information about your secret in the yaml format.

3. Determine the host URL to your registry image using the following template:

   ```    
   <region-code>.ocir.io/<tenancy-namespace>/<repo-name>/<image-name>:<tag>
   ```
   Example:
   ```    
   iad.ocir.io/my-namespace/flask-apps/python-hello-app:latest
   ```
4. On your system, create a file called `app.yaml` with the following text:

   Replace the following place holders:
       * `<your-image-url>`
       * `<your-secret-name>`

   ```yaml   
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: app
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
             containerPort: 5000
             protocol: TCP
         imagePullSecrets:
           - name: <your-secret-name>
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: app-lb
     labels:
       app: app
     annotations:
       service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
       service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
       service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "100"
   spec:
     type: LoadBalancer
     ports:
     - port: 5000
     selector:
       app: app
   ```
5. Deploy your application with the following command.

   ```console   
   kubectl create -f app.yaml
   ```
   Output: 
   ```    
   deployment.apps/app created
   ```

    >In the `app.yaml` file, the code after the dashes adds a flexible load balancer.
    {:.notice}
### Test Your App

After you deploy your app, it might take the load balancer a few seconds to load.

  1. Check if the load balancer is live:

      ```console   
      kubectl get service
      ```
      Repeat the command until load balancer is assigned an IP address.

      >While waiting for the load balancer to deploy, you can check the status of your cluster with these commands: 
      >    * Get each pods status: `kubectl get pods`
      >    * Get app status: `kubectl get deployment`
      {:.notice}

  2. Use the load balancer IP address to connect to your app in a browser:
      ```
      http://<load-balancer-IP-address>:5000
      ```
      The browser displays: `<h1>Hello World from Flask!</h1>`

  3. Undeploy your application from the cluster. _**(Optional)**_ To remove your application run this command:

      ```console
      kubectl delete -f app.yaml
      ```
      Output:
      ```    
      deployment.apps/python-hello-app deleted
      service "python-hello-app-lb" deleted
      ```
      Your application is now removed from your cluster.

## What's Next

You have successfully created a Hello World Python application, deployed it to a Kubernetes cluster and made it accessible on the internet, using the Flask framework.

Check out these sites to explore more information about development with Oracle products:

  * [Oracle Developers Portal](https://developer.oracle.com/)
  * [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
{% endslides %}
