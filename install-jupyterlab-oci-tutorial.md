---
layout: collection
title: How to install Jupyterlab in Oracle Cloud (OCI)
description: Setting up Jupyterlab to run on Oracle Cloud Infrastructure.
thumbnail: RELATIVE_PATH_TO_THUMBNAIL_IMAGE
tags: [python, linux, oci, jupyter]
sort: desc
date: 2021-11-05 12:01
author: 
    name: operard
    github: https://github.com/operard
categories: [clouddev]
parent: tutorials
---

The following walk-through guides you through the steps needed to set up your environment to run Jupyterlab in Oracle Cloud Infrastructure.

## Prerequisites

You have deployed a VM 2.1 with Oracle Linux 7.9 (OEL7) in Oracle Cloud Infrastructure (OCI).

* The installation of Oracle Linux 7.9 is using pip3.6 by default.
* Python 3.6 or higher is installed
* You have access to root either directly or via sudo. By default in OCI, you are connected like "opc" user with sudo privilege.

## Jupyterlab Installation

The install is pretty simple. It consists of setting up python, installing python components and libraries. Lets start with setting up the Python Environment

### Python Setup

By default, OEL7 runs Python 3. The first is to install pip and virtualenv.

#### Install virtualenv

The next step is to install virtualenv. Virtualenv enables us to create isolated sandpits to develop Python applications without running into module or library conflicts. It's very simple to install
```console
    sudo pip3.6 install virtualenv
```

Next we can create a virtual environment and enable it.

#### Create an environment "myvirtualenv"
```console
    virtualenv -p /usr/bin/python3 myvirtualenv
    # Activate the env
    source myvirtualenv/bin/activate
```

#### Check list of Python Libraries in your environment

Running the following command will show what Python models we have installed at this point.
    
    (myvirtualenv) [opc@lab1 ~]$ pip3 list
    Package    Version
    ---------- -------
    pip        21.1.3
    setuptools 57.1.0
    wheel      0.36.2
    WARNING: You are using pip version 21.1.3; however, version 21.2.1 is available.
    You should consider upgrading via the '/home/opc/myvirtualenv/bin/python -m pip install --upgrade pip' command.

#### Upgrade your PIP Environment for this virtual environment

```console
    /home/opc/myvirtualenv/bin/python -m pip install --upgrade pip
```

### Jupyterlab Setup

```console
    pip3 install jupyterlab
```

#### Install Python Libraries for Machine Learning or ETL Process

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

#### Install extensiones for Jupyterlab Environment

```console
    pip install jupyter_contrib_nbextensions
    jupyter contrib nbextension install --user
    jupyter nbextension enable execute_time/ExecuteTime
```

## Configure Jupyterlab like a OEL7 Linux Service

Create a script to instantiate automatically and reboot jupyterlab with "opc" user.
```console
    vi /home/opc/launchjupyterlab.sh
```

### Script for launchjupyterlab.sh

You must use the virtualenv created and you can launch Jupyterlab in a specific port (for example: 8001) and listen on public IP.

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

We must put the script in executable mode in order to be executed from jupyterlab service.
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

### Test Jupyterlab Service
```console
    systemctl start jupyterlab
    systemctl status jupyterlab
    systemctl enable jupyterlab
```

## Reboot Your machine to final check

Now, you must reboot your machine to check if jupyterlab script is enabled by default on port defined 8001.

You must open port 8001 to your virtual machine VM 2.1 in order to access using your Public IP.
```console
    firewall-cmd  --permanent --zone=public --list-ports
    firewall-cmd --get-active-zones
    firewall-cmd --permanent --zone=public --add-port=8001/tcp
    firewall-cmd --reload
```

If you're running directly on a virtual machine and have a browser installed it should take you directly into the jupyter environment. Connect to your "[http://xxx.xxx.xxx.xxx:8001/](http://xxx.xxx.xxx.xxx:8001/)".

And you should see the next Python Web environment "Jupyterlab".
