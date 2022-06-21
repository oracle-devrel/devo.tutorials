---
title: Using the AWS Migration Service with HeatWave on AWS with WordPress as an Example
parent:
	- tutorials
tags: 
	- mysql
	- database
	- heatwave
categories:
	- cloudapps
thumbnail: assets/a-mysqglhw-devrel0622-thmb001.png
date: 2022-06-16 17:00
description: A quick example of how you can move data over for use in MySQL HeatWave on AWS.
author: Victor Agreda
mrm: WWMK220224P00058
---
Now let’s try something really fun. Let’s say you’ve already got a database using Aurora or RDS, in our case we’ll use a WordPress database, and you want to migrate it to MySQL HeatWave on AWS.

First, we’ll need to have a MySQL DB System on HeatWave already, and a critical step is opening port 3306, shown below.

{% imgx assets/create-mysqldbsys-devrel0622.png %}

Great! Now let’s head over to AWS.

1. Log in to your AWS console, and use search for “DMS” — Database Migration Service, it’ll be the top result.

    {% imgx assets/awsdbs-migrationservice-search-devrel0622.png %}

2. Click Create replication instance.

    {% imgx assets/step2-create-replication-awshw-devrel0622.png %}

3. Fill out a Name, Amazon Resource Name (ARN), description. You may use whichever shape you like, but keep in mind performance:cost here. Engine version should be fine, as well as storage (unless you have a truly massive database, in which case adjust accordingly).

    {% imgx assets/arn-form-repinstance-awshw-devrel0622.png %}

4. For VPC, choose one you have previously set up with the appropriate access controls for development work. And make sure it is publicly accessible. For Multi AZ, we’ll use a single availability zone, dev or test workload.

    {% imgx assets/step4-vpcsetup-awshw-devrel0622.png %}

5. Click to open the Advanced security and network configurations. The subnet group will follow the VPC you chose above, and the availability zone should be US-East. The security groups should be populated with any you created earlier, ensuring ports are available (LINK TK to DOCS on this).

    {% imgx assets/step5-advanc-netsec-awshw-devrel0622.png %}

6. It will take a few minutes for the replication instance to spin up. Coffee time!

    {% imgx assets/step6-creating-instance-awshw-wpex-devrel0622.png %}

7. Once it’s ready, we’ll need to get the Public IP address for our endpoint. Go to the Endpoints section. On the right you’ll see a Create Endpoint button, click it.

    {% imgx assets/step7a-awsdms-endpoints-awshw-wpex-devrel0622.png %} {% imgx assets/step7b-create-endpoint-button-awshw-wpex-devrel0622.png %}

8. Select Source endpoint, and check Select RDS DB Instance. You should see the RDS Instance field populate with what’s available to you.

    {% imgx assets/step8-create-endpoint-awshw-wpex-devrel0622.png %}

9. For Endpoint configuration, you’ll have the identifier, ARN, and source engine pre-filled, but we want to provide the access to endpoint database information manually, so click that radio button. Then, enter the appropriate database information for the db you’re moving over.

    {% imgx assets/step9-endpoint-config-awshw-devrel0622.png %}

10. Then, you should be able to test the endpoint connection below.

     {% imgx assets/step10-testendpoint-awshw-wpex-devrel0622.png %}

11. Now, we’ll create a second endpoint as our destination.
To do this, we return to the MySQL HeatWave on AWS Console, and click MySQL DB Systems.

     I{% imgx assets/step11-mysql-dbsystems-onaws-awshw-wpex-devrel0622.png %}

     Then, click on the DB System you wish to use, and in Summary you will find the Host Name. Copy the string.

12. Go back to AWS console, and click to create another endpoint. Except this time we’ll create a Target endpoint! Naturally.

     {% imgx assets/step12-create-endpoint-aws-awshw-wpex-devrel0622.png %}

13. In Endpoint configuration, give it a name (identifier), choose MySQL under Target Engine. ARN is optional.

     {% imgx assets/step13-target-engin-awshw-wpex-devrel0622.png %}

14. Once again, we’ll provide access information manually. The server name is the host name you previously copied. Port is 3306. The username/password will match the one you created for the target database.

15. Now you have your endpoint, username/password, and can use this when creating a HeatWave on AWS cluster to connect a DB System and run queries. Refer to the HeatWave on AWS documentation for more.

NOTE: MySQL Shell is the recommended utility for exporting data from a source MySQL Server and importing it into a DB System on the MySQL HeatWave on AWS. MySQL Shell dump and load utilities are purpose- built for use with MySQL DB Systems. For more on running queries with HeatWave, please refer to the [MySQL documentation](https://dev.mysql.com/doc/heatwave/en/heatwave-running-queries.html).

Want to know more? Join the discussion in our [public Slack channel](https://bit.ly/devrel_slack)!
