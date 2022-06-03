---
title: Deploying Cassandra in Oracle Linux
mrm: WWMK211130P00067
parent:
- tutorials
tags:
- open-source
- oci
- back-end
categories:
- modernize
date: 2021-12-03 19:45
description: Cassandra, an open-source NoSQL database, plays well with Oracle Cloud
  Infrastructure. Let Olivier show you how to configure it.
author: Olivier Francois Xavier Perard
xredirect: https://developer.oracle.com/tutorials/cassandra-cloud/
---
[Apache Cassandra] is a scalable, open-source NoSQL distributed database known for its high availability and compatibility with Oracle Cloud Infrastructure (OCI).  

This quick start guides you through configuring your environment to run Cassandra in OCI.  

It's fun, we promise!  

For more information, see:  

* [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm)

## Prerequisites

In order to successfully complete this tutorial, you will need to:  

* Have deployed a VM 2.1 with Oracle Linux 7.9 (OEL7) in OCI.
* Have installed Oracle Linux 7.9 with pip3.6 by default.
* Installed Python 3.6 or higher.
* Have access to root, either directly or by using sudo.  
  By default in OCI, you are connected like an "opc" user with sudo privilege.
* Have an Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).

## Getting started

Let's start with setting up the Python environment.

### Python setup

By default, OEL7 runs Python 3. In order to prepare us for the JupyterLab installation later in the guide, we'll use pip to install virtualenv in this next section.

#### Install virtualenv

Virtualenv enables us to create isolated sandboxes to develop Python applications without running into module or library conflicts. It's also super easy to install:  

```console
sudo pip3.6 install virtualenv
```

With virtualenv installed, we can create a virtual environment and enable it.

#### Create an environment `myvirtualenv`

```conosle
virtualenv -p /usr/bin/python3 myvirtualenv
# Activate the env
source myvirtualenv/bin/activate
```

### List Python libraries in your environment

Running `pip3 list` will show which Python models we currently have installed:  

```console
(myvirtualenv) [opc@lab1 ~]$ pip3 list
```

Which should return output similar to:

```console
Package    Version
---------- -------
pip        21.1.3
setuptools 57.1.0
wheel      0.36.2
WARNING: You are using pip version 21.1.3; however, version 21.2.1 is available.
You should consider upgrading via the '/home/opc/myvirtualenv/bin/python -m pip install --upgrade pip' command.
```

#### Upgrade your pip environment for this virtual environment

```console
/home/opc/myvirtualenv/bin/python -m pip install --upgrade pip
```

## Jupyterlab setup

```console
pip3 install jupyterlab
```

### Install Python libraries for Machine Learning or ETL Process

```console
pip install pandas
pip install pandarallel
pip install dask
pip install seaborn
pip install matplotlib
pip install plotly

pip install -lxml==4.6.3
pip install selenium
pip install beautifulsoup4

pip install scikit-learn
```

#### Install additional Python libraries for Kafka and web server access

```console
pip install kafka-python (v2.0.0)
pip install Flask
pip install gunicorn
```

### Install extensions for JupyterLab environment

```console
pip install jupyter_contrib_nbextensions
jupyter contrib nbextension install --user
jupyter nbextension enable execute_time/ExecuteTime
```

## Configure JupyterLab like an OEL7 Linux service

Create a script to automatically instantiate and reboot JupyterLab with user `opc`:  

```console
vi /home/opc/launchjupyterlab.sh
```

### Script for `launchjupyterlab.sh`

Using the virtualenv, you can launch JupyterLab on a specific port (e.g., 8001) and listen via public IP:  

```console
#!/bin/bash

# Activate myvirtualenv Environment
source myvirtualenv/bin/activate

cd /home/opc

if [ "$1" = "start" ]
then
nohup jupyter-lab --ip=0.0.0.0 --port=8001 > ./nohup.log 2>&1 &
echo $! > /home/opc/jupyter.pid
else
kill $(cat /home/opc/jupyter.pid)
fi
```

Set the script to executable mode in order to be executed from the *jupyterlab* service:  

```console
chmod 777 /home/opc/launchjupyterlab.sh
```

### Connect to `root` user

```console
sudo -i
```

### Create a script to start/stop *jupyterlab* service

```console
vi /etc/systemd/system/jupyterlab.service
```

### Add code to launch the script `launchjupyterlab.sh` as an `oci` user

```console
[Unit]
Description=Service to start jupyterlab for opc
Documentation=
[Service]
User=opc
Group=opc
Type=forking
WorkingDirectory=/home/opc
ExecStart=/home/opc/launchjupyterlab.sh start
ExecStop=/home/opc/launchjupyterlab.sh stop
[Install]
WantedBy=multi-user.target
```

### Test *jupyterlab* service

```console
systemctl start jupyterlab
systemctl status jupyterlab
systemctl enable jupyterlab
```

## Reboot your machine for a final check

Home stretch!  

1. Reboot your machine to check if the JupyterLab script is enabled by default on port 8001.
2. Open port 8001 to your virtual machine VM 2.1 in order to access it using your Public IP:  

      ```console
      firewall-cmd  --permanent --zone=public --list-ports
      firewall-cmd --get-active-zones
      firewall-cmd --permanent --zone=public --add-port=8001/tcp
      firewall-cmd --reload
      ```

   >**Note:** If you're running directly on a virtual machine and have a browser installed, it should take you directly into the Jupyter environment.  
   >Connection on port 8001: `http://xxx.xxx.xxx.xxx:8001/`.
   {:.notice}

You should now see the next Python Web environment **JupyterLab**.

That's it! Enjoy using Cassandra with OCI.

## What's next

To explore more information about development with Oracle products:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

<!--- links -->

[OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm

[Apache Cassandra]: https://cassandra.apache.org/_/index.html