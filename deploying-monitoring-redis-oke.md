---
title: Deploying and monitoring a Redis cluster to Oracle Container Engine (OKE)
parent:
- tutorials
thumbnail: assets/redis-dashboard.png
tags:
- back-end
- oci
date: 2021-12-15 13:34
description: Redis, Prometheus, OKE, oh my!
MRM: WWMK211213P00053
author: ali-mukadam
xredirect: https://developer.oracle.com/tutorials/deploying-monitoring-redis-oke/
---
{% slides %}
In the [previous post](https://medium.com/@lmukadam/extending-terraform-oke-with-a-helm-chart-a51ae0df29d4), you learned how to add a simple extension to the [terraform-oci-oke project](https://github.com/oracle-terraform-modules/terraform-oci-oke) so that it uses the [Redis helm chart](https://github.com/helm/charts/tree/master/stable/redis) to deploy a Redis cluster on Kubernetes.  

In the current tutorial, you'll build on this background by exploring how set up Promtheus to monitor your Redis cluster.

Key tasks include how to:

* Deploy a Redis cluster
* Monitor the Redis cluster with Prometheus
* Populate the Redis cluster with existing data using Redis Mass Insertion
* Visualize the mass-insertion process with Grafana
* Use the Terraform helm provider as an alternate deployment and monitoring procedure

For additional information, see:

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)

## Before you begin

### Requirements

* An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* Access to Grafana.
* Access to helm.

## Deploy Prometheus Operator

1. To get things started, open a terminal and create a namespace for Prometheus:

   ```console
   kubectl create namespace monitoring
   ```

1. If you are using the `terraform-oci-oke` module and have provisioned the bastion host, helm is already installed and pre-configured for you! Just login to the bastion host and deploy the Prometheus operator:

   ```console
   helm install --namespace monitoring \
   stable/prometheus-operator \
   --name prom-operator \
   --set kubeDns.enabled=true \
   --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
   --set coreDns.enabled=false \
   --set kubeControllerManager.enabled=false \
   --set kubeEtcd.enabled=false \
   --set kubeScheduler.enabled=false
   ```

   By setting `serviceMonitorSelectorNilUsesHelmValues` to false you ensure that all ServiceMonitors will be selected.

1. Get a list of pods and identify the ones associated with Prometheus:

   ```console
   kubectl -n monitoring get pods | grep prometheus
   ```

   The system will echo something similar to the following:

   ```console
   alertmanager-prom-operator-prometheus-o-alertmanager-0   2/2     
   Running   0          18s                                                        
   prom-operator-prometheus-node-exporter-9xhzr             1/1     
   Running   0          24s                                                        
   prom-operator-prometheus-node-exporter-qtbvv             1/1     
   Running   0          24s                                                        
   prom-operator-prometheus-node-exporter-wjbfp             1/1     
   Running   0          24s                                                        
   prom-operator-prometheus-o-operator-79ff98787f-4t4k7     1/1     
   Running   0          23s                                                        
   prometheus-prom-operator-prometheus-o-prometheus-0       3/3     
   Running   1          11s
   ```

1. In another terminal, set your local `KUBECONFIG` environment variable and run `kubectl port-forward` locally to access the Prometheus Expression Browser:

   ```console
   export KUBECONFIG=generated/kubeconfig

   kubectl -n monitoring port-forward prometheus-prom-operator-
   prometheus-o-prometheus-0 9090:9090
   ```

1. To verify the targets, open your browser and access the Prometheus Expression Browser at `http://localhost:9090/targets`

   {% imgx assets/redis-prometheus-targets.png  "Prometheus targets" %}

### Configure Grafana

Next, you'll verify that Grafana has been configured properly and already has Prometheus as a datasource.  With this set, you'll be able monitor your Redis installation once it's been deployed.

1. In a console, get a list of pods and identify the ones associated with Grafana:

   ```console
   kubectl -n monitoring get pods | grep grafana
   ```

   This will echo something similiar to the following:

   ```console
   grafanaprom-operator-grafana-77cdf86d94-m8pv5 2/2     Running   0          57s
   ```

1. Run `kubectl port-forward` locally to access Grafana:

   ```console
   kubectl -n monitoring port-forward prom-operator-grafana-77cdf86d94-m8pv5 3000:3000
   ```

1. Access Grafana by connecting to port 30 on your browser (`http://localhost:3000`).

   Login with admin/prom-operator. Use the default username and password if you have not yet changed them. Once you've logged in, you should be able to see the default Kubernetes dashboards.

## Deploy Redis Cluster

1. Create a namespace for Redis:

   ```console
   kubectl create namespace redis
   ```

1. Use helm to deploy the Redis cluster:

   ```console
   helm install --namespace redis \
   stable/redis \
   --name redis \
   --set cluster.enabled=true \
   --set cluster.slaveCount=3 \
   --set master.persistence.size=50Gi \
   --set slave.persistence.size=50Gi \
   --set metrics.enabled=true \
   --set metrics.serviceMonitor.enabled=true \
   --set metrics.serviceMonitor.namespace=monitoring
   ```

1. Access the Prometheus Expression Browser again (`http://localhost:9090/targets`) and verify that Redis is now listed as one of the targets:

   {% imgx assets/redis-prometheus-targets-updated.png  "Prometheus now with Redis target" %}

## Import Redis Dashboard for Grafana

1. Login to Grafana (`http://localhost:3000`).
2. Select **+** on the left-hand menu to import a dashboard.
3. Enter the dashboard id `2751` in the Grafana.com dashboard field:

   {% imgx assets/redis-import-grafana.png  "Import screen in Grafana" %}

4. After the dashboard is loaded, select the Prometheus datasource:

   {% imgx assets/redis-grafana-imported.png  "Grafana with Prometheus loaded" %}

5. Select **Import**. You should now have a functioning Redis dashboard in Grafana!

   {% imgx assets/redis-dashboard.png  "A functioning Redis dashboard in Grafana" %}

### Mass-insert data into Redis

In this step, you'll learn a neat little time saver that will allow you to import large amounts of data into Redis using a csv file.  

#### Format your initial `files.csv`

1. First, make sure that your `file.csv` data file is set up with the same format as the one shown below:

   ```console
   id, first name, age, gender, nickname, salary
   1, John Smith, 40, Male, John, 10000
   2, Marco Polo, 43, Male, Marco, 10000
   …
   1999999, Tom Cruse, 50, Male, Tom, 10001
   ```

1. To import your csv file into Redis, run the following command in your console:

   ```console
   awk -F, 'NR > 1{ print "SET", "\"employee_"$1"\"", "\""$0"\"" }' file.csv | redis-cli --pipe
   ```

#### Generate dataset with mimesis

In this part, you'll be using the mimesis package to create a dataset based on the information you provided in `file.csv`.

1. In a console, install mimesis:

   ```console
   pip install mimesis
   ```

2. Your initial dataset will need a little tweaking to be ready for use in Redis. So, in this part, you'll adapt the mimesis schema a little bit to create a new csv file using Python. Create a `names.py` file with the following content:

   ```python
   import csv

   from mimesis import Person

   from mimesis.enums import Gender

   en = Person('en')

   with open('file.csv',mode='w') as csv_file:

   field_names = ['id', 'full name', 'age', 'gender', 'username', 'weight']

   writer = csv.DictWriter(csv_file, fieldnames=field_names)

   writer.writeheader()

   for n in range(100000):

   writer.writerow({'id': str(n), 'first name': en.full_name(), 'age': 
   str(en.age()), 'gender': en.gender(), 'username':en.username(),
   'weight':str(en.weight())})
   ```

3. In a console, run the Python script to generate the data:

   ```console
   python names.py
   ```

   This will create a `file.csv` in the current directory. You can [configure a PersistentVolume](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/) to store and load the data, but for the purpose of this tutorial, you'll do a quick hack by installing Redis on the bastion.

#### Install and configure Redis on the bastion

1. In your console, run:

   ```console
   sudo yum install redis -y
   ```

   This will allow you to use the redis-cli from the bastion where you've generated/uploaded your `file.csv`.

1. On the bastion, get a list of Redis pods:

   ```console
   kubectl -n redis get pods
   ```

   The system will echo something similar to the following:

   ```console
                                    NAME   READY    STATUS    RESTARTS   AGE                                                                                
   redis-master-0                   1/1     Running   0          156m                                                                               
   redis-metrics-794db76ff7-xmd2q   1/1     Running   0          156m                                                                               
   redis-slave-7fd8b55f7-25w8d      1/1     Running   1          156m                                                                               
   redis-slave-7fd8b55f7-hvhmc      1/1     Running   1          156m                                                                               
   redis-slave-7fd8b55f7-mjq8q      1/1     Running   1          156m
   ```

1. Afterwards, use `port-forward` so you can access the Redis master using the redis-cli:

   ```console
   k -n redis port-forward redis-master-0 6379:6379
   ```

   Redis wil echo something similar to the following:

   ```console
   Forwarding from 127.0.0.1:6379 -> 6379
   ```

1. Open a new terminal, login to the bastion and obtain the Redis password:

   ```console
   export REDIS_PASSWORD=$(kubectl get secret --namespace redis redis -o jsonpath="{.data.redis-password}" | base64 --decode)
   ```

   Just as a check, do a quick test to see if you can connect to Redis. In a cosole, run:

   ```console
   redis-cli -a $REDIS_PASSWORD127.0.0.1:6379> 
   ```

   Redis will echo with something similar to the following:

   ```console
   ping                                                                                                                                                        
   PONG                                                                                                                                                                        
   127.0.0.1:6379>
   ```

#### Prep Grafana for csv import

Before you import your csv, you'll first need to access Grafana (`http://localhost:3000`).

1. In a new terminal, run `kubectl port-forward` locally. Also, make sure that you navigate to the Redis Dashboard and set the refresh to every 5 seconds:

   ```console
   kubectl -n monitoring port-forward prom-operator-grafana-77cdf86d94-m8pv5 3000:3000
   ```

2. Import your csv:

   ```console
   awk -F, 'NR > 1{ print "SET", "\"employee_"$1"\"", "\""$0"\"" }' file.csv | redis-cli -a $REDIS_PASSWORD --pipe
   ```

   The system will echo with something similar to:

   ```console
   All data transferred. Waiting for the last reply...                                                                                      
   Last reply received from server.
        
   errors: 0, replies: 1000000
   ```

   The Redis cluster is now deployed and actively being monitored by Prometheus!

   At this point, you may want to watch the Redis dashboard in Grafana. You can see the immediate jump in Network IO, the number of items in the DB as well as the amount of memory used.

   {% imgx assets/redis-dashboard-after-insertion.png  "Redis Dashboard after mass insertion" %}

## Installing the Prometheus Operator and Redis cluster using the Terraform helm provider

Earlier in this tutorial, you learned how to manually install the Prometheus Operator and Redis Cluster through the cli, but this isn't the only option available to you. You can also achieve the same results using the Terraform helm provider, but there are a few important things to keep in mind while doing so.  

As you're enabling monitoring on Redis, you'll now need to ensure that the relevant custom resource definitions (CRDs) are created. Previously, the manual steps you performed made certain that the CRDs were created and in the proper order.  
However, when you use Terraform to do the provisioning, you'll need to explicitly set the order as follows:

```console
resource "helm_release" "prometheus-operator" {
   ...
   ...
   ...
}
  
resource "helm_release" "redis" {  

   depends_on = ["helm_release.prometheus-operator"]
   ...
   ...
   ...
}
```

Congratulations! After performing these steps, you've ensured that the prometheus-operator release is created first, along with all the necessary CRDs that the Redis release will need (like Alertmanager, Prometheus, PrometheusRule, and ServiceMonitor) for Prometheus to be able to monitor the Redis cluster.

## What's Next

You have successfully deployed a Redis cluser and enabled monitoring with Prometheus.

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

{% endslides %}
