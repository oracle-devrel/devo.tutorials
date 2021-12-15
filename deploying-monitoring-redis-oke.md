---
title: Deploying and monitoring a Redis cluster to Oracle Container Engine (OKE)
parent: [tutorials]
thumbnail: assets/redis-dashboard.png
tags: [backend, oci]
date: 2021-12-15 13:34
description: Redis, Prometheus, OKE, oh my!
MRM: WWMK211213P00053
ali-mukadam:
  name: Ali Mukadam
  home: https://lmukadam.medium.com
  bio: |-
    Technical Director, Asia Pacific Center of Excellence.
    For the past 16 years, Ali has held technical presales, architect and industry consulting roles in BEA Systems and Oracle across Asia Pacific, focusing on middleware and application development. Although he pretends to be Thor, his real areas of expertise are Application Development, Integration, SOA (Service Oriented Architecture) and BPM (Business Process Management). An early and worthy Docker and Kubernetes adopter, Ali also leads a few open source projects (namely [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke)) aimed at facilitating the adoption of Kubernetes and other cloud native technologies on Oracle Cloud Infrastructure.
  linkedin: alimukadam
---
In the [previous post](https://medium.com/@lmukadam/extending-terraform-oke-with-a-helm-chart-a51ae0df29d4), we added a simple extension to the [terraform-oci-oke project](https://github.com/oracle-terraform-modules/terraform-oci-oke) so that it uses the [Redis helm chart](https://github.com/helm/charts/tree/master/stable/redis) to deploy a Redis cluster on Kubernetes

In this post, we'll do something more ambitious:

* Deploy a Redis Cluster as in the previous post
* Monitor the Redis cluster with Prometheus
* Populate the Redis cluster with existing data using Redis Mass Insertion
* Visualize the mass insertion process with Grafana

For the sake of convenience, we'll do a manual deployment of Prometheus and Redis. However, if you are using the terraform-oci-oke module (or any Kubernetes cluster for that matter), you can achieve the same result by using the helm provider as described in the previous post.

## Prerequisites

This tutorial requires an account with Oracle Cloud Infrastructure (OCI). If you don't yet have an OCI account, you can quickly sign up for one today by registering for an [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/#always-free) account. 

Afterwards, check [developer.oracle.com](https://developer.oracle.com) for more developer content.

## Deploy Prometheus Operator

Let's create a namespace for Prometheus:

```console
kubectl create namespace monitoring
```

If you are using the terraform-oci-oke module and have provisioned the bastion host, helm is already installed and pre-configured for you. Just login to the bastion and deploy the Prometheus operator:

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

Setting `serviceMonitorSelectorNilUsesHelmValues` to false ensures that all ServiceMonitors will be selected.

Get a list of pods and identify the Prometheus pods:

```console
kubectl -n monitoring get pods | grep prometheusalertmanager-prom-operator-prometheus-o-alertmanager-0   2/2     Running   0          18s                                                        
prom-operator-prometheus-node-exporter-9xhzr             1/1     Running   0          24s                                                        
prom-operator-prometheus-node-exporter-qtbvv             1/1     Running   0          24s                                                        
prom-operator-prometheus-node-exporter-wjbfp             1/1     Running   0          24s                                                        
prom-operator-prometheus-o-operator-79ff98787f-4t4k7     1/1     Running   0          23s                                                        
prometheus-prom-operator-prometheus-o-prometheus-0       3/3     Running   1          11s
```

On another terminal, set your local `KUBECONFIG` environment variable and run `kubectl port-forward `locally to access the Prometheus Expression Browser:

```console
export KUBECONFIG=generated/kubeconfigkubectl -n monitoring port-forward prometheus-prom-operator-prometheus-o-prometheus-0 9090:9090
```

Open your browser and access the Prometheus Expression Browser to verify the targets at http://localhost:9090/targets

{% imgx assets/redis-prometheus-targets.png  "Prometheus targets" %}

### Configuring Grafana

Next, we want to verify that Grafana has been configured properly and already has Prometheus as a datasource. Get a list of pods and identify the Grafana pods:

```console
kubectl -n monitoring get pods | grep grafanaprom-operator-grafana-77cdf86d94-m8pv5 2/2     Running   0          57s
```

Run kubectl port-forward locally to access Grafana:

```console
kubectl -n monitoring port-forward prom-operator-grafana-77cdf86d94-m8pv5 3000:3000
```

Access Grafana by pointing your browser to http://localhost:3000

Login with admin/prom-operator (default username and password if you have not changed them). You should be able to see the default Kubernetes dashboards.

## Deploy Redis Cluster

Create a namespace for redis:

```console
kubectl create namespace redis
```

Use helm to deploy the Redis cluster:

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

Access the Prometheus Expression Browser again and verify that Redis is now listed as one of the targets:

{% imgx assets/redis-prometheus-targets-updated.png  "Prometheus now with Redis target" %}

## Import Redis Dashboard for Grafana

Login into Grafana again as above and click **+** on the left menu to import a dashboard and enter the dashboard id `2751` in the Grafana.com dashboard field:

{% imgx assets/redis-import-grafana.png  "Import screen in Grafana" %}

After the dashboard is loaded, select the Prometheus datasource:

{% imgx assets/redis-grafana-imported.png  "Grafana with Prometheus loaded" %}

Click **Import**. You should now have a functioning Redis dashboard in Grafana.

{% imgx assets/redis-dashboard.png  "A functioning Redis dashboard in Grafana" %}

### Mass Insert Data into Redis
Let’s now do a mass insertion of data into Redis. I found this neat gem to load a csv file into redis.

Given a csv file of the following format:

```console
id, first name, age, gender, nickname, salary
1, John Smith, 40, Male, John, 10000
2, Marco Polo, 43, Male, Marco, 10000
….
1999999, Tom Cruse, 50, Male, Tom, 10001
```

The following command can be used to import that csv file into Redis:

```console
awk -F, 'NR > 1{ print "SET", "\"employee_"$1"\"", "\""$0"\"" }' file.csv | redis-cli --pipe
```

First, we have to generate the dataset. We will be using the mimesis package:

```console
pip install mimesis
```

And we will adapt the schema a little bit so we can make use of whatever mimesis provides to create a csv file using Python:

```console
import csvfrom mimesis import Personfrom mimesis.enums import Genderen = Person('en')with open('file.csv',mode='w') as csv_file:field_names = ['id', 'full name', 'age', 'gender', 'username', 'weight']writer = csv.DictWriter(csv_file, fieldnames=field_names)writer.writeheader()for n in range(100000):writer.writerow({'id': str(n), 'first name': en.full_name(), 'age': str(en.age()), 'gender': en.gender(), 'username':en.username(), 'weight':str(en.weight())})
```

Run the Python script to generate the data:

```console
python names.py
```

This will create a file.csv in the current directory. You can [configure a PersistentVolume](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/) to store and load the data but for the purpose of this exercise, we'll do a quick hack by installing redis in the bastion:

```console
sudo yum install redis -y
```

This will allow us to use the redis-cli from the bastion where we have generated/uploaded the file.csv.

On the bastion, get a list of Redis pods:

```console
kubectl -n redis get podsNAME                             READY   STATUS    RESTARTS   AGE                                                                                
redis-master-0                   1/1     Running   0          156m                                                                               
redis-metrics-794db76ff7-xmd2q   1/1     Running   0          156m                                                                               
redis-slave-7fd8b55f7-25w8d      1/1     Running   1          156m                                                                               
redis-slave-7fd8b55f7-hvhmc      1/1     Running   1          156m                                                                               
redis-slave-7fd8b55f7-mjq8q      1/1     Running   1          156m
```

Afterwards, use port-forward to so you can access it using the redis-cli:

```console
k -n redis port-forward redis-master-0 6379:6379
Forwarding from 127.0.0.1:6379 -> 6379
```

Open a new terminal, login into the bastion and obtain the Redis password:

```console
export REDIS_PASSWORD=$(kubectl get secret --namespace redis redis -o jsonpath="{.data.redis-password}" | base64 --decode)
```

Do a quick test to see you can connect to Redis:

```console
redis-cli -a $REDIS_PASSWORD127.0.0.1:6379> ping                                                                                                                                                        
PONG                                                                                                                                                                        
127.0.0.1:6379>
```

Before we import the csv, access Grafana (http://localhost:3000) as described above by opening a third terminal and running kubectl port-forward locally. Browse to the Redis Dashboard and set the refresh to every 5 seconds:

```console
kubectl -n monitoring port-forward prom-operator-grafana-77cdf86d94-m8pv5 3000:3000
```

Now import the csv file as follows:

```console
awk -F, 'NR > 1{ print "SET", "\"employee_"$1"\"", "\""$0"\"" }' 
file.csv | redis-cli -a $REDIS_PASSWORD --pipeAll data transferred. Waiting for the last reply...                                                                                                                   
Last reply received from server.                                                                                                                                      
errors: 0, replies: 1000000
```

You may want to watch the Redis dashboard in Grafana. You can see the immediate jump in Network IO, the number of items in the DB as well as the amount of memory used.

{% imgx assets/redis-dashboard-after-insertion.png  "Redis Dashboard after mass insertion" %}

While we installed the Prometheus Operator and Redis Cluster manually using the cli, you can also achieve that using the Terraform helm provider. As you are enabling monitoring on Redis, you need to ensure the relevant CRDs are created. When you are doing that manually and in the order above, this is done for you.

However, when you use Terraform to do the provisioning, you will need to explicitly set the order as follows:

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

After performing these steps, you'll have ensured that the prometheus-operator release is created first along with the necessary CRDs that the redis release will need (like Alertmanager, Prometheus, PrometheusRule, ServiceMonitor) for Prometheus to be able to monitor the Redis cluster.