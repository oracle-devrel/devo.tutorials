# Virtual Desktop Infrastructure(VDI) for Unreal Engine 5 on OCI with nVidia GPU

Hey, in this blog I will share how to get Virtual Desktop Infrastructure setup on Oracle Cloud Infrastructure.

Few weeks ago Unreal Engine 5.1 was released, there is a lot of improvements many new cool features that for me are making this release kind of of a big deal.

[{% imgx img/UE5/UE5.png "UE5.1" "UE5.1" %}](https://www.youtube.com/watch?v=FUGqzE6Je5c&ab_channel=UnrealSensei)

{% imgx img/UE5/VPT.png %}

Let’s get started.

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
    
6. This guide will focus on Ubuntu OS so select Canonical Ubuntu.
7. Next select Bare Metal Machine and GPU shape
8. Tick T&C (Please note that GPU shape will be charged against your account event when instance is stopped)
9. Confirm but clicking on Select Shape

    {% imgx img/selectShape.png %}

1. For the purpuse of this guide we will create new virtual network called "GPUVCN" but you can reuse your exisiting one if you wish

    {% imgx  img/newVCN.png" %}

1. Also create new subnet and call it "GPUSUBNET"
    
    {% imgx img/newSubnet.png %}

1. Next, create new SSH keys (or upload your public key files.pub)

    {% imgx img/newSSH.png" %}

1. Running Unreal usually requires a lot of hard drive space, I recommend selecting a boot volume starting from 500GB+, but this may vary depending on your requirements

    {% imgx img/bootVolume.png" %}

2. I also recommend setting up high performance VPU as this will speed things up when compiling, calculating shaders etc. Hit create once you finished.

    {% imgx img/VPU.png %}

3. Once our instance is provisioned lets create networks security rules to allow connection for Remote desktop and SSH

    {% imgx img/NSG/1VNICnoNSG.png %}

4. Let’s create a new security rule by navigating to our VCN

    {% imgx img/NSG/2openVCN.png %}

    {% imgx img/NSG/3createNSG.png %}

5. Let’s navigate back to our compute instance and add our newly created Security Rule

    {% imgx img/NSG/4addAllowNSG.png %}

### Setting up remote desktop on your GPU Compute shape.

Next steps will focus on enabling Ubuntu GUI on the GPU shape. These steps can be done either in Terminal or Visual Studio Code.

1. In order to connect to your instance you can [follow this guide](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/testingconnection.htm)
1. Now that we are in lets run few commands to setup our GUI for Ubuntu
2. Let’s run following to update and upgrade our OS and install nVidia drivers

    ```console
    $ sudo apt-get update
    $ sudo apt-get upgrade
    $ sudo apt install libnvidia-common-515
    $ sudo apt install libnvidia-gl-515
    $ sudo apt install nvidia-driver-515
    ```

3. Let’s get Ubuntu GUI installed next
    
    ```console
    $ sudo apt install ubuntu-desktop
    ```

4. In order to enable remote access lets [install XRDP](http://xrdp.org/) - an open-source Remote Desktop Protocol server
    
    ```console
    $ sudo apt install xrdp
    ```

5. Followed by installing net tool so we can debug our connectivity
    
    ```console
    sudo apt install net-tools
    ```

6. Let change our port setting from tcp6 to tcp4
    
    ```console
    sudo nano /etc/xrdp/xrdp.ini
    ```

1. Inside that config file change `port=3389` to `port=tcp://:3389`

2. Next step is to flush our iptables so that we can reset our linux firewall (https://www.comparitech.com/net-admin/beginners-guide-ip-tables/) you can do that by running

    ```console
    $ sudo iptables -F
    ```

3. Save your config by running 
    
    ```console
    sudo netfilter-persistent save
    ```

1. I would recommend creating new user and securing your admin account with password or whitelisting your external IP you can find out how using [this video we did a while back](https://youtu.be/amqxaw2Ujn4?t=909)
4. You should now be able to access virtual machine via Remote Desktop solution of your choice. Just type your external IP to connect to your machine.
  
### Using Unreal Engine on your Cloud

1. Final thing to do is to get Unreal Engine downloaded to your machine. Since we have a GUI interface you can install by running in terminal `sudo apt install -y chromium-browser` and open browser on your machine 
2. Navigate to <https://www.unrealengine.com/en-US/linux> and log in/create an epic account
3. Download your preferred version of the engine and extract the zip file 

    {% imgx img/UE5/UEforLinux.png %}

4. To open Unreal Engine simply run following command `/path/to/ue5.1/Engine/Binaries/Linux/UnrealEditor` in terminal.
    
    {% imgx img/UE5/Terminal.png %}
    
    {% imgx img/UE5/UEStart.png %}
          

## Outro

As a word of caution I would say that Unreal Editor still require a bit of work in order to be as intuitive as it is on Windows. Hence use case here is probably focusing at accelerating the rendering for video generation and pixel streaming. 

