---
title: HeatWave on AWS Metrics and Performance Tools
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
description: A quick overview of the performance and metrics console windows in MySQL HeatWave on AWS.
author: Victor Agreda
mrm: WWMK220224P00058
---
As you’re working with your data, you’ll want to check out the performance of MySQL HeatWave on AWS, and we provide a number of metrics for you to examine.

### HeatWave Cluster Workspaces

{% imgx assets/hwaws-query_already_run-devrel0622.png %}

Above, we see the Workspaces tab in the Console, having just run a query. While we see a memory snapshot, we can go deeper in the Performance tab.  

### Performance

{% imgx assets/hw_performance_monitoring-devrel0622.png %}

Here’s the good stuff! Not only can you see performance per node, you can see the size of the dataset, the data dictionary, and if you click on Workload on the left side, you’ll see duration each step of the query took, and when queries have taken place.  

{% imgx assets/hw_performance_monitoring_03-devrel0622.png %}

Clicking back on Cluster and scrolling down, we can see metrics related to the VM itself, including memory and connection usage, CPU, and so on. If you’re keen on squeezing every drop of performance that you can out of HeatWave on AWS, we got you.  

{% imgx assets/hw_performance_monitoring_02-devrel0622.png %}

Want to know more? Join the discussion in our [public Slack channel](https://bit.ly/devrel_slack)!
