---
title: Install Jupyter Lab in OCI
parent: tutorials
tags:
- oci
- get-started
- jupyter
- python
- data-science
- machine-learning
- open-source
categories:
- ai-ml
description: This tutorial will guide you through setting up your environment to run
  Jupyter Lab on Oracle Cloud Infrastructure.
date: 2021-10-07 14:27
redirect_from: "/collections/tutorials/install-jupyter-lab-on-oci/"
---
{% slides %}

This tutorial will guide you through setting up your environment to run Jupyter Lab on Oracle Cloud Infrastructure.

## Prerequisites

You'll need a Virtual Machine 2.1 with Oracle Linux 7.9 (OEL7) deployed in Oracle Cloud Infrastructure (OCI).

- Oracle Linux 7.9 using pip3.6 by default. 
- Python 3.6 or higher installed
- Access to root, either directly or via sudo. By default in OCI, you are connected as the "opc" user with sudo privilege.

The install is pretty simple. It consists of setting up python and installing python components and libraries. 

Lets start with setting up the Python Environment

## Python Setup

By default, OEL7 runs Python 3. The first step is to install `pip` and `virtualenv`.

1. Install `virtualenv`

	Virtualenv enables us to create isolated sandboxes for developing Python applications without running into module or library conflicts. It's very simple to install:

	```console
	sudo pip3.6 install virtualenv
	```

2. Next we can create a virtual environment called "myvirtualenv"

	```console
	virtualenv -p /usr/bin/python3 myvirtualenv
	# Activate the env
	source myvirtualenv/bin/activate
	```

3. Check list of Python Libraries in your environment

	Running the following command will show what Python models we have installed at this point.

	```console
	(myvirtualenv)$ pip3 list
	Package    Version
	---------- -------
	pip        21.1.3
	setuptools 57.1.0
	wheel      0.36.2
	WARNING: You are using pip version 21.1.3; however, version 21.2.1 is available.
	You should consider upgrading via the '/home/opc/myvirtualenv/bin/python -m pip install --upgrade pip' command.
	```

4. Upgrade your PIP Environment for this virtual environment:

	```console
	/home/opc/myvirtualenv/bin/python -m pip install --upgrade pip
	```

## Jupyter Lab Setup

1. Use `pip` to install Jupyter Lab:

	```console
	pip3 install jupyterlab
	```

2. Install Python Libraries for Machine Learning or ETL Process:

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

3. Install other Python libraries for Kafka Access and WEB Server Access:

	```console
	pip install kafka-python (v2.0.0)
	pip install Flask
	pip install gunicorn
	```

4. Install extensions for Jupyter Lab environment:

	```console
	pip install jupyter_contrib_nbextensions
	jupyter contrib nbextension install --user
	jupyter nbextension enable execute_time/ExecuteTime
	```

## Configure Jupyter Lab like an OEL7 Linux Service

1. Create a script to instantiate automatically and reboot jupyterlab with the `opc` user.

	```console
	vi /home/opc/launchjupyterlab.sh
	```

2. Add the contents below to `launchjupyterlab.sh`. You must use the `virtualenv` you created, and you can launch Jupyter Lab on a specific port (for example: 8001) and listen on your VM's public IP.

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

3. Make the script executable so it can be run from the jupyterlab service:

	```console
	chmod 777 /home/opc/launchjupyterlab.sh
	```


4. Connect to "root" user:

	```console
	sudo -i
	```

5. Create a script to start and stop the "jupyterlab" service:

	```console
	vi /etc/systemd/system/jupyterlab.service
	```


6. Add the following to `jupyterlab.service`:

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

7. Test the Jupyter Lab Service

	```console
	systemctl start jupyterlab
	systemctl status jupyterlab
	systemctl enable jupyterlab
	```

## Reboot your VM

1. Reboot your machine to check if `jupyterlab` script is enabled by default on port we defined (8001).

2. Open port 8001 to your virtual machine VM 2.1 so you can access Jupyter Lab using your Public IP.

	```console
	firewall-cmd  --permanent --zone=public --list-ports
	firewall-cmd --get-active-zones
	firewall-cmd --permanent --zone=public --add-port=8001/tcp
	firewall-cmd --reload
	```

3. If you're running directly on a virtual machine and have a browser installed, it should take you directly into the Jupyter environment. Connect to `http://xxx.xxx.xxx.xxx:8001/` (replacing `xxx` with your public IP).

You should now see the Python Web environment "Jupyter Lab".

{% endslides %}
