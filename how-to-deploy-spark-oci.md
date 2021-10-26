---
title: How to Deploy Spark Standalone in Oracle Cloud (OCI)
parent: tutorials
tags:
- oci
- open-source
- spark
- java
- data-science
thumbnail: assets/apache_spark.png
date: 2021-09-30 01:00
description: A short walkthrough of setting up Spark and Hadoop in your OCI environment.
author: olivier
redirect_from: "/collections/tutorials/how-to-deploy-spark-oci/"
---
{% slides %}
The following walk-through guides you through the steps needed to set up your environment to run Spark and Hadoop in Oracle Cloud Infrastructure.

## Prerequisites

You have deployed a VM 2.1 or + with Oracle Linux 7.9 (OEL7) in Oracle Cloud Infrastructure (OCI).

* The installation of Oracle Linux 7.9 is using a JVM by default.
* You have access to root either directly or via sudo. By default in OCI, you are connected like "opc" user with sudo privilege.

```console
    [opc@xxx ~]$ java -version
    java version "1.8.0_281"
    Java(TM) SE Runtime Environment (build 1.8.0_281-b09)
    Java HotSpot(TM) 64-Bit Server VM (build 25.281-b09, mixed mode)
```

## Java Installation

The install is quite simple. It consists of setting up Java, installing Spark and Hadoop components and libraries. Lets start with setting up the Spark and Hadoop environment.

Download the last version of JDK 1.8 because Hadoop 2.X is using this Java version.
```console
rpm -ivh /home/opc/jdk-8u271-linux-x64.rpm
```

Check Java Version.
```console
java -version
```

## Spark and Hadoop Setup

The next step is to install Spark and Hadoop environment.

First, choose the version of Spark and Hadoop you want to install. Then, download the version you want to install:

### Download Spark 2.4.5 for Hadoop 2.7
```console 
cd /home/opc
wget http://apache.uvigo.es/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz
```

### Download Spark 2.4.7 for Hadoop 2.7
```console
wget http://apache.uvigo.es/spark/spark-2.4.7/spark-2.4.7-bin-hadoop2.7.tgz
```

### Download Spark 3.1.1 for Hadoop 3.2
```console
wget http://apache.uvigo.es/spark/spark-3.1.1/spark-3.1.1-bin-hadoop3.2.tgz
```

### Install the Spark and Hadoop Version

Install the Spark and Hadoop Version choosen in the directory "/opt".
```console
sudo -i
cd /opt
tar -zxvf /home/opc/spark-2.4.5-bin-hadoop2.7.tgz
#or 
tar -zxvf /home/opc/spark-2.4.7-bin-hadoop2.7.tgz
#or
tar -zxvf /home/opc/spark-3.1.1-bin-hadoop3.2.tgz
```

## Install PySpark in Python3 environment
```console 
/opt/Python-3.7.6/bin/pip3 install 'pyspark=2.4.7'
/opt/Python-3.7.6/bin/pip3 install findspark
```

Next we shall create a virtual environment and enable it.

### Modify your environment to use this Spark and Hadoop Version

Add to ".bashrc" for the user "opc" the following lines:
```console
# Add by %OP%
export PYTHONHOME=/opt/anaconda3
export PATH=$PYTHONHOME/bin:$PYTHONHOME/condabin:$PATH

# SPARK ENV
#export JAVA_HOME=$(/usr/libexec/java_home)
export SPARK_HOME=/opt/spark-2.4.5-bin-hadoop2.7
export PATH=$SPARK_HOME/bin:$PATH
export PYSPARK_PYTHON=python3

export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'
```

## Test your Spark and Hadoop Environment

If you're running directly on a virtual machine and have a browser installed it should take you directly into the jupyter environment. Connect to your "[http://xxx.xxx.xxx.xxx:8001/](http://xxx.xxx.xxx.xxx:8001/)".

And upload the next notebooks:

* [Notebook test findspark](https://github.com/operard/oracle-cloud-tutorial/blob/main/notebooks/Test_findSpark.ipynb).
* [Notebook test Pyspark](https://github.com/operard/oracle-cloud-tutorial/blob/main/notebooks/Test%20PySpark.ipynb).
* [Notebook test Pyspark with Mysql](https://github.com/operard/oracle-cloud-tutorial/blob/main/notebooks/Test_PySpark_Mysql.ipynb).
{% endslides %}
