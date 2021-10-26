---
title: Get Started with your own LAMP stack application on Oracle Cloud
parent: tutorials
tags:
- data-management
- front-end
- mysql
- oci
- orm
thumbnail: assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-12-19.png
date: 2021-10-01 09:18
description: Build Move & Modernize Apps and Hybrid Solutions, DevOps and Automation
  on OCI.
categories:
- cloudapps
author:
  name: lefred
  home: https://lefred.be/
  linkedin: freddescamps
  twitter: lefred
  github: lefred
redirect_from: "/collections/tutorials/get-started-with-lamp-on-oci/"
---



I've written [several articles](https://lefred.be/deploy-to-oci/) about how to deploy popular Open Source applications on Oracle Cloud Infrastructure and MySQL Database Service.

Now we will see how you can deploy your own LAMP stack application using the same technique where **L** will stand for a compute instance (and why not the [Ampere always free trier](https://lefred.be/content/deploy-on-oci-using-ampere-compute-instances/)?), **A** stays Apache and will run in that compute instance. **M** stands for MySQL Database Service and **P** is for PHP.

As usual we start by deploying a Stack by just clicking on the deploy button [from GitHub](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-11-43.png)

Then we are redirected to OCI’s dashboard and we need to accept the Terms of Use:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-11-56.png)

As soon as we accept the Terms of Use, we see the information being updated, and we can directly click on Next:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-12-04.png)

On the next screen, we can set all the variables. Some are mandatory and the others are already pre-filled:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-12-19.png)

This is also where you can choose which version of PHP you want to use:

![](assets/get-started-with-lamp-on-oci-Selection_048.png)

You validate everything, and then Create the stack and deploy the architecture on OCI:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-13-12.png) ![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-28-39.png)

As you can see, we have all the generated and required information in the **Outputs** section.

We can already use the public IP in a browser and we should see the following page:

![](assets/get-started-with-lamp-on-oci-Selection_049.png)

Now the Web server is ready to get our code. From the stack’s outputs, we already know the IP, the username, and password to use to connect to MySQL Database Service.

We also need the ssh key that we can copy locally to ssh to the Web Server to deploy our code, or we can use the Cloud Shell from OCI’s dashboard. Let’s use it:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-31-30.png)

We create a file for the ssh key (`php.key`) and we paste its content in it:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-28-39-1.png) ![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-31-38.png)

We change the permission of the key’s file and we use it to connect to our web server using its public IP:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-32-03.png)

As an application, we will use [this gist file which is a PHP script](https://gist.github.com/lefred/b97fe90f31115607e0d28ddc8a72ca16) that connects to MDS and we will place it in `**/var/www/html**`:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-32-58.png)

We edit it, and there are 3 variables to modify using the values from the Stack’s outputs:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-41-03.png)

When done, we can refresh the page on the browser and we will see our code being processed:

![](assets/get-started-with-lamp-on-oci-Screenshot-from-2021-05-28-13-54-44.png)

The Web server box already contains `git` and `certbot`.

Now you are able to deploy your own LAMP stack easily to OCI, enjoy!
