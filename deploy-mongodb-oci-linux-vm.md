---
title: Deploying MongoDB in Oracle Cloud (OCI) Linux VM
parent: [tutorials]
tags: [devops, python]
date: 2021-12-10 14:34
description: MongoDB and Oracle Cloud Infrastructure play well together --- Olivier shows you how to configure your envionment to connect them.
MRM: WWMK211208P00082
author: olivier
---
If you've ever wanted a guide for running MongoDB Enterprise/Community in your Oracle Cloud Infrastructure (OCI) environment, we have good news for you! 

## Prerequisites

* You have deployed a VM 2.1 with Oracle Linux 7.9 (OEL7) in Oracle Cloud Infrastructure.
* Your install of Oracle Linux 7.9 is using pip3.6 by default. 
* Python 3.6 or higher is installed.
* You have access to root either directly or via sudo. By default in OCI, you are connected like an "opc" user with sudo privilege.

If you don't yet have an OCI account, you can quickly sign up for one today by registering for an [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/#always-free) account. 

Afterwards, check [developer.oracle.com/linux](https://developer.oracle.com/linux/) for even more Linux content.

## MongoDB Installation

Create an `/etc/yum.repos.d/mongodb-enterprise-5.0.` repo file in the yum configuration so that you can install MongoDB Enterprise directly with this command:

```console
vi /etc/yum.repos.d/mongodb-enterprise-5.0.repo
```

Paste these lines in that file:

```console
[mongodb-enterprise-5.0]
name=MongoDB Enterprise Repository
baseurl=https://repo.mongodb.com/yum/redhat/$releasever/mongodb-enterprise/5.0/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
```

Execute the next command using the yum file:

```console
sudo yum install -y mongodb-enterprise
```

Your result should look like this:

```console
Installed:
  mongodb-enterprise.x86_64 0:5.0.2-1.el7

Dependency Installed:
  cyrus-sasl.x86_64 0:2.1.26-23.el7                                    cyrus-sasl-gssapi.x86_64 0:2.1.26-23.el7
  mongodb-database-tools.x86_64 0:100.5.0-1                            mongodb-enterprise-cryptd.x86_64 0:5.0.2-1.el7
  mongodb-enterprise-database.x86_64 0:5.0.2-1.el7                     mongodb-enterprise-database-tools-extra.x86_64 0:5.0.2-1.el7
  mongodb-enterprise-mongos.x86_64 0:5.0.2-1.el7                       mongodb-enterprise-server.x86_64 0:5.0.2-1.el7
  mongodb-enterprise-shell.x86_64 0:5.0.2-1.el7                        mongodb-enterprise-tools.x86_64 0:5.0.2-1.el7
  mongodb-mongosh.x86_64 0:1.0.5-1.el7                                 net-snmp.x86_64 1:5.7.2-49.el7_9.1
  net-snmp-agent-libs.x86_64 1:5.7.2-49.el7_9.1                        net-snmp-libs.x86_64 1:5.7.2-49.el7_9.1

Complete!
```

The install is pretty simple using the yum installation script. Let' s start with setting up the MongoDB Environment

### MongoDB Setup

By default, MongoDB has a daemon configuration file in `/etc/mongod.conf` and runs using the mongod user account with the following default directories:

* /var/lib/mongo (the data directory)
* /var/log/mongodb (the log directory)

The package manager creates the default directories during installation. The owner and group name are `mongod`.

### Using Non-Default Directories with MongoDB

To use a data directory and/or log directory other than the default directories:

Create the new directory or directories and then edit the configuration file /etc/mongod.conf and modify the following fields accordingly:

```console
storage.dbPath to specify a new data directory path (e.g. /some/data/directory)
systemLog.path to specify a new log file path (e.g. /some/log/directory/mongod.log)
```

Ensure that the user running MongoDB has access to the directory or directories:

```console
sudo chown -R mongod:mongod <directory>
```

For example, create a "data" directory:

```console
sudo mkdir /data/mongodb 
sudo chown -R mongod:mongod /data/mongodb
```

Change the configuration in `/etc/mongod.conf` and the `dbPath` variable.

```console
vi /etc/mongod.conf

storage:
dbPath: /var/lib/mongo
dbPath: /data/mongodb
journal:
enabled: true
engine:
wiredTiger:
```

If you change the user that runs the MongoDB process, you must give the new user access to these directories.

#### MongoDB SELinux Configuration (Optional)

Configure SELinux if enforced. See [SELinux](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/#std-label-install-rhel-configure-selinux).

### Start MongoDB

You can start the `mongod` process by issuing the following command:

```console
sudo systemctl start mongod
```

### Verify that MongoDB has started successfully

You can verify that the `mongod` process has started successfully by issuing the following command:

```console
sudo systemctl status mongod
```

You can optionally ensure that MongoDB will start following a system reboot by issuing the following command:

```console
sudo systemctl enable mongod
```

### Stop MongoDB
As needed, you can stop the `mongod` process by issuing the following command:

```console
sudo systemctl stop mongod
```

### Restart MongoDB.
You can restart the `mongod` process by issuing the following command:

```console
sudo systemctl restart mongod
```

You can follow the state of the process for errors or important messages by watching the output in the `/var/log/mongodb/mongod.log` file.

## Begin using MongoDB

Start a mongosh session on the same host machine as  mongod. You can run mongosh without any command-line options to connect to a mongod that is running on your localhost with default port 27017.


```console
mongosh
```

The result should look like:

```console
Current Mongosh Log ID: 61a0e720ab709eb9973092bc
Connecting to:          mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000
Using MongoDB:          5.0.2
Using Mongosh:          1.0.5

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting:
   2021-11-26T13:54:31.358+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2021-11-26T13:54:31.358+00:00: /sys/kernel/mm/transparent_hugepage/enabled is 'always'. We suggest setting it to 'never'
------

Enterprise test>
```

You're now connected to Mongodb on Oracle Cloud Infrastructure!
