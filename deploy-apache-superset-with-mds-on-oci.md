---
title: Deploy Apache Superset with MySQL Database Service on Oracle Cloud Infrastructure
parent: tutorials
tags:
- data-management
- front-end
- mysql
- oci
- analytics
- bi
thumbnail: assets/mds_superset/mds_superset.webp
date: 2021-10-20 09:18
description: Deploy Open Source BI, reporting tool on OCI using MySQL Databse Service.
categories:
- cloudapps
author: 
  name: lefred
  home: https://lefred.be/
  linkedin: freddescamps
  twitter: lefred
  github: lefred
---

It's easy to deploy solutions on OCI (Oracle Cloud Infrastructure) using Terraform and Resource Manager’s Stack. I’ve published several resources available on [this page](https://lefred.be/deploy-to-oci/).

Today we will see how easy it is to deploy Apache Superset on OCI using MySQL Data Service.

Apache Superset is an open source BI, Reporting, Charting tool that competes with Tableau, Looker, etc.  For a list of companies that have deployed Superset, see [this page](https://github.com/apache/superset/blob/master/RESOURCES/INTHEWILD.md).

Superset is loaded with options that make it easy for users of all skill sets to explore and visualize their data, from simple line charts to highly detailed geospatial charts.

For a gallery of available charts, [go here](https://superset.apache.org/gallery).

MySQL can be used as a backend to store the needed information related to the platform (users, settings, dashboards, …) , this represents 55 tables. MySQL can also be used as source for the data visualization.

## Preparation

The easiest way to install Apache Superset on OCI is to click this button:

[{% imgx aligncenter assets/mds_superset/deploy_on_oci.svg %}](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/lefred/oci-superset-mds/releases/download/v1.0.0/stack_superset_mds.zip)

You can also use the Terraform modules available on [this GitHub repo](https://github.com/lefred/oci-superset-mds).

If you use the Red Pill (by clicking on the image above), you will redirected to OCI’s Dashboard Resource Manager Stack:

{% imgx aligncenter assets/mds_superset/01.webp %}

You need to accept the Oracle Terms of Use and then the stack’s configuration will be loaded.

Check that you are in the desired compartment and then click Next:

{% imgx aligncenter assets/mds_superset/02.webp %}

You will be redirected to the second screen, for variables configuration. Some variables are mandatory and self explanatory:

{% imgx aligncenter assets/mds_superset/03.webp %}

You also have the possibility to choose HA for MySQL DB instance, to load superset sample data (the deployment is then longer) and the Shape Selection. If you plan to use HeatWave on that instance, I recommend you to directly choose a HeatWave compatible Shape (default):

{% imgx aligncenter assets/mds_superset/04.webp %}

If you already have a VNC and/or a MDS instance you want to use, you can also use the existing OCI infrastructure you have previously deployed:

{% imgx aligncenter assets/mds_superset/05.webp %}

You need the OCIDs of all the existing resources.

When you have performed all the selection you need, you can continue the process… Usually default should be good, you only require to add the MDS admin’s password and if this is the first Apache Superset deployment, I also recommend to load the sample data.

{% imgx aligncenter assets/mds_superset/06.webp %}

## Deployment

The deployment will start, with the sample data load, and this takes approximately 30 minutes…

{% imgx aligncenter assets/mds_superset/07.webp %}

When ready, the status will change:

{% imgx aligncenter assets/mds_superset/08.webp %}

At the end of the logs section we already have the output variables we need to use to join our deployment:

{% imgx aligncenter assets/mds_superset/09.webp %}

And we can retrieve that info in the Outputs section too:

{% imgx aligncenter assets/mds_superset/10.webp %}

## Apache Superset

To reach the Apache Superset we just deployed, we paste the superset_public_ip‘s value on a browser and we use the superset_admin_username and superset_admin_password to connect:

{% imgx aligncenter assets/mds_superset/11.webp %}

{% imgx aligncenter assets/mds_superset/12.webp %}

{% imgx aligncenter assets/mds_superset/13.webp %}

Congratulations! Apache Superset is available and working on OCI with MySQL Database Service.

If you want to connect to another MDS instance that you would use as a data source for some visualization graphs, you will need to be able to reach it (usually on the same VCN’s subnet or having routing between different VCN’s) and you must use the following syntax, as the MySQL Connector installed is mysql-connector-python:

```
mysql+mysqlconnector://<login>:<password>@<mds IP>:3306/<schema_name>
```

{% imgx aligncenter assets/mds_superset/14.webp %}

{% imgx aligncenter assets/mds_superset/15.webp %}

{% imgx aligncenter assets/mds_superset/16.webp %}

{% imgx aligncenter assets/mds_superset/17.webp %}

## Conclusion

Using OCI’s Resource Manager Stack (or Terraform) it is very easy to deploy Apache Superset on OCI using MySQL Database Service (MDS) as a backend.

In a few minutes you have an Open Source Data Visualization solution that you can use with your MySQL Database Service instances.

Enjoy OCI, MySQL and MySQL Database Service!
