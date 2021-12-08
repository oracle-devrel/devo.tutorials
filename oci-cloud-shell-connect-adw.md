---
title: "Oracle Cloud Shell: Connect an ADW Database" 
date: 2021-12-08 12:00
parent: [tutorials]
toc: true
author:
  name: Dilli Raj Maharjan
tags: [oci]
categories: []
thumbnail: assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.28.42.png
---
{% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.28.42.png %}

### Oracle Cloud Shell Overview.

Oracle Cloud Infrastructure (OCI) Cloud Shell is a  browser-based terminal accessible from the Oracle Cloud Console. It is free to use and provides access to a Linux shell. Oracle announced Oracle Cloud Shell on Feburary 11, 2020. It contains a pre-authenticated OCI command line interface and a lot of other useful tools to perform OCI cloud related tasks. Cloud Shell is a feature available to all OCI users that is accessible from the OCI console. It appears in the persistent frame of the console and will stay active while navigating to different pages of the console.

Cloud Shell provides an ephemeral machine, that lasts for a short time. It acts as a host for a Linux shell with pre-configured latest version of the OCI command line interface and a number of useful tools. Cloud Shell provides 5 GB of storage for our home directory and all the files will be saved during reboot of Cloud Shell. The storage for Cloud Shell VM's home directory remains persistent from session to session. The administrator of Cloud will receive notification that the storage will be removed in 60 days if the Cloud Shell is not used for 6-months. 

The resource name for Cloud Shell is `cloud-shell`. IAM Policy required to access Cloud Shell will be something like below

```console
allow group <group name> to use cloud-shell in tenancy
```

For more details about Cloud Shell Please visit link below.

- [Cloud Shell Intro](https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm)
- [Cloud Shell Getting Started](https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellgettingstarted.htm)
- [Announcing Oracle Cloud Shell](https://blogs.oracle.com/cloud-infrastructure/announcing-oracle-cloud-shell)

### Accessing Cloud Shell in the Oracle Cloud Console.

1. On the top right corner of the console you will get the icon for OCI Cloud Shell. Click on it to access OCI Cloud Shell.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B09.21.40.png %}

1. At the bottom of the OCI cloud console page, a new persistent frame will be available. If you are using Cloud Shell for the first time it will take few minutes to start. 

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B09.22.00.png %}

1. From the second time it will be quicker to load Cloud Shell. It is just provisioning VM and attaching and mounting the storage to home dir.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.49.31.png %}

1. Once Oracle Cloud Shell is connected it looks something like below.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B09.24.12.png %}

1. Available buttons in Cloud Shell.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B20.03.31.png %}

1. I read the redhat-release file and noticed operating system is RHEL 7.8

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B09.25.14.png %}

1. Checked disk details with df command and found home is 5 GB in size.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B09.25.27.png %}

1. Checked location of utilities.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B09.29.48.png %}

#### Following utilities are available with Cloud Shell.

1. Git
2. Java
3. Python (2 and 3)
4. SQL Plus
5. kubectl
6. helm
7. maven
8. gradle
9. terraform
10. ansible

### Create Autonomous Data Warehouse Database.

1. Open Oracle Cloud Console. Click on Create an ADW database on Quick Actions page.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.40.44.png %}

1. Provide the name of Autonomous Database.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.42.39.png %}

1. Scroll down and provide Admin user password. Click on Create Autonomous Database.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.44.43.png %}

1. We can noticed that ADW is in PROVISIONING state.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.45.04.png %}

1. Once provisioning is completed, status will be changed to available. Click on DB Connection button.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.47.22.png %}

1. Click on Download Wallet button.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.47.37.png %}

1. Provide the wallet login password and click on Download.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B18.48.16.png %}

### Create Object Storage

Create Object Storage to temporarily upload wallet and download to OCI Cloud Shell.

1. Click on Navigation menu. Click on Object Storage and click on Object Storage.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.05.45.png %}

1. Click on Create Bucket.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.07.39.png %}

1. Provide the name of Bucket.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.08.11.png %}

1. Click on Create Bucket button to create bucket.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.08.21.png %}

1. Upload Wallet file to the bucket.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.09.14.png %}

1. Click on three vertical dots at the right and click on Create Pre-Authenticated Request.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.10.25.png %}

1. Provide the name of the Pre-Authenticated Request and click on Create Pre-Authenticated Request button.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.10.44.png %}

1. Copy PRE-Authenticated request URL

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.10.57.png %}

1. Go to Cloud Shell and download the wallet with wget command.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.11.25.png %}

1. It looks something like below once wallet is downloaded completely.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.11.46.png %}

1. Create directory to store wallet files. Move wallet files to the directory and extract it.

    ```console
    mkdir -p network/admin
    mv Wallet_cstest.zip network/admin
    cd network/admin
    unzip Wallet_cstest.zip
    ```

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.13.49.png %}

1. Open sqlnet.ora file and modify the Directory value to the directory location where wallet files are located.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.20.21.png %}

1. Connect to ADW database using sqlplus `<username>@<tnsnames>`.

    {% imgx assets/oci-cloud-shell-connect-adw-Screen%2BShot%2B2020-09-30%2Bat%2B19.20.38.png %}
