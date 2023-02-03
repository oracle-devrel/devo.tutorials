---
title: Automation Basics
parent:
- tutorials
- ci-automation
sidebar: series
tags:
- open-source
- iac
- devops
- get-started
categories:
- iac
- opensource
thumbnail: assets/ci-automation.png
date: 2023-02-01 12:00
description: By this point you should be ready to dive right in and build some automation. Start with the OCI Command Line Interface (CLI) to provision your resources.
toc: true
author: eli-schilling
redirect_from: "/collections/tutorials/1-automation-basics/"
mrm: 
xredirect: https://developer.oracle.com/tutorials/ci-automation/1-automation-basics/
slug: 1-automation-basics
---
{% imgx aligncenter assets/ci-automation.png 400 400 "Automating Container Instances" "Container Instances Automation Tutorial Series" %}

In this tutorial we are going to build a simple virtual network environment and deploy an OCI Container Instance resource. The Container Instance will run two containers; WordPress in one, and MySQL in the other. All of the work is done at the command prompt and when you're finished, you could easily create a bash script for one-click deployment in the future.

If you do not yet have the CLI installed, [Click Here][1] to follow the instructions. WHen you're ready to go, dive right in!

### Gather Required Information
The prep work involves identifying your preferred availability domain and working compartment. It is recommended you do not use the *root* compartment in your tenancy, however, the instructions will accommodate use of *root* if you so choose.

View the list of availability domains in your designated region. We will be collecting both the **name** and **id**.

    oci iam availability-domain list

![Screenshot of: List of availability domains][2]

The command output is JSON so there are a few tricks we can use to easily capture the data we need. In another article, we'll delve further into the *--query* functionality of the CLI. For now, you can check out [Jmespath.org][3] if you're curious.

One more example before we move on. The following will query for the availability domain that includes "AD-1" in the name. If you'd like to use a different AD, just change the number. 

    oci iam availability-domain list --query 'data[?contains ("name",`AD-1`)]|[0].[id,name]' | sed 's/"//g'

Capture the availability domain id and name in environment variables.

    adId=($(oci iam availability-domain list --query 'data[?contains ("name",`AD-1`)]|[0].id' | sed 's/"//g'))

    adName=($(oci iam availability-domain list --query 'data[?contains ("name",`AD-1`)]|[0].name' | sed 's/"//g'))

You can quickly echo the values to confirm they both loaded properly:
![Screenshot of: echo command output][4]

The final piece of information required before creating resources is the Compartment OCID. In this example, our compartment name is **Training**. 

    compOcid=($(oci iam compartment list --query 'data[?name==`Training`]|[0].id' | sed 's/"//g'))

If you prefer to use the root compartment, the query looks a little different:

    compOcid=($(oci iam compartment list --query 'data[0]."compartment-id"' | sed 's/"//g'))

### Create the network resources
We are going to create a Virtual Cloud Network (VCN) with a single public subnet, a security list that allows ingress traffic on port 80 (to access the WordPress server), an Internet Gateway, and add a route for the Internet Gateway to the default route table.  Let's do this!

Create the VCN! Here we are using 10.0.0.0/16 as the network CIDR. You may opt for a different range...if you do, just make sure you change it accordingly in subsequent steps.
**Note** Because we are loading specific output directly to an environment variable, the command will return nothing to the screen unless there is an error.

    vcnOcid=($(oci network vcn create --cidr-block 10.0.0.0/16 -c $compOcid --display-name ContainerInstance-VCN --dns-label cidemovcn --query 'data.id' | sed 's/"/g'))

Create the security list. When we create the subnet it expects an array of security list IDs, so we'll go ahead and store the array in the variable.

    seclistOcid=('["'$(oci network security-list create --display-name PubSub1 --compartment-id $compOcid --vcn-id $vcnOcid --egress-security-rules  '[{"destination": "0.0.0.0/0", "destination-type": "CIDR_BLOCK", "protocol": "all", "isStateless": false}]' --ingress-security-rules '[{"source": "0.0.0.0/0", "source-type": "CIDR_BLOCK", "protocol": 6, "isStateless": false, "tcp-options": {"destination-port-range": {"max": 80, "min": 80}}}]' --query 'data.id'  | sed 's/"//g')'"]')

Create the internet gateway, obtain the id of the default VCN route table, and add a new route to the default route to said route table.

    igwId=($(oci network internet-gateway create -c $compOcid --is-enabled true --vcn-id $vcnOcid --display-name CIDemoIGW --query 'data.id'  | sed s'/[\[",]//g' | sed -e 's/\]//g'))

    rtId=($(oci network route-table list -c $compOcid --vcn-id $vcnOcid --query 'data[*].id'  | sed s'/[\[",]//g' | sed -e 's/\]//g'))

    oci network route-table update --rt-id $rtId --route-rules '[{"cidrBlock":"0.0.0.0/0","networkEntityId":"'$igwId'"}]'  

The final command will output the results of the action:
![Screenshot of: Route table update command][5]

Now just create the subnet where the Container Instance will be deployed...easy as that!

    pubsubId=($(oci network subnet create --cidr-block 10.0.10.0/24 -c $compOcid --vcn-id $vcnOcid --security-list-ids $seclistOcid --query 'data.id' | sed 's/"//g'))

### Container Instance Resources

Now that all of the network resources are in place, we're about ready to create the Container Instance resources. Before we just jump right in, however, lets take a look at some of the command parameters. The container instance configuration requires details about the core component, the network, and specifics of each container you intend to run. Deploying WordPress and a database will require two separate containers.

The **containers** parameter requires a fair amount of JSON. Be careful here because a simple typo could have you running in circles for hours. Later on we'll talk about *json input* for now, let's just see what we're working with. (do not run this code snippet by itself)

    ['{"displayName":"AppContainer","environmentVariables":{"WORDPRESS_DB_HOST":"127.0.0.1","WORDPRESS_DB_NAME":"wordpress","WORDPRESS_DB_PASSWORD":"wordpress","WORDPRESS_DB_USER":"wordpress"},"imageUrl":"docker.io/library/wordpress:latest","resourceConfig":{"memoryLimitInGBs":8,"vcpusLimit":1.5}},{"displayName":"DbContainer","environmentVariables":{"MYSQL_ROOT_PASSWORD":"wordpressonmysql","MYSQL_DATABASE":"wordpress","MYSQL_USER":"wordpress","MYSQL_PASSWORD":"wordpress"},"imageUrl":"docker.io/library/mysql:8.0.31","arguments": ["--default-authentication-plugin=mysql_native_password"],"resourceConfig":{"memoryLimitInGBs":8,"vcpusLimit":1.5}}']

Contained within the [] array are two separate container configurations. The first is going to grab the latest WordPress image from DockerHub, allocate resource limitations on the individal container (so it doesn't overrun the other container), and pass environment variables used for app configuration. The second configuration pulls v8.0.31 of the MySQL image, sets environment variables and resource limits again, and passes a runtime argument. Using the argument here will override the MySQL container's **ENTRYPOINT** argument and enables the database password authentication plugin.

The next parameter to keep in mind is **shape-config** where you define the amount of memory and number of OCPUs allocated to the underlying infrastruture. For optimal performance, ensure the combined total of container resource limitations does not exceed the allocations in shape-config.

    {"memoryInGBs":16,"ocpus":4}

And finally, the network configuratino, or **vnics** parameter. Notice again the values contained within an array. You may opt to attach multiple VNICs to your container instance. For this go, we'll just use a single VNIC. Provide a display name and subnet ID, and thats it!

    ['{"displayName": "CLI-ContainerInstance-Demo","sunetId":"'$pubsubId'"}']

Now put it all together with the *oci container-instances container-instance create* command and...make it so!

    oci container-instances container-instance create --display-name CLI-ContainerInstance-Demo --availability-domain $adName --compartment-id ocid1.compartment.oc1..aaaaaaaav4x6vgcs757ijx7nwyun773mqqlq3p5xmictf2xfnc6k7z25pu3q --containers ['{"displayName":"AppContainer","environmentVariables":{"WORDPRESS_DB_HOST":"127.0.0.1","WORDPRESS_DB_NAME":"wordpress","WORDPRESS_DB_PASSWORD":"wordpress","WORDPRESS_DB_USER":"wordpress"},"imageUrl":"docker.io/library/wordpress:latest","resourceConfig":{"memoryLimitInGBs":8,"vcpusLimit":1.5}},{"displayName":"DbContainer","environmentVariables":{"MYSQL_ROOT_PASSWORD":"wordpressonmysql","MYSQL_DATABASE":"wordpress","MYSQL_USER":"wordpress","MYSQL_PASSWORD":"wordpress"},"imageUrl":"docker.io/library/mysql:8.0.31","arguments": ["--default-authentication-plugin=mysql_native_password"],"resourceConfig":{"memoryLimitInGBs":8,"vcpusLimit":1.5}}'] --shape CI.Standard.E4.Flex --shape-config '{"memoryInGBs":16,"ocpus":4}' --vnics ['{"displayName": "CLI-ContainerInstance-Demo","subnetId":"'$pubsubId'"}']

The result of a successful execution will be about a page and a half of JSON output.  All the details about the resource just created.
![Screenshot of: JSON command output][6]

If you look near the end of the output you'll find a section for the *vnics* - and likely you'll find the value of the vnic-id to be null.  Don't fret! It takes a few seconds to provision that particular item.  And as luck would have it, we can find it easily.

![Screenshot of: Null vnic id value][7]

In the JSON output from the command above, locate the **id** for the container instance and copy it (or store it in an environment variable). Then run:

    oci container-instances --container-instance get --container-instance-id <the id you coiped above>

Now in the output you'll see an **id** for the vnic.
![Screenshot of: Valid vnic id value][8] 

Copy that and use it to run one more command:

    oci network vnic get --vnic-id <your vnic id>

The output of the command will have the details of the VNIC, including the Public IP address. Copy that, navigate to it in a web browser and you should see the WordPress setup page.



[1]: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
[2]: assets/ci-automation-cli-01.png
[3]: https://jmespath.org/
[4]: assets/ci-automation-cli-02.png
[5]: assets/ci-automation-cli-03.png
[6]: assets/ci-automation-cli-04.png
[7]: assets/ci-automation-cli-05.png
[8]: assets/ci-automation-cli-06.png