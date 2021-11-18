---
title: Get Started with the Feature Store HopsWorks (LogicalClocks) on Oracle Cloud
parent: tutorials
tags:
- feature-store
- open-source
- machine-learning
date: 2021-11-18 09:45
categories: [cloudapps]
description: This walk-through will guide you through setting up your environment to run HopsWorks with OCI.
author: olivier
---
{% slides %}
In this walk-through you'll configure your environment to run HopsWorks in Oracle Cloud Infrastructure.

### Prerequisites

* VM 2.1 with Oracle Linux 7.9 (OEL7) has been deployed in Oracle Cloud Infrastructure (OCI)
* Oracle Linux 7.9 uses `pip3.6` by default
* Python 3.6 or higher is installed
* You have access to root either directly or using `sudo`. In OCI you are connected as user `opc` with sudo privilege by default

## Jupyterlab Installation

The Jupyterlab install is pretty simple. It consists of setting up Python, then installing Python components and libraries. 

Let's start with setting up the Python environment.

### Python Setup

By default, OEL7 runs Python 3. The first step is to install `virtualenv` and `pip`.

#### Install virtualenv

Virtualenv enables us to create isolated sandpits to develop Python applications without running into module or library conflicts. It's simple to install.

```console
$ sudo pip3.6 install virtualenv
```

Next, we can create a virtual environment and enable it.

#### Create a myvirtualenv Environment

```console
$ virtualenv -p /usr/bin/python3 myvirtualenv
# Activate the env
$ source myvirtualenv/bin/activate
```

#### Check the List of Python Libraries in Your Environment

Running the following command will show what Python models we have installed at this point.

```console
$ pip3 list
Package    Version
---------- -------
pip        21.1.3
setuptools 57.1.0
wheel      0.36.2
WARNING: You are using pip version 21.1.3; however, version 21.2.1 is available.
You should consider upgrading via the '/home/opc/myvirtualenv/bin/python -m pip install --upgrade pip' command.
```

#### Upgrade Your pip Environment

```console
$ /home/opc/myvirtualenv/bin/python -m pip install --upgrade pip
```
### Jupyterlab Setup

```console
$ pip3 install jupyterlab
```

#### Install Python Libraries for Machine Learning or an ETL Process

```console
$ pip install pandas
$ pip install pandarallel
$ pip install dask
$ pip install seaborn
$ pip install matplotlib
$ pip install plotly
$ pip install -lxml==4.6.3
$ pip install selenium
$ pip install beautifulsoup4
$ pip install scikit-learn
```

#### Install Other Python Libraries for Kafka Access and WEB Server Access

```console
$ pip install kafka-python (v2.0.0)
$ pip install Flask
$ pip install gunicorn
```

#### Install Extensions for Jupyterlab Environment

```console
$ pip install jupyter_contrib_nbextensions
$ jupyter contrib nbextension install --user
$ jupyter nbextension enable execute_time/ExecuteTime
```

## Configure Jupyterlab Like the OEL7 Linux Service

Create a script to automatically instantiate and reboot Jupyterlab with `opc` user.

```console
$ vi /home/opc/launchjupyterlab.sh
```

### Script for launchjupyterlab.sh

Using virtualenv, you can launch Jupyterlab on a specific port (for example: 8001) and listen on a public IP.

```bash
#!/bin/bash

# Activate myvirtualenv Environment
source myvirtualenv/bin/activate

cd /home/opc

if [ "$1" = "start" ]; then
    nohup jupyter-lab --ip=0.0.0.0 --port=8001 > ./nohup.log 2>&1 &
    echo $! > /home/opc/jupyter.pid
else
    kill $(cat /home/opc/jupyter.pid)
fi
```

We need to make the script executable so it can be run from the jupyterlab service.

```console
$ chmod 777 /home/opc/launchjupyterlab.sh
```

### Connect to Root User

```console
$ sudo -i
```

### Create Script to Start, Stop "jupyterlab"

```console
$ vi /etc/systemd/system/jupyterlab.service
```


### Launch "opc" User with "launchjupyterlab.sh"

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

### Test Jupyterlab Service

```console
$ systemctl start jupyterlab
$ systemctl status jupyterlab
$ systemctl enable jupyterlab
```

## Reboot for a Final Check

Now reboot your machine to check if the jupyterlab script is enabled by default on port 8001.

You need to open port 8001 to your virtual machine VM 2.1 in order to access using your public IP.

```console
$ firewall-cmd  --permanent --zone=public --list-ports
$ firewall-cmd --get-active-zones
$ firewall-cmd --permanent --zone=public --add-port=8001/tcp
$ firewall-cmd --reload
```

If you're running directly on a virtual machine and have a browser installed, it should take you directly into the jupyter environment. Connect to "http://xxx.xxx.xxx.xxx:8001/".
  
You should see the next Python web environment "Jupyterlab."
{% endslides %}
