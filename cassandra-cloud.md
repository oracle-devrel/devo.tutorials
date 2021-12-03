---
title: Deploying Cassandra in Oracle Linux
mrm: WWMK211130P00067
parent: [tutorials]
tags: [open-source, oci, backend]
categories: [modernize]
date: 2021-12-03 19:45
description:  Cassandra, an open-source NoSQL database, plays well with Oracle Cloud Infrastructure. Let Olivier show you how to configure it.
author: Olivier Francois Xavier Perard
---
This walk-through guides you through configuring your environment to run Cassandra in Oracle Cloud Infrastructure (OCI).

It's fun, we promise.

## Prerequisites

* You have deployed a VM 2.1 with Oracle Linux 7.9 (OEL7) in OCI.
* The installation of Oracle Linux 7.9 is using pip3.6 by default.
* Python 3.6 or higher is installed.
* You have access to root either directly or using sudo. By default in OCI, you are connected like an "opc" user with sudo privilege.

Let's start with setting up the Python environment.

## 1. Python Setup

By default, OEL7 runs Python 3. The first is to install `pip` and `virtualenv`.

### Install virtualenv

Virtualenv enables us to create isolated sandpits to develop Python applications without running into module or library conflicts. It's super easy to install.

```console
sudo pip3.6 install virtualenv
```

Next, we can create a virtual environment and enable it.

#### Create an environment "myvirtualenv"

```conosle
virtualenv -p /usr/bin/python3 myvirtualenv
# Activate the env
source myvirtualenv/bin/activate
```

### Check list of Python Libraries in your environment

Running the following command will show what Python models we have installed at this point.

```console
(myvirtualenv) [opc@lab1 ~]$ pip3 list
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

## 2. Jupyterlab Setup

```console
pip3 install jupyterlab
```

### Install Python Libraries for Machine Learning or ETL Process

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

#### Install other Python Libraries for Kafka Access and WEB Server Access

```console
pip install kafka-python (v2.0.0)
pip install Flask
pip install gunicorn
```

### Install extensions for Jupyterlab Environment

```console
pip install jupyter_contrib_nbextensions
jupyter contrib nbextension install --user
jupyter nbextension enable execute_time/ExecuteTime
```

## 3. Configure Jupyterlab like a OEL7 Linux Service

Create a script to instantiate automatically and reboot Jupyterlab with "opc" user.

```console
vi /home/opc/launchjupyterlab.sh
```

### Script for launchjupyterlab.sh

Using the virtualenv, you can launch Jupyterlab in a specific port (for example: 8001) and listen on public IP.

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

Set the script to executable mode in order to be executed from the Jupyterlab service.

```console
chmod 777 /home/opc/launchjupyterlab.sh
```

### Connect to "root" user

```console
sudo -i
```

### Create a script to start, stop service "jupyterlab"

```console
vi /etc/systemd/system/jupyterlab.service
```

### Add next lines to launch like "opc" user the script "launchjupyterlab.sh"

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

### Test Jupyter Lab Service

```console
systemctl start jupyterlab
systemctl status jupyterlab
systemctl enable jupyterlab
```

## 4. Reboot Your machine for a final check

Home stretch! 

1.  Reboot your machine to check if the Jupyterlab script is enabled by default on port 8001.
2. Open port 8001 to your virtual machine VM 2.1 in order to access it using your Public IP.

```console
firewall-cmd  --permanent --zone=public --list-ports
firewall-cmd --get-active-zones
firewall-cmd --permanent --zone=public --add-port=8001/tcp
firewall-cmd --reload
```

If you're running directly on a virtual machine and have a browser installed, it should take you directly into the Jupyter environment. Connect to your `http://xxx.xxx.xxx.xxx:8001/`.

You should now see the next Python Web environment "Jupyterlab".

That's it! Enjoy using Cassandra with OCI.