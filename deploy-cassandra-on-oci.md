---
title: Deploy Cassandra on Oracle Cloud (OCI) Linux VM
tags:
- oci
- python
- jupyter
- back-end
parent: tutorials
description: Set up your environment to run Cassandra in Oracle Cloud Infrastructure.
author: olivier
categories:
- cloudapps
date: 2021-09-21 12:00
redirect_from: "/collections/tutorials/deploy-cassandra-on-oci/"
---
{% slides 2 %}
This tutorial will guide you through the steps needed to set up your environment to run Cassandra in Oracle Cloud Infrastructure.

### Prerequisites

You should have already deployed a VM 2.1 with Oracle Linux 7.9 (OEL7) in Oracle Cloud Infrastructure (OCI).

- The installation of Oracle Linux 7.9 is using pip3.6 by default
- Python 3.6 or higher is installed
- You have access to root, either directly or via sudo. In OCI, the default user is "opc" and has sudo privileges

Installing JuypterLab is fairly simple:

1. Set up python
2. Install python components and libraries

Lets start with setting up the Python Environment.

## Python setup

By default, OEL7 runs Python 3. The first step is to install `pip` and `virtualenv`.

<!-- Says install _pip_ and virtualenv but does not have instructions for pip -->

1. Install virtualenv

    The next step is to install `virtualenv`. `virtualenv` enables us to create isolated sandboxes to develop Python applications without running into module or library conflicts. It's easy to install:

    ```console
    sudo pip3.6 install virtualenv
    ```

2. Create an environment and enable it

    Create an environment called "myvirtualenv" using the following command:

    ```console
    virtualenv -p /usr/bin/python3 myvirtualenv
    # Activate the env
    source myvirtualenv/bin/activate
    ```

3. Check Python libraries

    Running the following command will show what Python modules we have installed at this point:

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

4. Upgrade your PIP Environment

    ```console
    /home/opc/myvirtualenv/bin/python -m pip install --upgrade pip
    ```

## Jupyterlab setup

1. Install JupyterLab
    
    ```console
    pip3 install jupyterlab
    ```

1. Install Python libraries for Machine Learning or ETL Process

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

2. Install other Python Libraries for Kafka Access and WEB Server Access

    ```console
    pip install kafka-python (v2.0.0)
    pip install Flask
    pip install gunicorn
    ```

3. Install extensiones for Jupyterlab Environment

    ```console
    pip install jupyter_contrib_nbextensions
    jupyter contrib nbextension install --user
    jupyter nbextension enable execute_time/ExecuteTime
    ```

## Configure Jupyterlab as an OEL7 Linux Service

1. Create a script to automatically instantiate and reboot JupyterLab with the "opc" user.

    ```console
    vi /home/opc/launchjupyterlab.sh
    ```

    Add the content below. You must use the "myvirtualenv" virtualenv environment you created previously. You can launch Jupyterlab on a specific port (for example: 8001) and listen on your public IP.

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

1. Make the script executable so it can be executed from the JupyterLab service.

    ```console
    chmod 777 /home/opc/launchjupyterlab.sh
    ```

2. Connect to the "root" user

    ```console
    sudo -i
    ```

3. Create a script to start and stop the "jupyterlab" service

    ```console
    vi /etc/systemd/system/jupyterlab.service
    ```


    Add the following to launch the "launchjupyterlab.sh" script as the "opc" user

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

5. Test Jupyterlab Service

    ```console
    systemctl start jupyterlab
    systemctl status jupyterlab
    systemctl enable jupyterlab
    ```

## Reboot Your machine for a final check

Lastly, you'll need to **reboot your machine** to ensure the jupyterlab script is available on port 8001.

Open port 8001 on your virtual machine VM 2.1 to allow access to JupyterLab using your Public IP.

```console
firewall-cmd --permanent --zone=public --list-ports
firewall-cmd --get-active-zones
firewall-cmd --permanent --zone=public --add-port=8001/tcp
firewall-cmd --reload
```

If you're running directly on a virtual machine and have a browser installed, it should take you directly into the Jupyter environment. Connect using your public IP with the 8001 port, i.e. "http://xxx.xxx.xxx.xxx:8001/".
  
You should now see the Python Web environment "Jupyterlab".
  
{% endslides %}

