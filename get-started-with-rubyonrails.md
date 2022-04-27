---
title: Get started with Ruby in Rails on OCI
parent: tutorials
tags:
- ruby
- rails
- MySQL
- RubyOnRails
categories:
- frameworks
- cloudapps
thumbnail: ruby_on_rails_logo.png
date: 2022-01-28 17:03
description:
author: hassan-ajan
published: true
---
{% imgx https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Ruby_On_Rails_Logo.svg/200px-Ruby_On_Rails_Logo.svg.png "Ruby on Rails Logo" %}

## Introduction

Ruby on Rails is a rapid development framework It’s used by over a million websites amongst them AirBNB, Bloomberg, Github, Gitlab, Couchsurfing and many more.

The ruby language is easy to understand as it’s close to English making it great for beginners. In this tutorial we'll show you how to get started with a new Ruby on Rails project and how to bring your existing Ruby on Rails application to OCI.

## TLDR

Don't have time to read the whole article, use the "Deploy Button" to provision the Ruby on Rails environment with a few clicks. On this environment you can build a new application or bring your existing Ruby on Rails application to OCI. 

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/haj/oci-arch-rubyonrails-mds/archive/refs/tags/latest.zip)

## Set up environment automatically

The quickest way to setup a ruby on rails environment on OCI is by using the "Deploy Button".

The button takes you to Oracle Resource Manager which runs Terraform code that will provision the full Ruby on Rails environment.

The following ressources will be created:


| #        | Service Name          |Additional Info  |
| ------------- |:-------------:| -----:|
| 1 | Virtual Cloud Network |  |
| 1 | Public subnet      |    |
| 1 | Private subnet      |   |
| 1 | VM - Ubuntu   |   1 OCPU, 8 Gb Memory 1 OCPU. can be scaled up to 1024 GB Memory and 128 OCPUs |
| 1 | MySQL Database Service     |  can be scaled up to run in HA with up to 3 nodes |
| 1 | Bastion Host      |   can optionally be replaced with bastion service |
| 1 | Load balancer 10 mpbs      | flex loadbalancer upto 4000 mbps |


The public subnet will contain the following ressources:

- Loadbalancer
- Bastion Host

The private subnet will contain the following ressources:

- Ruby on Rails VM(s)
- Managed MySQL Database

### Software packages installed on the VMs

#### RBENV

Package manager for ruby to make it easy to manage different ruby versions and gem packs 

#### Nodejs

The bootstrap script in the gihub repo shows how the VMs are configured and all the packages that are installed:

You can check the script on Github: [Bootstrap Script](https://github.com/haj/oci-arch-rubyonrails-mds/blob/main/scripts/ror_bootstrap.sh). 

If you have deployed the environment using the deploy button you can skip the next section. The bootstrap script has been run automatically when the VMs were provisioned. 


## How to setup environment automatically

1. Click the deploy button [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/haj/oci-arch-rubyonrails-mds/archive/refs/tags/latest.zip)
2. If you aren't already signed in, when prompted, enter the tenancy and user credentials.
3. Review and accept the terms and conditions.
4. Select the region where you want to deploy the stack.
5. Follow the on-screen prompts and instructions to create the stack.
6. After creating the stack, click **Terraform Actions**, and select **Plan**.
7. Wait for the job to be completed, and review the plan. To make any changes, return to the Stack Details > page, click **Edit Stack**, and make the required changes. Then, run the **Plan** action again.
8. If no further changes are necessary, return to the Stack Details page, click **Terraform Actions**, and select **Apply**.

## How to setup environment manually

If you prefer to setup the environment manually you need to provision the resources and then  install the ruby on rails environment.

Provisioning the VM and MySQL database is not covered in this guide.

Once you have a VM and MySQL database ready you can proceed to the next step to install Ruby on Rails.

### Minimum requirements

- VM running Ubuntu 20.04
- MySQL Database

## How to install Ruby on Rails on Ubuntu 20.04 with rbenv

SSH to your VM and run the following commands
Make sure to run the commaned with a user that has sudo rights. On Ubuntu the Ubuntu user is usually fine: 

Update apt:

```bash
sudo apt update
```

Install ruby manager, mysql-client and other dependencies:

```console
sudo apt-get install -y build-essential git libsqlite3-dev libssl-dev libzlcore-dev mysql-client libmysqlclient-dev git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs npm
```

Install yarn:

```console
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt update
sudo apt install -y yarn
```

Install ruby package manager to help install and manage different ruby versions

```console
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
source ~/.bash_profile

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

Now we are ready to install ruby. If you need a different version, change the version number. 

```console
rbenv install 3.0.1
```

Check that the correct version of ruby is installed

```console
ruby -v
```
Use version 3.0.1 and make it default.

```console
rbenv global 3.0.1
rbenv local 3.0.1
```

Reload the environment variables to ensure the correct ruby binaries are run:

```console
source ~/.bash_profile
```

Let's install Rails framework and bundler gem:

```console
gem install rails
gem install bundler
```

Congratulations you have now installed Ruby on Rails on your VM. 

## Create your Ruby on Rails application

In this section we will create a rails applcation using the built-in scaffolding methods of rails. We will connect the rails app to the database provisioned. 

Let's create a directory where our app will reside and make the Ubuntu user the owner of the directory

```console
sudo mkdir /opt/apps
sudo chown ubuntu:ubuntu /opt/apps
```

Create a new app that is preconfigured with a mysql adapter:

```console
cd /opt/apps
rails new myapp -d mysql
```

Open up port 8080 for incoming HTTP requests:

```console
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8080 -j ACCEPT
#SAVE STATE
```

Edit the database config file and add your MySQL username and MySQL database name and MySQL host URL:

```console
nano /opt/apps/myapp/config/database.yml
```

Create a database schema. If you have already created a database schema you can skip this:

```console
rake db:create
```

Run all migration scripts to create the tables in the DB. This step needs to run everytime you makes change to table definitions:

```console
rake db:migrate
```

Start rails server as a background process, listen on port 8080 and bind all interfaces and send log output to startup.log:

```console
rails s -p 8080 -b 0.0.0.0 >> ./log/startup.log &
```

### Accessing the application

If you configured your VM manually you should now be able to access your new rails application on `http://my-vm-public.ip:8080`.

If you provisioned your environment automatically using the "Deploy Button" you can access the application through the load balancer, e.g. `http://my-load-balancer-ip`.

Check Oracle Resource Manager output for the ip or check the load balancer page.

The load balancer is configured to listen on port 80 and forwards all traffic to the VM where the Ruby on Rails application is running.

The load balancer will forward traffic to all the VMs if you provisioned more than one VM.  

## Summary

A new Rails App is created in the directory `/opt/apps/myapp`.

A database schema is created on the MySQL server.

Database schema name: `myapp`

The app is configured to connect to the database. Configuration can be found in: `/opt/apps/app/config/database.yml`

## How to deploy your existing application

Before deleting the app we will take a backup of the database.yml file. We'll need it later.

```console
cp /opt/apps/myapp/config/database.yml  /opt/apps/bck_database.yml
```

1. Delete the existing vanilla Ruby on Rails app created in `/opt/apps/myapp`

    ```console
    rm -rf /opt/apps/myapp
    ```

2. Copy your application to the server using scp


    ```console
    scp myapp.zip ubuntu@server-ip:/opt/apps/
    ```

3. Unpack the application 

    ```console
    unzip myapp.zip ./myapp/
    ```

4. Copy the generated database config file

    ```console
    cp /opt/apps/bck_database.yml ./myapp/config/database.yml
    ```

5. Or edit the existing database config file (`database.yml`)

    ```yaml
    username: 
    password: 
    url: 
    ```

6. Migrate your data to the MySQL Database 

7. Install dependencies 

    ```console
    bundle install
    ```

8. Run Rails migrations

    ```console
    rake db:migrate 
    ```

9. Start the server

    ```console
    rails s -b 0.0.0.0 -p 8080
    ```

## How to change Ruby version

The default ruby version installed is 3.0.1. If you need a different ruby version simply run: 

```console
rbenv install 3.0.2
```

You can see available Ruby version by running: 

```console
rbenv install list 
```

In this part we take a look at the following topics, stay tuned:

**How to build a new application**

- Scaffold 
- Developer in the cloud 
- Connect VSCode with SSH 
- Connect Netbeans with SSH and bastion
- Connect Jdeveloper with SSH and bastion

**My top 10 favorite gems**

- Check out Rails Admin Gem
- Check out Devise 
- CanCan
- Bootstrap

