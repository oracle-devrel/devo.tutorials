# Virtual Desktop Infrastructure(VDI) for Unreal Engine 5 on OCI with nVidia GPU
Hey, in this blog I will share how to get Virtual Desktop Infrastructure setup on Oracle Cloud Infrastructure.

Few weeks ago Unreal Engine 5.1 was released, there is a lot of improvements many new cool features that for me are making this release kind of of a big deal.
<br>
[![UE5.1](img/UE5/UE5.png)](https://www.youtube.com/watch?v=FUGqzE6Je5c&ab_channel=UnrealSensei)

  <img src="img/UE5/VPT.png">

Let’s get started.

## Configuration

### Setting up the GPU Compute shape.

   1. First lets log into our Oracle Cloud console. <br>

  1. Once there lets click on the hamburger menu <br>
<img src="img/hamburger.png" />

  1. Click "Compute"<br>
   <img src="img/compute.png" />

  2. Click "Instances"<br>
   <img src="img/instances.png" />

  3. Click "Create instance"<br>

   <img src="img/create.png"/><br>

  4. Change name<br>

   <img src="img/changeName.png" /><br>

  5. Choose the compartment that you want to run it on
   
  6. This guide will focus on Ubuntu OS so select Canonical Ubuntu.
  7. Next select Bare Metal Machine and GPU shape
  8. Tick T&C (Please note that GPU shape will be charged against your account event when instance is stopped)
  9.  Confirm but clicking on Select Shape
      <img src="img/selectShape.png" />
1. For the purpuse of this guide we will create new virtual network called "GPUVCN" but you can reuse your exisiting one if you wish
   <img src="img/newVCN.png" />
2. I will also create new subnet and call it "GPUSUBNET"
      <img src="img/newSubnet.png" />
3. Next lets create new SSH keys (or upload your public key files.pub)
<img src="img/newSSH.png" />

1.  Running Unreal usually requires a lot of hard drive space, I recommend selecting boot volume starting from 500GB+ but this may vary depending on your requirements
         <img src="img/bootVolume.png" />

2. I also recommend setting up high performance VPU as this will speed things up when compiling, calculating shaders etc. Hit create once you finished.

      <img src="img/VPU.png" />

3. Once our instance is provisioned lets create networks security rules to allow connection for Remote desktop and SSH
   <img src="img/NSG/1VNICnoNSG.png"
4. Let’s create a new security rule by navigating to our VCN
   <img src="img/NSG/2openVCN.png"><br>
   <img src="img/NSG/3createNSG.png"><br>
5. Let’s navigate back to our compute instance and add our newly created Security Rule
   <img src="img/NSG/4addAllowNSG.png"><br>

### Setting up remote desktop on your GPU Compute shape.

Next steps will focus on enabling Ubuntu GUI on the GPU shape. These steps can be done either in Terminal or Visual Studio Code.

1. In order to connect to your instance you can follow this guide
https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/testingconnection.htm
1. Now that we are in lets run few commands to setup our GUI for Ubuntu
2. Let’s run following to update and upgrade our OS and install nVidia drivers<br>
    `sudo apt-get update`<br>
    `sudo apt-get upgrade` <br>
    `sudo apt install libnvidia-common-515`<br>
    `sudo apt install libnvidia-gl-515`<br>
    `sudo apt install nvidia-driver-515`<br>
3. Let’s get Ubuntu GUI installed next<br>
   `sudo apt install ubuntu-desktop`
4. In order to enable remote access lets instal XRDP - an open-source Remote Desktop Protocol server http://xrdp.org/<br>
   `sudo apt install xrdp`
we wi5. Follwed by installing net tool so we can debug our connectivity
    `sudo apt install net-tools`
6. Let change our port setting from tcp6 to tcp4
  `sudo nano /etc/xrdp/xrdp.ini` 
1. Inside that config file change `port=3389` to `port=tcp://:3389`
2. Next step is to flush our iptables so that we can reset our linux firewall (https://www.comparitech.com/net-admin/beginners-guide-ip-tables/) you can do that by running <br>`sudo iptables -F`
3. Save your config by running 
   `sudo netfilter-persistent save`
1. I would recommend creating new user and securing your admin account with password or whitelisting your external IP you can find out how using this video we did a while back(https://youtu.be/amqxaw2Ujn4?t=909)
4. You should now be able to access virtual machine via Remote Desktop solution of your choice. Just type your external IP to connect to your machine.
  
### Using Unreal Engine on your Cloud
   1. Final thing to do is to get Unreal Engine downloaded to your machine. Since we have a GUI interface you can install by running in terminal `sudo apt install -y chromium-browser` and open browser on your machine 
   2. Navigate to https://www.unrealengine.com/en-US/linux and log in/create epic account

   3. Download your preferred version of the engine and extract the zip file 
   <img src="img/UE5/UEforLinux.png"><br>
   4. To open Unreal Engine simply run following command `/path/to/ue5.1/Engine/Binaries/Linux/UnrealEditor` in terminal.
         <img src="img/UE5/Terminal.png"><br>
        <img src="img/UE5/UEStart.png"><br>
        

## Outro

As a word of caution I would say that Unreal Editor still require a bit of work in order to be as intuitive as it is on Windows. Hence use case here is probably focusing at accelerating the rendering for video generation and pixel streaming. 

