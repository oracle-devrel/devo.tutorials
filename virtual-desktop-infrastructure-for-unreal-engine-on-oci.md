---
title: Virtual Desktop Infrastructure(VDI) for Unreal Engine 5 on Oracle Cloud Infrastructure with nVidia GPU
parent:
- tutorials
tags: []
categories: []
date: 2022-12-22 08:00
description: Get Virtual Desktop Infrastructure set up on Oracle Cloud Infrastructure with nVidia GPU.
toc: true
author: oracle-developers
slug: virtual-desktop-unreal-engine
---

In this tutorial you'll learn how to set up Virtual Desktop Infrastructure on Oracle Cloud Infrastructure (OCI).

A few weeks ago, Unreal Engine 5.1 was released. There are a lot of improvements and many new cool features that, for me, are making this release kind of of a big deal.

[{% imgx assets/vdi-unreal-UE5.jpg "UE5.1" %}](https://www.youtube.com/watch?v=FUGqzE6Je5c&ab_channel=UnrealSensei)

{% imgx assets/vdi-unreal-VPT.jpg %}

Let’s get started with setting this up.

## Configuration

### Setting up the GPU Compute shape.

1. First, log into your Oracle Cloud console

1. Once there, click on the hamburger menu

    {% imgx assets/vdi-unreal-hamburger.jpg %}

1. Click "Compute"
    
    {% imgx assets/vdi-unreal-compute.jpg %}

2. Click "Instances"
    
    {% imgx assets/vdi-unreal-instances.jpg %}

3. Click "Create instance"

    {% imgx assets/vdi-unreal-create.jpg %}

4. Change name

    {% imgx assets/vdi-unreal-changeName.jpg %}

5. Choose the compartment that you want to run it on
    
6. This guide will focus on Ubuntu OS, so select Canonical Ubuntu.
7. Next, select Bare Metal Machine and GPU shape
8. Tick Terms and Conditions (Please note that the GPU shape will be charged against your account event when instance is stopped)
9. Confirm by clicking on Select Shape

    {% imgx assets/vdi-unreal-selectShape.jpg %}

### Setting up networking

1. For the purpuses of this guide we will create new virtual network called "GPUVCN" but you can reuse your exisiting one if you wish

    {% imgx assets/vdi-unreal-newVCN.jpg %}

1. Also create new subnet and call it "GPUSUBNET"
    
    {% imgx assets/vdi-unreal-newSubnet.jpg %}

1. Next, create new SSH keys (or upload your public key files.pub)

    {% imgx assets/vdi-unreal-newSSH.jpg %}

### Other settings

1. Running Unreal usually requires a lot of hard drive space, so I recommend selecting a boot volume starting from 500GB+. This may vary depending on your requirements

    {% imgx assets/vdi-unreal-bootVolume.jpg %}

2. I also recommend setting up a high performance VPU as this will speed things up when compiling, calculating shaders etc. Hit create once you finish

    {% imgx assets/vdi-unreal-VPU.jpg %}


### Security rules

1. Once our instance is provisioned, let's create network security rules to allow connections for Remote desktop and SSH

    {% imgx assets/vdi-unreal-1VNICnoNSG.jpg %}

1. Next, create a new security rule by navigating to our VCN

    {% imgx assets/vdi-unreal-2openVCN.jpg %}

    {% imgx assets/vdi-unreal-3createNSG.jpg %}

1. Navigate back to our compute instance and add the new Security Rule

    {% imgx assets/vdi-unreal-4addAllowNSG.jpg %}

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

5. Install net tools so we can debug our connectivity:
    
    ```console
    sudo apt install net-tools
    ```

6. Change your port setting from tcp6 to tcp4:
    
    ```console
    sudo nano /etc/xrdp/xrdp.ini
    ```

7. Inside that config file, change `port=3389` to `port=tcp://:3389`

8. The next step is to flush your iptables so that we can reset our linux firewall (https://www.comparitech.com/net-admin/beginners-guide-ip-tables/). You can do that by running:

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

1. Get Unreal Engine downloaded to your machine. Since we have a GUI interface, you can install it in terminal by running `sudo apt install -y chromium-browser`. 
2. Open browser on your machine 
2. Navigate to <https://www.unrealengine.com/en-US/linux> and log in/create an epic account
3. Download your preferred version of the engine and extract the zip file:

    {% imgx assets/vdi-unreal-UEforLinux.jpg %}

4. To open Unreal Engine, run `/path/to/ue5.1/Engine/Binaries/Linux/UnrealEditor` in terminal:
    
    {% imgx assets/vdi-unreal-Terminal.jpg %}
    
    {% imgx assets/vdi-unreal-UEStart.jpg %}
          

## Outro

As a word of caution, I would say that Unreal Editor still require a bit of work in order to be as intuitive as it is on Windows. Hence, the use case here is probably focusing on accelerating the rendering for video generation and pixel streaming. 

