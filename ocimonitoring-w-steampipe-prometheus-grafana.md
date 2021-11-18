---
title: Installation Guide for OCI Monitoring 
parent: tutorials
categories: [modernize]
toc: true
tags:
- ansible 
- data-visualization
- data-management
personas:
- backend
date: 2021-11-18 09:42
description: This tutorial walks you through configuring a basic OCI monitoring solution with components based on Ansible in Oracle Linux 8.
author: 
  name: Martin Berger
  github: martinberger-ch
---
{% slides %}
# An Installation Guide for OCI Monitoring

> **Note:** This is an experimental environment. Feel free to try it out, extend it, and have fun with it!
{:.notice}

In this walkthrough you'll install a basic OCI monitoring solution with these components based on Ansible in Oracle Linux 8. The setup is tested for:

- OL8 running in ESXi
- OL8 running in local VMware Workstation with NAT
- OL8 running in Oracle Cloud Infrastructure

Installed components by Ansible roles:

- Docker
- Steampipe
- Grafana
- Prometheus
- Push Gateway
- PostgreSQL

## Links

- [Steampipe](https://steampipe.io/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)

## How it works

{% imgx assets/oci-monitoring-architecture.png "Architecture" "Architecture Overview" %}

1. Execute the Python script
2. Steampipe gathers the information from Oracle Cloud Infrastructure
3. The return value is pushed to Prometheus Push Gateway
4. Prometheus scrapes the metrics from the gateway
5. Grafana reads the metrics from Prometheus

## Prerequisites

- root access by password
- `/etc/hosts` configured
- Ansible and Git configured
- Internet access
- Oracle Cloud Infrastructure user with inspect permissions, including SSH PEM key and configuration

### Software Installation OL8 ESXi / OL8 VMware

As user `root`:

```console
$ yum -y install yum-utils
$ yum -y install oracle-epel-release-el8
$ yum-config-manager --enable ol8_developer_EPEL
$ yum -y install ansible git
```

### Software Installation OL8 Oracle Cloud Infrastructure

As user `opc`:

```console
$ sudo dnf upgrade
$ sudo dnf -y install oracle-epel-release-el8
$ sudo dnf config-manager --enable ol8_developer_EPEL
$ sudo dnf -y install ansible git
```

### Ansible SSH Configuration for Oracle Cloud Infrastructure

- Upload the `opc`'s SSH private key to `/home/opc/.ssh` temporarily for installaton purposes
- Change the Ansible checked out hosts file to:

    ```console
    [all:vars]
    ansible_ssh_private_key_file=/home/opc/.ssh/<your_ssh_key_file_name_here>

    [monitoring]
    <your_oci_compute_private_instance_here> ansible_user=opc ansible_python_interpreter="/usr/bin/env python3"
    ```

> After the installation, it's a good practice to remove the opc private key from your compute instance
{:.alert}

## Steps

1. Login to Oracle Linux 8 as `root`
2. Clone the repository to a local folder such as `/root/git`
3. Change to subdirectory `oci-monitoring`
4. Update the Ansible `hosts` file with your IP and root password. `ansible_ssh_pass` is required for local connections
5. Run `ansible-galaxy collection install -r roles/requirements.yml`
6. Run `ansible-playbook install.yml`

As `root`, verify that all Docker containers are running:

```console
$ docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED             STATUS             PORTS                    NAMES
f7f2e137f4a1   prom/pushgateway   "/bin/pushgateway"       About an hour ago   Up About an hour   0.0.0.0:9091->9091/tcp   pushgateway
c6ecc72065c9   prom/prometheus    "/bin/prometheus --c…"   About an hour ago   Up About an hour   0.0.0.0:9090->9090/tcp   prometheus
3485de8cc1f9   grafana/grafana    "/run.sh"                About an hour ago   Up About an hour   0.0.0.0:3000->3000/tcp   grafana
8e821aa0044b   turbot/steampipe   "docker-entrypoint.s…"   About an hour ago   Up 30 minutes      0.0.0.0:9193->9193/tcp   steampipe
```

### Network Security

The Ansible playbooks also open these ports in the VM for troubleshooting access:

* 3000 - Grafana
* 9090 - Prometheus
* 9091 - Prometheus Push Gateway
* 9093 - Steampipe Service

## OCI Configuration

- After the successful Ansible execution, put your personal OCI configuration and SSH key into the directory `/home/steampipe/.oci`
- Replace the dummy values
- Update the file `/home/steampipe/config/oci.spc` with the correct SSH key file name

> Take care that owner and group of the OCI configuration file is `steampipe`
{:.notice}

Example:

```console
$ pwd
/home/steampipe/.oci

$ ls -l
total 8
-rw-r--r--. 1 steampipe steampipe  307 Aug  9 09:01 config
-rw-r--r--. 1 steampipe steampipe 1730 Aug  9 09:01 jurasuedfuss-20210809.pem
```

Restart the Docker container for Steampipe:

```console
$ docker stop steampipe
$ docker start steampipe
```

## How to create the user for OCI access - based on OCI CLI

Next we create an OCI user for monitoring. An existing OCI CLI setup for an tenant administrator is required to execute these steps. The required SSH key in PEM format can be downloaded from the OCI web interface. The user, group, and policy can be created in web interface as well. 

All we need for Steampipe is the OCI config file for the new user and their SSH key in PEM format.

### Create User

```console
$ oci iam user create --name oci_user_readonly --description "OCI User with inspect all-resources."
```

### Create Group

```console
$ oci iam group create --name oci_group_readonly --description "OCI Group with inspect all-resources."
```

### Add User to Group

```console
$ oci iam group add-user \
--user-id <your user OCID from created user above> \
--group-id <your group OCID from created group above>
```

### Create Policy

```console
$ oci iam policy create \
--compartment-id <your tenancy OCID> \
--name oci_policy_readonly \
--description "OCI Policy with inspect all-resources." \
--statements '[ "allow group oci_group_readonly to inspect all-resources on tenancy" ]'
```

### Add API Key

1. Add your API key

    {% imgx assets/oci-monitoring-api-key.png "OCI API Key 01" %}

2. Download the created private key in PEM format

    {% imgx assets/oci-monitoring-add-api-key.png "OCI API Key 02" %}

3. Copy the configuration file preview. The values are used for the Steampipe OCI configuration

    {% imgx assets/oci-monitoring-config-file-prev.png "OCI API Key 03" %}

## Steampipe

### OCI Regions

To filter your regions, just edit the file `/home/steampipe/config/oci.spc`.

For example:

```
connection "oci_tenant_kestenholz" {
  plugin                = "oci"
  config_file_profile   = "DEFAULT"          # Name of the profile
  config_path           = "~/.oci/config"    # Path to config file
  regions               = ["eu-frankfurt-1" , "eu-zurich-1"] # List of regions
}
```

Here are some commands to verify if Steampipe is working as expected. Execute as `root`:

```console
$ docker exec -it steampipe steampipe plugin list
+--------------------------------------------+---------+-----------------------+
| Name                                       | Version | Connections           |
+--------------------------------------------+---------+-----------------------+
| hub.steampipe.io/plugins/turbot/oci@latest | 0.1.0   | oci_tenant_kestenholz |
+--------------------------------------------+---------+-----------------------+
```

```console
$ docker exec -it steampipe steampipe \
query "select display_name,shape,region from oci_core_instance where lifecycle_state='RUNNING';"
+-----------------------------------+------------------------+----------------+
| display_name                      | shape                  | region         |
+-----------------------------------+------------------------+----------------+
| Instance-DB-1                     | VM.Standard1.2         | eu-frankfurt-1 |
| Instance-AS-1                     | VM.Standard1.1         | eu-frankfurt-1 |
+-----------------------------------+------------------------+----------------+
```

```console
$ docker exec -it steampipe steampipe \
query "select key,title,status from oci_region where is_home_region=true;"
+-----+----------------+--------+
| key | title          | status |
+-----+----------------+--------+
| FRA | eu-frankfurt-1 | READY  |
+-----+----------------+--------+
```

## Python Example Scripts

In the subdirectory `/home/steampipe/py`, there are two basic examples of how to get the data from the Steampipe PostgreSQL service to Python3. Feel free to adapt the queries and files. Returned values are pushed to the Prometheus Gateway on port 9091 for further usage.

| Script                                 | Purpose                                              |
|----------------------------------------|------------------------------------------------------|
| pgsql-query-bv-zurich.py               | Summary of Block Volume in OCI Region Zurich         |
| pgsql-query-ci-running-zurich.py       | Summary of running Instances in OCI Region Zurich    |

> Note: You'll need to restart the Docker container before executing Python3 according this error. This is something I'm working on!
{:.alert}

Manual execution and upload of the query result:

```console
$ python3 pgsql-query-ci-running-zurich.py
$ python3 pgsql-query-bv-zurich.py
```

```console
Something went wrong: no connection config loaded for connection 'oci'
```

Restarting Steampipe as `root`:

```console
$ docker stop steampipe
$ docker start steampipe
```

## Prometheus Push Gateway

According to the Python script, new data is loaded in Prometheus Push Gateway to port 9091 and scraped by Prometheus port 9090. 

Checkout this example for the Protheus Gateway where data is loaded by jobs `oci_blockvolume_ / _oci_compute`.

{% imgx assets/oci-monitoring-pushgateway.png "OCI Prometheus Push Gateway 01" %}

## Grafana

Grafana is reachable by address `your-machine-ip:3000`.

- Username: `admin`
- Password: `welcome1`

The Prometheus data source and a basic dashboard are deployed during the Grafana Docker setup process. Here's an example for dasboard __OCI Demo - eu-zurich-1__:

{% imgx assets/oci-monitoring-grafana.png "Prometheus data source" "Prometheus data source" %}

{% imgx assets/oci-monitoring-grafana-demo.png "Sample dashboard OCI Demo" "Sample dashboard OCI Demo" %}

Here you can see the pushed metric from the Python script by name:

{% imgx assets/oci-monitoring-grafana-metrics-browser.png "Metric from Python script" %}

## Troubleshooting

### Docker Logs

To verify that Steampipe is running properly:

```console
$ docker logs steampipe
```

### Steampipe Access Logs

The foreign data wrapper logs are stored locally --- not in the Docker container --- in the directory `/home/steampipe/logs`:

```console
drwx------. 11 steampipe steampipe     173 Aug  9 17:18 ..
-rw-------.  1      9193 root       756701 Aug  9 19:57 database-2021-08-09.log
drwxrwxr-x.  2 steampipe root           68 Aug 10 02:00 .
-rw-------.  1      9193 root      3411203 Aug 10 07:19 database-2021-08-10.log
```
{% endslides %}
