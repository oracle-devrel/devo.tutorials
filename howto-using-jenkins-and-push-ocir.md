---
title: How to: Using Jenkins to build container image and push to OCIR
parent: tutorials
tags:
- open-source
- ocir
- jenkins
- ci/cd
categories:
- devops
- opensource
thumbnail: assets/verrazzano-logo.png
date: 2021-11-12 09:11
description: How to: Using Jenkins to build container image and push to OCIR
toc: true
author:
  name: Ali Mukadam
  home: https://lmukadam.medium.com
  bio: |-
    Technical Director, Asia Pacific Center of Excellence.

    For the past 16 years, Ali has held technical presales, architect and industry consulting roles in BEA Systems and Oracle across Asia Pacific, focusing on middleware and application development. Although he pretends to be Thor, his real areas of expertise are Application Development, Integration, SOA (Service Oriented Architecture) and BPM (Business Process Management). An early and worthy Docker and Kubernetes adopter, Ali also leads a few open source projects (namely [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke)) aimed at facilitating the adoption of Kubernetes and other cloud native technologies on Oracle Cloud Infrastructure.
  linkedin: https://www.linkedin.com/in/alimukadam/
redirect_from: "/collections/tutorials/deploying-the-argo-project-on-oke/"
---
One thing I really like about OCI is its openness: the openness towards developers and letting them use and embrace entirely different software and solution stacks, even if they are seemingly competitive to some of OCI’s own services.

Case in point: the ultra-competitive Continuous Integration landscape. There’s the new [DevOps service](https://docs.oracle.com/en-us/iaas/Content/devops/using/home.htm) in OCI. Heck, I even wrote about using [Tekton](https://lmukadam.medium.com/running-continuous-integration-on-oke-with-tekton-353684c15730) before.
But in this tutorial, we will see how to use Oracle Linux to deploy [Jenkins](https://www.jenkins.io/) on OCI for building containers and pushing to [OCIR (OCI Registry)](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm#top).
Below is conceptually what we will try to achieve:

{% img aligncenter assets/jenkins-1.png 1024 557 Continuous Integration flow %}

1. A Developer pushes code to a git repo (in this case, GitHub)
2. Jenkins detects a push and starts a new build
3. After a successful build, Jenkins pushes a new container image to OCIR

### Installing Jenkins
We will start by installing Jenkins on a compute instance in a private subnet. Create your private subnet without a security list and create an NSG with the following egress and ingress rules respectively:

{% img aligncenter assets/jenkins-2.png 1024 557 NSG rules for Jenkins instance %}

Next, create your instance by choosing Oracle Linux 8. Make sure you select the correct subnet and NSG. Note the private IP address and you can ssh to it using a bastion host:

```
ssh -i ~/.ssh/id_rsa -J opc@11.22.33.44 opc@10.0.3.14
```

Next, configure firewalld:

```
sudo firewall-cmd --permanent --add-service=jenkins
sudo firewall-cmd --reload
```

Note that you can also automate this with terraform and cloud init. In this case, you need to run `firewall-offline-cmd` and not use the `permanent` option:

```
# Configuring firewalld using cloud-init
firewall-offline-cmd --add-service=jenkins
```

Next, install JDK:

```
sudo dnf install -y java-11-openjdk.x86_64
```

Check Java is in your path:

```
$ java -version
openjdk version "11.0.13" 2021-10-19 LTS
OpenJDK Runtime Environment 18.9 (build 11.0.13+8-LTS)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.13+8-LTS, mixed mode, sharing)
```

Install Jenkins and git:

```
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat/jenkins.repo
sudo dnf config-manager --enable jenkins --enable ol8_developer_EPEL
sudo rpm --import http://pkg.jenkins.io/redhat/jenkins.io.key
sudo dnf install -y jenkins git
sudo systemctl enable jenkins & sudo systemctl start jenkins
```

### Installing container-tools
Since we are going to be building containers, we also need to install the necessary tools and daemons. On Oracle Linux 7, we would have installed docker-engine but we don’t build docker-engine for OL 8 anymore. Instead, we recommend you use install podman and related utilities:

```
sudo dnf module install -y container-tools:ol8
```

This will also install buildah and skopeo. The container tools (podman, buildah, skopeo) are to Docker what [Blade](https://www.imdb.com/title/tt0120611/) is to vampires: [all of its strengths, none of its weaknesses](https://www.youtube.com/watch?v=xdUlvsdgWQU&t=26s). Among those strengths, the ability to reuse and keep using existing or new Dockerfiles stands tall. That saves developers a lot of trouble of having to rewrite build scripts.

What about those weaknesses? Well, while Docker requires root access to build your Docker images with the Docker daemon, both buildah and podman do not. This means no more risk of breaking out of the container into the underlying host.

That being said, old (or bad or both) habits die hard I’m still wired to use the Docker commands and probably others too:

```
docker search
docker build
docker push
....
```

So while there are podman’s equivalent commands, I think a lot of CI tools are still expecting to be able to run docker commands. This is where the podman-docker package comes to the rescue. The podman-docker package provides docker aliases to podman and saves you the trouble of having to change your scripts or rewire your cerebellum where your Docker memory has been engraved. Let’s install it:

```
sudo dnf install -y podman-docker
```

Now, we can test it:

```
docker
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.
Error: missing command 'podman COMMAND'
Try 'podman --help' for more information.
```

Likewise, if we search for an image:

```
docker search ubuntu
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.
INDEX       NAME                                                               DESCRIPTION                                      STARS       OFFICIAL    AUTOMATED
docker.io   docker.io/library/ubuntu                                           Ubuntu is a Debian-based Linux operating sys...  13130       [OK]
...
...
```

Configuring Jenkins
We now have to configure Jenkins, install the plugins etc. Start a new terminal session to Jenkins to establish a tunnel:

```
ssh -L 8080:localhost:8080 -i ~/.ssh/id_rsa -J opc@11.22.33.44 opc@10.0.3.14
```

Using your browser, access Jenkins at http://localhost:8080. You’ll be asked to supply the initial admin password:

{% img aligncenter assets/jenkins-3.png 1024 557 Provide the initial Admin password %}

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy and paste the password and click on the ‘Continue’ button. You’ll next be asked to install suggested plugins:

{% img aligncenter assets/jenkins-4.png 1024 557 Install suggested plugins %}


Go ahead and install the suggested plugins:

{% img aligncenter assets/jenkins-5.png 1024 557 Installing the suggested plugins %}


Select “Skip and continue as admin”, then save and finish on the instance configuration page. 

Next, We need to install a few Jenkins plugins:
- Click on “Manage Jenkins” > “Manage Plugins” > Available
- Use the search bar to search for “Docker”, “Docker Pipeline”, “GitHub Authentication” and “Blue Ocean Aggregator” plugins
- Select the plugins as you find them
- Click “Install without restart”

Since Jenkins will be running as the “jenkins” user, we also need to ensure that podman can run in rootless mode:

```
sudo echo jenkins:10000:65536 >> /etc/subuid
sudo echo jenkins:10000:65536 >> /etc/subgid
```

### Configuring OCIR Credentials
First, we need to do 2 things in OCI:
1. Create an Auth Token to login
2. Obtain the tenancy namespace

Let’s do that:
- Login to OCI Console and click on the “Profile” icon > “User settings”
- Click on “Auth Tokens”
- Click on “Generate Token”
- Click on “Copy” and store it somewhere safe like a password manager
- Click on the “Profile” icon again > “Tenancy”
- Locate “Object Storage Namespace” and note down its value. This is the

Following and adapting from [this article](https://medium.com/@gustavo.guss/jenkins-building-docker-image-and-sending-to-registry-64b84ea45ee9), we can now create the credentials for OCIR:
- Click on “Manage Jenkins” > “Manage Credentials”
- Click “Jenkins” > “Global credentials” > “Add Credentials”
- Select “Username with password” for Kind
- Select “Global….” for Scope
  - If you are using a native OCI user, the username will be <tenancy-namespace>/<username>
  - If you are using an IDCS user, the username will be<tenancy-namespace>/oracleidentitycloudservice/<username>
- Password is your the value you obtained when you created an Auth Token
- Enter “OCIR” for ID

Note that in the above, for the purpose of writing, I used my own credentials. However, I recommend you :
- create a dedicated Jenkins user
- add the Jenkins user to a group
- create a policy that gives the group the necessary and limited privileges that will allow it to push images to OCIR.

# Creating a repository in OCIR
Next, we need to create a repository in OCIR. First, let’s clear a common confusion: a repository is everything that exists between the tenancy’s namespace and the tag in the repo path.

Let’s say we have the following 2 repos for Acme Corp:
- tenancy_namespace/website:1.0
- tenancy_namespace/acme/blog:1.0

The first repository is “website” whereas the second repository is “acme/blog”. In other words, the repository includes the image’s name. Secondly, each region has its own URI. It is typically the region’s IATA code prepended to ocir.io e.g. London is lon.ocir.io, Sydney is syd.ocir.io, San Jose is sjc.ocir.io and so on.
Let’s create one for acmewebsite.

{% img aligncenter assets/jenkins-6.png 1024 557 Creating a repository %}


Creating a pipeline in Jenkins
The last thing we are going to do is creating a pipeline in Jenkins. We want to point Jenkins to a GitHub repo and execute a series of steps that will result in the building and pushing of a container image to our repository created previously. Again, I’m more or less following [this blog](https://medium.com/@gustavo.guss/jenkins-building-docker-image-and-sending-to-registry-64b84ea45ee9) (hat tip) and adapting it to our needs:

- Click on “New Item”
- Enter a name e.g. “acmewebsite”
- Check GitHub project and enter the url: https://github.com/hyder/acmewebsite
- For pipeline, select Pipeline script and enter the following:

```
pipeline {
    environment {
        registry = "region_code".ocir.io/namespace/acmewebsite"
        registryCredential = 'ocir'
        dockerImage = ''
    }
    agent any
    stages {
        stage('SCM Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/hyder/acmewebsite.git'
            }
        }
        stage('Building image') {
            steps{
                script {
                    dockerImage = docker.build(registry + ":${BUILD_NUMBER}")
                }
            }
        }
        stage('Push to OCIR') {
            steps {
                script {
                    docker.withRegistry( 'https://region_code.ocir.io', registryCredential ) {
                    dockerImage.push()
                    }
                }
            }
        }
        stage('Cleanup') {
            steps{
                sh "docker rmi $registry:$BUILD_NUMBER"
            }
        }
    }
}
```

Replace the above region code with your appropriate values. Note that we are not configuring a full blown pipeline here; we only want Jenkins to build an container image and push it to OCIR.

Save and click on Build Now.

{% img aligncenter assets/jenkins-7.png 1024 557 Building the image %}


You can also open the Blue Ocean view:

{% img aligncenter assets/jenkins-8.png 1024 557 Blue Ocean view of Jenkins pipeline %}

Navigate back to OCI Console > Developer Services > Container Registry. You should now be able to see the container image in OCIR:

{% img aligncenter assets/jenkins-79.png 1024 557 BContainer image in OCIR %}


Conclusion
In the example above, we used an inline Pipeline script. You can also store your pipeline in a Jenkinsfile which you can then check in the GitHub repo. However, you must ensure that sensitive variables such as the tenancy namespace and credentials are not checked in along with the code.

This concludes our exercise of getting Jenkins to build a container image and push it to OCIR for us.