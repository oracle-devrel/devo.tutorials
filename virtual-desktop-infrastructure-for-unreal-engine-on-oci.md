---
title: Virtual Desktop Infrastructure(VDI) for Unreal Engine 5 on Oracle Cloud Infrastructure with nVidia GPU
parent:
- tutorials
tags: []
categories: []
date: 2021-12-12 08:00
description: Get Virtual Desktop Infrastructure set up on Oracle Cloud Infrastructure with nVidia GPU.
toc: true
author: oracle-developers
slug: rust-building-an-api
---

In this blog you'll learn how to set up Virtual Desktop Infrastructure on Oracle Cloud Infrastructure (OCI).

A few weeks ago, Unreal Engine 5.1 was released. There are a lot of improvements and many new cool features that, for me, are making this release kind of of a big deal.

[{% imgx img/UE5/UE5.png "UE5.1" "UE5.1" %}](https://www.youtube.com/watch?v=FUGqzE6Je5c&ab_channel=UnrealSensei)

{% imgx img/UE5/VPT.png %}

Let’s get started with setting this up.

## Configuration

### Setting up the GPU Compute shape.

1. First, log into your Oracle Cloud console

1. Once there, click on the hamburger menu

    {% imgx img/hamburger.png %}

1. Click "Compute"
    
    {% imgx img/compute.png %}

2. Click "Instances"
    
    {% imgx img/instances.png %}

3. Click "Create instance"

    {% imgx img/create.png %}

4. Change name

    {% imgx img/changeName.png %}

5. Choose the compartment that you want to run it on
    
6. This guide will focus on Ubuntu OS, so select Canonical Ubuntu.
7. Next, select Bare Metal Machine and GPU shape
8. Tick Terms and Conditions (Please note that the GPU shape will be charged against your account, even when instance is stopped)
9. Confirm by clicking on Select Shape

    {% imgx img/selectShape.png %}

### Setting up networking

1. For the purpuse of this guide we will create new virtual network called "GPUVCN" but you can reuse your exisiting one if you wish

    {% imgx  img/newVCN.png" %}

1. Also create new subnet and call it "GPUSUBNET"
    
    {% imgx img/newSubnet.png %}

1. Next, create new SSH keys (or upload your public key files.pub)

    {% imgx img/newSSH.png" %}

### Other settings

1. Running Unreal usually requires a lot of hard drive space, so I recommend selecting a boot volume starting from 500GB+. This may vary depending on your requirements

    {% imgx img/bootVolume.png" %}

2. I also recommend setting up a high performance VPU as this will speed things up when compiling, calculating shaders etc. Hit create once you finish

    {% imgx img/VPU.png %}


### Security rules

1. Once our instance is provisioned, let's create network security rules to allow connections for Remote desktop and SSH

    {% imgx img/NSG/1VNICnoNSG.png %}

1. Next, create a new security rule by navigating to our VCN

    {% imgx img/NSG/2openVCN.png %}

    {% imgx img/NSG/3createNSG.png %}

1. Navigate back to our compute instance and add the new Security Rule

    {% imgx img/NSG/4addAllowNSG.png %}

### Setting up remote desktop on your GPU Compute shape.

The next steps will focus on enabling the Ubuntu GUI on the GPU shape. These steps can be done either in Terminal or Visual Studio Code.

1. In order to connect to your instance, you can [follow this guide](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/testingconnection.htm)
1. Now that we are in, lets run few commands to set up our GUI for Ubuntu
2. Run the following to update and upgrade your OS and install nVidia drivers:

    ```console
    $ sudo apt-get update
    $ sudo apt-get upgrade
    $ sudo apt install libnvidia-common-515
    $ sudo apt install libnvidia-gl-515
    $ sudo apt install nvidia-driver-515
    ```

3. Install the Ubuntu GUI:
    
    ```console
    $ sudo apt install ubuntu-desktop
    ```

4. In order to enable remote access, let's [install XRDP](http://xrdp.org/), an open-source Remote Desktop Protocol server:
    
    ```console
    $ sudo apt install xrdp
    ```

5. Install net tools in case you need to debug your connectivity:
    
    ```console
    sudo apt install net-tools
    ```

6. Change your port setting from tcp6 to tcp4:
    
    ```console
    sudo nano /etc/xrdp/xrdp.ini
    ```

7. Inside that config file, change `port=3389` to `port=tcp://:3389`

8. The next step is to flush your iptables so that we can reset our linux firewall [for comprehencive tutarial around iptables check out this article](https://www.comparitech.com/net-admin/beginners-guide-ip-tables/). You can do that by running:

    ```console
    $ sudo iptables -F
    ```

3. Save your config:
    
    ```console
    sudo netfilter-persistent save
    ```

I recommend creating a new user and securing your admin account with a password, or whitelisting your external IP. You can find out how using [this video we did a while back](https://youtu.be/amqxaw2Ujn4?t=909).

You should now be able to access the virtual machine using the Remote Desktop solution of your choice. Just type your external IP to connect to your machine.
  
### Using Unreal Engine on your Cloud

1. Lets install chromium broswer as Ubuntu doesnt't come with it by default `sudo apt install -y chromium-browser`. 
2. Open chromium on your remote machine 
2. Navigate to <https://www.unrealengine.com/en-US/linux> and log in or create epic account
3. Download your preferred version of the engine and extract the zip file:

    {% imgx img/UE5/UEforLinux.png %}

4. To open Unreal Engine, run `/path/to/ue5.1/Engine/Binaries/Linux/UnrealEditor` in terminal:
    
    {% imgx img/UE5/Terminal.png %}
    
    {% imgx img/UE5/UEStart.png %}
          

## Outro

As a word of caution, I would say that Unreal Editor still require a bit of work in order to be as intuitive as it is on Windows. Hence, the use case here is probably focusing on accelerating the rendering for video generation and pixel streaming. 

