---
title: Go Software Engineering and Automation with OCI DevOps
parent:
- tutorials
- way-to-go-on-oci
redirect_from: "/tutorials/way-to-go-on-oci/go-on-oci-devops-article-2"
tags:
- open-source
- devops
- get-started
- automation
- back-end
- go
- iac
categories:  [clouddev, cloudapps]
thumbnail: assets/way-to-go-on-oci-article-2-thumbnail-overview.png
date: 2022-05-01 11:00
description: How to build, deploy, test and expose Go applications on Oracle Cloud Infrastructure with DevOps, Resource Manager, Compute and API Gateway.
toc: true
author: lucasjellema
redirect: https://developer.oracle.com/tutorials/way-to-go-on-oci/go-on-oci-devops-article-2/
---
{% imgx alignright assets/way-to-go-on-oci-article-2-thumbnail-overview.png 400 400 "Go Build & Deployment on OCI" %}

This is the second installment in a five part series about Go and Oracle Cloud Infrastructure. This series discusses how Go applications can be created and run on Oracle Cloud Infrastructure - in Compute Instances (VMs), containerized on Kubernetes or as serverless Functions. The articles show how to automate the build and deployment of these Go applications using OCI DevOps. An important topic is how to use OCI services from Go applications - both those running on OCI as well as Go code running elsewhere. Some of the OCI services discussed are Object Storage, Streaming, Key Vault and Autonomous Database. 

In order to follow along with these articles, readers should have at least basic knowledge of how to create Go applications. It is assumed that readers have access to their own Go development environment. Some of the examples and screenshots will specifically mention VS Code as development tool. However, other editors and IDEs can be used as well. The Go code presented in these articles demonstrates a number of mechanisms in their simplest form for maximum clarity and with the least dependencies. Readers should not expect meaningful functionality or production ready code. 

The articles describe how to get Going on OCI and to try out the examples, readers will need to have access to an OCI tenancy with permissions to create the OCI resources discussed in these articles. Most of the resources used are available in the *Aways Free Tier* (Compute Instance, VCN, Autonomous Database, Object Storage, Logging, Resource Manager) or have a free allotment tier for limited monthly usage (Functions, API Gateway, Streaming, Vault, DevOps). 


## Introduction

The first part describes provisioning of a Compute Instance based on the Oracle Linux Cloud Developer image, opening it up for inbound and outbound network activity, creating and running a Go application that serves HTTP requests and connecting logging produced by the application to OCI Logging. This part takes the software engineering, build and deployment of the application to the next level, using the compute instance created in the previous installment. Automation is the name of the game and the OCI DevOps service is introduced for storing the Go source code, building the application executable and storing it as deployable artifact, deploying that artifact to the Compute Instance. The last step in this article is exposing an HTTP endpoint for that application through an OCI API Gateway. 

The detailed steps in this article:
* set up the OCI DevOps project with the artifact registry and source code repository

* load the application resources for the Go application as code resources for the OCI resources into the source code repository

* create OCI DevOps Build Pipeline for producing a deployable artifact from Go source code; include Go fumpting/linting and testing in the pipeline. Deliver the artifact to the OCI Artifact Repository. Trigger the pipeline manually, to see it in action; watch lint and test. Verify the artifact that is produced.

* create an OCI DevOps Deployment Pipeline that takes the built Go app artifact - a binary executable - and deploys it to the VM (and makes it run). Add a trigger of the Deployment Pipeline in the Build Pipeline.
Manually trigger the build pipeline. The Go application is deployed to the VM. 

* Create API Gateway with a new API Deployment with a route for the HTTP endpoint exposed by the Go app that was just deployed to the VM. Check out HTTP calls to the now public API – see them handled. Apply a little request manipulation in the API Gateway's route to the Go application 

## Create DevOps Project with Code Repository and Artifact Registry

The Oracle Cloud Infrastructure (OCI) DevOps service is an end-to-end, continuous integration and continuous delivery (CI/CD) platform for developers. It provides code repositories, build servers that run automated CI/CD pipelines, an artifact registry for storing the deployable built artifacts and deployment pipelines that rollout new software to OCI environments. The starting point in OCI DevOps is a project - a logical grouping of DevOps resources needed to implement a CI/CD workflow. DevOps resources can be artifacts, build pipelines, deployment pipelines, external connections (to GitHub or GitLab code repositories), triggers (definitions of events that should trigger a build pipeline or a deployment pipeline ), and environments (into which deployment is performed -  a Function application, a group of Compute instances, or a Container Engine for Kubernetes (OKE) cluster).

Using OCI DevOps is largely free. However, you do have to pay for the build server — but only the pay-per-use compute costs and the network traffic to and from outside OCI boundaries. Running the Deployment Pipelines is not charged to you. Of course the runtimes to which the applications are deployed, need to be paid for and the storage required for the Artifact Registry as well as the Container Registry is charged to your cloud account as well. 

### Create DevOps Project
Before we can create a DevOps project, we first need to create a Topic in the Notifications service. Messages representing events in OCI services or alarms that get triggered or messages explicitly produced by custom application components are asynchronously published on a Topic and subsequently delivered to subscribers to the Topic. Project Notifications are published to a Topic to keep you apprised of important events and the latest project status. They also alert you if you need to take any necessary action such as approving a workflow. You must therefore create a Topic and add a subscription to the topic. 

Open the OCI console. Type *notific* in search field; then navigate to *Notifications*. Click on the button *Create Topic*. Enter the name of the topic - for example *devops-topic* and optionally provide a description of the topic. Click on *Create* to have the topic resource provisioned.

The newly created Topic is shown in the console. Click on the name to navigate to the details page. Click on *Create Subscription* - to create a subscription to have emails sent to your email address for DevOps project events that require your attention. Note: in addition to email, subscriptions can also be created for Slack, PagerDuty, web hook, SMS and OCI Functions.

Click on *Create* to create the subscription. 

The new subscription is shown with status *Pending*. The subscription only becomes active when the email address is confirmed. Check your mailbox. You should find a mail from OCI that invites you to confirm your subscription. When you click the link in the mail (or copy the url for the link to a browser window) you are taken to a web page that informs you that the subscription was confirmed. At this point, messages published to the topic will be relayed as email to the address you have subscribed with.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-email-subscription-confirmation.png 1200 647 "Email invitation to confirm subscription on topic" %}   

Let's now create a DevOps project. Ensure that the context compartment is the right one - in my case *go-on-oci*, created in part 1 of this series. Type *devops* in search field; then navigate to *Overview*. An overview is shown of all DevOps projects - probably none at this point.

Click on the button Create DevOps Project.
{% imgx aligncenter assets/way-to-go-on-oci-article-2-createdevopsproject.png 1200 564 "Start creation of a new DevOps project" %}
Type the name of the project, for example *go-on-oci*, and optionally enter a description - "Resources for the Way to Go on OCI application".

Click on *Select Topic* and select the Topic you have just created. Then click on *Create DevOps Project*.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-create-devopsproject2.png 1200 564 "Enter details for the new DevOps project" %}

The DevOps project is created. Its overview page is shown. 
{% imgx aligncenter assets/way-to-go-on-oci-article-2-devopsproject-created.png 1200 564 "Enable logging for freshly created DevOps project" %}

One last step to complete the project definition: enable logging. Click on the button *Enable Log*. This takes you to a tab labeled *Logs*. Toggle the switch to *Enable Log*. 

This brings up a pane where the Log Group and the name of the Log are defined. In article 1 of this series, we created a Log Group *go-on-oci-logs* which can serve us now. If you want to use a different Log Group or do not have that group available (anymore), click on the link *Create New Group*. Provide a name for the Log. Then click on *Enable Log*.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-enable-logging.png 1200 487 "Toggle the DevOps Logs enabled switch to the on position" %}

The new log is shown with status *Creating*. After a minute or so, the status will be be updated to *Active*. Now the DevOps project is fully primed, ready for some action. 

Note: in order to allow other users to access the DevOps Project, you need to set up the appropriate policies. Read [details about how go get started with the DevOps service in the OCI Documentation](https://docs.oracle.com/en-us/iaas/Content/devops/using/getting_started.htm#getting_started_with_devops) 


### Create Code Repository

OCI DevOps offers git style code repositories — similar to GitHub, GitLab or Azure DevOps. You pay for storage only — no additional charges for the git repository overhead. You get a git repo that you access in a secure way — from your command line or local git GUI tool just like you are used to. Or through a simple, straightforward browser UI that for example allows searching for sources, commits and inspecting pull requests. Although this UI is clearly not meant to be your next git power tool, it can still be quite convenient for some quick browsing.

On the DevOps project overview page, click on the card *Create repository*. Enter the name for the repository - for example *go-on-oci-repo* and optionally a description. Then click on the button *Create repository*. 

After a few seconds, the details for the new code repository appear. The repository is empty at this point. And it cannot yet be cloned to your local environment. You first need to create a authentication token that can be used for connecting your local git tooling to this OCI Code Repository.

Before you create that token (or reuse an existing token), click on the button *HTTPS*. A command is now shown for cloning the new git code repository. The command looks like:

```
git clone https://devops.scmservice.us-ashburn-1.oci.oraclecloud.com/namespaces/idtwlqf2hanz/projects/go-on-oci/repositories/go-on-oci-repo
```

But the region key and namespace will be different in your case.

To create an Authentication Token, follow these steps: 
    1. In the top-right corner of the Console, open the Profile menu and click User Settings.
    1. Under Resources, click Auth Tokens.
    1. Click Generate Token. Enter a description that indicates what this token is for. 
    1. Click Generate Token.

The new token string is displayed. Copy the token immediately to a secure location from which you can retrieve it later, because you will not see the token again in the Console.

You can now clone the code repository to create a local copy on your computer, add or remove files, commit changes, and work on different branches by using git operations. To clone the repository by using HTTPS, copy the displayed URL to a local terminal window in an environment with *git* setup.

Upon running the command, the clone operation starts. You are prompted for the username. Depending on whether you use direct signin for logging in to OCI, then the username you need to enter is `tenancy/username` - for example `unicorn-lab/archimedes@rockstars.nl`. If you connect to OCI through an identity provider - a federated login - then the username required here consists of `tenancy/identityprovider/username`. For example: `lucascloudlab/oracleidentitycloudservice/lucas@rainbowmail.nl`.  

When prompted for the password, paste the authentication token that you created earlier and saved for this purpose.

The repository will now be cloned from OCI DevOps to your local machine and your access through git is configured locally. To stop git from prompting you for credentials with every operation against the remote repository, you can run

```
git config --global credential.helper store
```

Then perform a `git pull`, login one more time and from now on, git has the login details and will no prompt you again. 

As an aside: a OCI Code Repository can also be set up as a mirror for another git repository on GitHub or GitLab. This means that changes to this existing git repo are replicated to the Code Repository on OCI and can trigger pipeline in OCI DevOps. The other benefit of doing that is speeding up the build process: when the build needs to fetch the sources from the repo, it will be able to do so much faster from a nearby OCI Code Repository than from a farther removed GitHub or GitLab repository. 

### Create Artifact Registry

An artifact registry is used to store the deliverables from build pipelines and any other artifact that we need to perform successful deployments. More in general, an Artifact Registry is a repository service for storing, sharing, and managing software development packages. Artifacts are grouped into repositories, which are collections of related artifacts. Artifacts can be uploaded and downloaded, versioned and hashed for identification and mutation check.

To create a new Artifact Registry, type *registr* in the Console search bar. Click on the link *Artifact Registry*. 

Click *Create repository*. In the Create repository dialog box, specify details for the new repository, or at least specify its name. For example: *go-on-oci-artifacts-repo*. 

Click on *Create* to create the new artifact repository.


## Deployment

A little bit later on, we will talk about the Build Pipeline that takes sources from the code repository and uses them to produce correct and deployable artifacts and subsequently triggers a deployment pipeline. We will first focus on the deployment process. We will

In OCI DevOps projects, three elements are needed to perform a successful deployment:
    1. A target environment must have been defined; this can be a Kubernetes cluster (an OKE instance), a Function or a Compute Instance (or group of instances, VMs or bare metal machines). The Deployment Pipeline needs specific IAM policies to be allowed to act upon target environment.
    2. One or more artifacts - files that are part of the application that is to be deployed, including scripts needed to run for preparing the deployment or runtime context. Artifacts are used from a repository, either an OCI Container Image Registry or an OCI Artifact Registry repository.
    3. The deplopyment pipeline that defines the steps to perform and the 

For deployment to a compute instance, we also need a deployment configuration file - a yaml file that defines the commands to copy the artifacts to their specific locations on the compute instance's file system and the statements to execute for configuring the environment and running the application.


### Environments & Policies

In the current case, the deployment will take place on the same Compute Instance we used before. We configure the deployment pipeline later on for environments defined in the DevOps Project. An *enviroment* in the DevOps project represents a real environment - OCI Function, OCI Kubernetes Cluster or (group of) OCI Compute instances such as in our case. Deploy stages in an pipeline of type *Deploy - Instance Group* are associated with an *environment* of type *Instance Group*.   

Navigate to the *Environments* tab in the DevOps Project. Click on the button *Create Environment*. Click on the tile *Instance Group*. Provide a name - for example *go-on-oci-vm* - and optionally a description. Click on *Next*.

On the second page of this *Create environment* wizard, click on *Add instance*. In the *Instance selection pane* that appears, locate the compute instancem, select it and click on *Add instance*. Finally, click on the button *Create Environment* to complete the wizard.

#### IAM Dynamic Groups and Permission Policies

The Deployment Pipeline needs permissions - to act upon the compute instance into which it has to deploy. These permissions are defined through policies, that grant the permissions to a dynamic group. The Deployment Pipeline is made member of that dynamic group - the recipient of the policies' permissions. 

To create the dynamic group, type *dyn* in the search bar. Click on the link *Dynamic Groups* in the search results pane.  

On the overview page for dynamic groups, Click on the button *Create Dynamic Group*.

Enter the name for the Dynamic Group for the Deployment Pipeline(s) - for example *deploy-pipelines-for-go-on-oci* - and optionally type a description. Define the following rule that selects all deployment pipelines that are part of the compartment (in this case we have not even created a single deployment pipeline, but we soon will):

``` 
All {resource.type = 'devopsdeploypipeline', resource.compartment.id = '<compartment_id>'}
``` 

Of course, replace `<compartment_id>` with the identifier of the compartment you are working in. Then press *Create*.

It is convenient to define the dynamic group in this broad fashion - simply including all resources in the compartment of type deployment pipeline. In a realistic environment, it is recommended to define dynamic groups and policies as fine grained as possible - as to not grant more permissions than is needed and than you may realize.

Next, to create a policy in the console: type *poli* in the search bar and click on *Policies | Identity* in the *Services* area in the search results popup. This takes you to the *Policies* overview page for the current compartment.

The first policy defines the permission for the deployment pipelines to access resources in the compartment. Create a new policy, type a name, a description and the following statement:

```
Allow dynamic-group deploy-pipelines-for-go-on-oci to manage all-resources in compartment <compartment_name>
```

The definition as shown here is again quite broad. You further restrict the access to resources by specifying the type of resource or other restrictive conditions.

A second policy defines the permission for the deployment pipelines to retrieve artifacts from artifact registry repositories in the current compartment. Again, you need to provide a name and a description. Then define the policy statement as follows:

```
Allow dynamic-group deploy-pipelines-for-go-on-oci to read all-artifacts in compartment <compartment_name>
```


We need another policy to make it possible to access the artifacts from the artifact registry repository. This policy defines the permission for the dynamic group of compute instances - as defined in the previous installment of this article as *go-on-oci-instances* - to retrieve generic artifacts from artifact registry repositories in the current compartment. This may come as a bit of a surprise: should not only the deployment pipeline have the permission to read the artifacts? As it happens: deployment takes place on the compute instance and artifact retrieval is done from that instance. Therefore the policy has to allow the instance to read the generic artifact.

Again, you need to provide a name and a description. Then define the policy statement as follows:

```
Allow dynamic-group go-on-oci-instances to read all-artifacts in compartment <compartment_name>
```

The deployment pipeline is executed on the compute instances through the cloud agent running on the instance. This next policy enables use of the instance agent execution facility on the compute instances in the dynamic group. Type a name - *go-on-oci-instances-can-run-command* - and a mandatory description. Then define the policy (replacing the placeholder with the actual name of the compartment):

```
Allow dynamic-group go-on-oci-instances to use instance-agent-command-execution-family in compartment  <compartment_name>
```

This diagram visualizes the dynamic groups and policies that are now in place.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-deployment-pipeline-policies.png 900 631 "Visualization of the dynamic groups and policies for making deployment to the VM possible" %}   

#### Oracle Cloud Agent and Run Command Plugin

The Compute Instance *Run Command plugin* must be enabled on the VM, and the plugin must be running for the Deployment Pipeline to be able to have commands executed on the instance. You can check and enable this on the Oracle Cloud Agent tab in the Compute Instance details page in the console. For the *Compute Instance Run Command plugin*, make sure the *Enabled Plugin* switch is in the *Enabled* setting. It takes up to 10 minutes for the change to take effect. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-runcommand-plugin.png 1200 564 "Make sure that the Run Command plugin is enabled and running for the Compute Instance" %}



### Artifacts
   
Before too long, we will be using a DevOps Build Pipeline to generate the deployable artifacts that the Deployment Pipeline can then take and install in the target runtime environment. However, for now we wil settle for a hand crafted artifact - created from the source code discussed in the previous installment of this series. 

Using any SSH client - and perhaps most conveniently the *SSH FS* extension in VS Code - open an SSH connection to the OCI Compute Instance that was set up in the previous article. You may have called it *go-app-vm*.

You created a directory *myserver* as part of the steps in this article. Navigate into this directory, that should contain the file `my-server.go`. 

Now build the Go application into an executable: 

```
go build -o my-server
```

This produces a local executable file called my-server, of close to 7 MB. That my seem large. But consider: this file is the entire application. It can run by itself, without any special requirements on a preinstalled runtime environment or virtual machnie. 

Run the file with the following command

```
./my-server
```

The web server will be up and running. With this next command, you can verify that the executable is running as intended.

```
curl localhost:8080/greet
```

Let us now create a an artifact we can use for automated deployment later on. In the current directory - that contains the executable `my-server` and the subdirectory `website`.

These commands create the zip file `my-server.zip`, that will be the artifact used in the deployment pipeline we are about to create:

```
zip -r my-server.zip website
zip -rv my-server.zip my-server
```

To show contents of new zip file, execute:

```
zip -sf  my-server.zip
```

In order to deploy the application now contained in zip file in the deployment pipeline, we need to make sure this artifact is loaded into the artifact registry. 

Move the zipfile into the `website` directory under `myserver`. 

Make sure the application `my-server` is running, so we can use our own application to download the zip-file from the compute instance. Download the zip-file to your local environment through a curl command on the command line or through the browser:

```
http://<public ip of the compute instance>:8080/site/my-server.zip
```

Stop the *my-server* application process.

In the OCI console, navigate to the artifact registry repository that was created earlier. Click on *Upload Artifact*. Type path - `my-server.zip` - and version - `1.0`. Select the my-server.zip file as the file to upload. Click on *Upload*. This will create the artifact in the registry. 

In order to also make this artifact available for deloyment in the current DevOps Project, it needs to be associated with the DevOps Project. Navigate from the DevOps Project's homepage in the console to the *Artifacts* tab. This is where artifacts - container images from the OCI Container Image Registry or generic artifacts from an Artifact Registry Repository - are identified as relevant for the DevOps Project.

Click on the button *Add Artifact*. Specify a name - for example *my-server* - and select *Generic Artifact* as the type. Next, click on the *Select* button to select the Artifact Registry repository from which you want to select an artifact. Obviously, select the repository that was created earlier. Click on the second *Select* button to locate the specific artifact in this repository. Select the `my-server.zip` artifact that you uploaded earlier. Set the toggle *Replace parameters used in this artifact* to *No*: no placeholders need to be substituted with deployment time values in this zip file. Then click on *Add* to complete the association of the artifact with the project.


### Deployment Configuration File

The deployment itself consists of a number of steps, such as retrieving the artifacts from the registry, unzipping the archive's contents to the right destination, setting the required file access privileges, creating an autostart service to make the application run whenever the VM is rebooted. These steps are defined in two ways: 
* through the *deployment configuration file* (in yaml format) describes the high level steps, such as artifact transfer to the target environment and command execution on that environment as well optionally human approval, explicit pauses and execution of an OCI function for fine tuning or validation; this configuration file can be defined as a special type of artifact and associated with the deployment pipeline or it can be defined as an inline artifact, as we will do at first
*  in *shell scripts* that are executed on the target environments to perform the fine grained installation and configuration steps; these scripts are defined as (part of) artifacts transfered to the target environment 

In this first deployment pipeline we will only use a very simple deployment configuration file, defined as inline artifact. 

Click once more on the button *Add Artifact*. In the *Add artifact* dialog, type a name: *myserver-to-vm-deployment-configuration*. Select *Instance group deployment configuration* as the type. Select *Inline* for artifact source.

```
version: 1.0
component: deployment
env:
  variables:
    version: ${appVersion}
files:
  # This section is to define how the files in the artifact shall 
  # be put on the compute instance
  # the artifacts are copied to directory myserver in /tmp; if that directory does not exist, it will be created
  # artifacts that are archives (such as zip) are extracted as well into the target directory; a file in the root of the archive ends up in /tmp/myserver
  - source: /
    destination: /tmp/myserver
steps:
  # This section is to define the scripts that each step shall run on the instance after file copy.
  - stepType: Command
    name: Kill my-server (if it is currently running)
    command: killall my-server || echo "Process was not running."
    timeoutInSeconds: 30
  - stepType: Command
    name: Remove directory yourserver - for a fresh and clean install
    command: rm -Rf /tmp/yourserver
    timeoutInSeconds: 60
  - stepType: Command
    name: Copy directory myserver with all unzipped artifacts to newly created directory yourserver
    command: cp -R /tmp/myserver /tmp/yourserver
    timeoutInSeconds: 30
  - stepType: Command
    name: Copy Log File for this deployment as static file under website
    command: cp /tmp/myserver/stdout /tmp/yourserver/website/deployment-log.txt
    timeoutInSeconds: 30
  - stepType: Command
    name: Start My Server to serve HTTP Requests (as backgroundprocess)
    command: cd /tmp/yourserver && ./my-server &
    timeoutInSeconds: 60
  - stepType: Command
    name: Remove deployment artifacts
    command: rm -Rf /tmp/myserver
    timeoutInSeconds: 60
```    

Now it is time to create the deployment pipeline itself - and link the two artifacts to the environment.  

### Deployment Pipeline 

On the DevOps Project's overview page, click on the button *Create pipeline*. The *Create pipeline* form is presented. Type a name - *deploy-myserver-on-go-app-vm* - and optionally a description. Then click on the button *Create pipeline*. The deployment pipeline is now created - though it is quite empty: not an environment into which it should deploy, no artifacts that are to be deployed and no configuration file to define the steps to execute. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-create-pipeline-stage.png 1200 552 "The deployment pipeline editor - click on the Add Stage card to add a pipeline stage" %}

In the pipeline editor that appears, click on the *Add Stage* tile (or on the plus icon). The next page shows a list of stage types. Click on the tile labeled *Deploy incrementally through Compute instance groups*; although a mouthful it simply means (for our purpose): deploy stuff onto a single VM.  

{% imgx aligncenter assets/way-to-go-on-oci-article-2-select-stagetype.png 1200 564 "Select the Stage Type for deployment to one or more compute instances" %}

Press button *Next*. 

Type the stage name, for example *deploy-myserver-to-vm*. Select the environment that was defined earlier for the target VM: *go-on-oci-vm*. 

Under *Deployment configuration*, click on *Add Artifact*. A list of all artifacts in the DevOps project of type *Instance group deployment configuration* is presented. Select the only entry - that was created earlier. Press button *Save changes* to associate this deployment configuration with the deployment stage.

Note that the button *Add Artifact* is no longer enabled: only a single deployment configuration can be defined in a stage. 

To specify the artifact(s) that are to be taken from an artifact store and put into the target environment, click on the second button labeled *Select Artifact*. Select the *my-server* artifact that was added to the DevOps project, representing the similarly named artifact *my-server.zip:1.0* in the Artifact Registry repository *go-on-oci-artifacts-repo*. Click on *Save Changes*.

Toggle radio group *Rollout policy* - not useful in our case with only a single compute instance as deployment target - to *Rollout by count* and type *1* in the field *Instance rollout by count*. Then click on button *Add*.

The pipeline stage is created in the pipeline. And the pipeline can now be executed - to retrieve the zip file with the my-server application from the artifact repository, download zipfile and extract its contents in the target VM and run the application as background process. When the deployment pipeline is done running, the application should be serving HTTP requests.

Click on button *Run pipeline*.  A page with an overview of the manual run of the deployment pipeline. It allows you to set a name - to indicate the specific significance of this particular deployment. Parameter values can now be provided for use in this run of the deployment pipeline. Our pipeline does not currently have any such parameters defined so we can not set any values. In the future, we might well use parameters, for example to define the prefix for log output or the port on which *my-server* should listen for HTTP requests - set as an environment variable or startup parameter in the deployment configuration.  Now press button *Start manual run*. The deployment is started. An email is sent to the address that you subscribed on the notification topic, to alert you of the start of the run. A second mail will be sent to let you know about the result of the run.  

The next figure shows the configuration of the Deployment Pipeline in conjunction with the other OCI resources it depends on. The configuration
{% imgx aligncenter assets/way-to-go-on-oci-article-2-deployment-pipeline-diagram.png 714 600 "deployment pipeline-diagram" %}  

When the deployment is finished successfully, send an HTTP request - with curl or from a browser - to port 8080 at the public IP of the VM: 

```
http://<public ip of the compute instance>:8080/greet?name=Success
```

When you receive a response to this request - as you should - it proves that the deployment has succeeded. Starting from zip file containing the binary executable of our Go application, without our hands touching the VM, we managed to apply some fine automation and bring the application alive. The deployment pipeline, targeted at the proper environment, leveraging the right artifact and steered by the proper deployment configuration managed to pull it off. Note however that the application is not autohealing and will not automatically start when the VM is rebooted. We can configure the application as a Linux service that should automatically be started - and we will do so when we put together the build pipeline for a somewhat more sophisticated application. At that point we will also make use of dynamically defined port for the application to listen on instead of the hard coded port 8080 that is currently used.

Using the next URL path

```
http://<public ip of the compute instance>:8080/site/deployment-log.txt
```

you are able to inspect the first few log entries from the deployment pipeline itself. This file is copied to the static website directory of my-server in the first step in the deployment configuration. The files indicates the directory on the compute instance where the detailed logs are written: *Deployment Log for deploymentId ocid1.... is created at /var/lib/ocarun/commands/wd/..../stdout*. Note: root access is required to read this file.

The deployment pipeline can do several additional things. Take parameter values we specify for each deployment and replace placeholders in the deployment pipeline and the deployment configuration with these values. Ask a user's approval to proceed. Run additional stages - sequentially or in parallel.  Do a blue/green or canary release to a group of compute instances. 

You would be forgiven for thinking that this has been quite a lot of work for what is really a simple installation. If you would do this installation only once, then creating an SSH connection as we did in part one of this series and just performing the installation steps manually would be much more efficient than creating this pipeline to perform the installation. When however you want to install the application on multiple compute instances that you not have SSH access to or you want to install the application multiple times, whenever a new version of the application becomes available and you want colleagues without Linux skills or access privileges to be able to perform the installation, having this deployment pipeline slowly begins to make sense. Once you know the steps in the pipeline are correct, the deployment can be run in a fully automatic manner without the risk of human errors, abuse of access privileges, lack of audit trail, lenghty wait times because of unavailability of staff. Suddenly the concept of deployment pipelines is more and more enticing. Assuming much more involved deployment processes with additional installation steps, larger numbers of artifacts, more complex, perhaps parameter driven environment configuration - the value of automated deployment pipelines will be obvious.

To get a glimpse of this effect, you could quickly create a new compute instance in the compartment. Then define a new environment in the DevOps project for this compute instance and associate the Deployment Pipeline with this environment. Then run the pipeline. With just a few simple steps, you have made the application run on this second compute instance. Without resorting to SSH connections and command line operations. In fact, through only a simple console based process that you can teach to fairly non-technical staff.


## Build Pipelines for Automated Source to Artifact Build and Delivery

In the previous section the artifact to be deployed was created manually and uploaded into the artifacts repository by hand. In the name of automation we want to use build pipelines for creating such artifacts. 

Starting from the source code of the Go application, the build pipeline will enlist a build server, copy the relevant sources to that server, perform the linting, code analysis, compilation, testing and packaging steps and save the resulting deployable artifacts to the artifacts repository. The build pipeline can subsequently trigger the deployment pipeline to take those artifacts and deploy them to a specified environment. The build pipeline itself can be triggered manually or by an event such as a commit or a merge-to-master of a pull request in the code repository. 

In this section we are going to create an OCI Devops Build Pipeline. It is on the one hand associated with the Code Repository you have created in the DevOps Project and it delivers artifacts to the Artifact Registry repository on the other. The pipeline can contains for these activities:
* Perform a managed build (execute build according to specification on a build server) a
* Deliver the output of a managed build stage to an Artifact Registry repository
* Wait (for a specified period of time)
* Trigger a Deployment Pipeline while passing parameters to it 

The Build Pipeline we will create next will take sources for a Go application from Code Repository, perform lint, test and compile on the application and package the application with its resources in a zip file. This file is the artifact that is published to the Artifact Registry. Subsequently, the Deployment Pipeline is triggered - to deliver this application to a compute instance and make it run. 

### Prepare Code repository

Our pipeline will have precious little to build at present, because our Code Repository is quite empty. The source you can work with are available from [the GitHub repository that has been prepared for this series of articles](https://github.com/lucasjellema/go-on-oci-article-sources). You will want to get these sources into your OCI Code Repository.

The easiest way of making that happen is simply by downloading the GitHub repo's content as a zip file and extracting its contents into your local clone of the *go-on-oci-repo* Code Repository. Alternatively, create a clone of the GitHub repository and copy all content (except the `.git` directory) to the directory that has the local clone of *go-on-oci-repo*.

Then, when all sources are available as unstaged files in the local *go-on-oci-repo*, stage all files and commit. Then do a `git push`. To bring all the local files into the Code Repository on OCI.

You may feel like inspecting the sources through the console to make sure that they are now truly yours, safely held in your cloud based repository. And ready to be used in a build pipeline. 

### Assembling the Build Pipeline

The Build Pipeline is a workflow definition, just like the deployment pipeline. It describes the steps to take whenever an automated build is required, the order for the steps and through parameters the context for the steps. It also describes the input - the sources from the code repository - and (where to store) the output. The real action happens in *managed build* stages, on a build server. 

We will now first create the Build Pipeline and then add three stages to it: managed build, publish artifact and trigger deployment pipeline. Before we can run the pipeline we then also need to take care of permissions through a dynamic group and some policies. 

#### Create the Build Pipeline

On the overview page for DevOps Project *go-on-oci*, click on button *Create build pipeline*. A page is presented for specifying the name - say *build-myserver* - and a description. Press *Create* to have the build pipeline added to the DevOps Project.

Click on the link *build-myserver* in the list to navigate to the details page.

#### First Stage - Managed Build 

The first stage in any build pipeline is a *Managed Build* stage. This stage provides instructions for the pipeline to get hold of a build server, copy specified sources from code repositories to the server and run through a number of actions on that server. At the time of writing, we can use a single image for the build server. It is an Oracle Linux image (8 GB memory, 1 OCPU) that has a number of pre installed tools and language run times. For example: Git, Docker, Helm, OCI CLI, Node.js, Java and Go are on the build runner image. For Go, the current version is 1.16.5. If the build process requires additional or different versions of technologies, you will have to make their installation part of the build process.

In the future, we will be able to choose between multiple build runner images (different composition and size) and bring our own images to use. Note: You are charged for using the compute shape (OCPU and memory) during the build run.   

Reference [OCI Docs - Build Runner Details](https://docs.oracle.com/en-us/iaas/Content/devops/using/runtime_details.htm)

Click on either the plus icon or the *Add Stage* card. The two step *Add a stage* wizard appears. On step one in the wizard, make sure that the *Managed Build* card is selected for the type of stage. Press *Next*.

The second page is shown. Define a name for the build stage: *build-source-to-executable*. Optionally type a description.  

At present we cannot select a different build image, so we settle for the one available - which is fine for our purpose. The default name and location for the build specification is correct - file build_spec.yaml in the root of the repository. 

Click on the *Select* button under *Primary code repository*. We can now specify from which code repository the build will get its sources. Select *OCI Code Repository* as the *Source Connection Type*. Then select the *go-on-oci-repo* repository. We will work with source on the main branch, so do not change that default. Type *myserver-sources* as the value for *Build source name*. This managed build stage can use sources from multiple repositories. In the build specification, we can refer to each of these sources using the label defined as *Build source name*. Click on *Save*. 

Press button *Add*. This completes the definition of the managed build stage. This is all it takes to take sources and process into artifacts. 

Well, hang on, I hear you think. We may have indicated the sources to use, but we certainly did not say what to do with those sources. Whether any linting, testing, compilation and packaging into a zip file should be performed. And in fact - we did stipulate exactly what should happen on the build server. It is right there - in the `build-spec.yaml` file. We have not talked about that file yet and we certainly did not create it. But it pushed into the code repository and sitting there in the root directory of the project. It is this file that contains the instructions for the actual detailed steps executed on the build server.

```
version: 0.1
component: build
timeoutInSeconds: 6000
runAs: root
shell: bash
env:
  # these are local variables to the build config
  variables:
     SOURCE_DIRECTORY: "myserver-sources"

  # the value of a vaultVariable is the secret-id (in OCI ID format) stored in the OCI Vault service
  # you can then access the value of that secret in your build_spec.yaml commands
  vaultVariables:

  # exportedVariables are made available to use in sucessor stages in this Build Pipeline
  exportedVariables:
    - BUILDRUN_HASH


steps:
  - type: Command
    name: "Export variables"
    timeoutInSeconds: 40
    command: |
      export BUILDRUN_HASH=`echo ${OCI_BUILD_RUN_ID} | rev | cut -c 1-7`
      echo "BUILDRUN_HASH: " $BUILDRUN_HASH
      echo "SOURCE-DIRECTORY: " $SOURCE_DIRECTORY
      echo "${OCI_PRIMARY_SOURCE_DIR}" ${OCI_PRIMARY_SOURCE_DIR}
      echo "fully qual sources" ${OCI_WORKSPACE_DIR}/${SOURCE_DIRECTORY}
      echo "myserver-version from build pipeline parameter" ${MYSERVER_VERSION}
      go version

  - type: Command
    timeoutInSeconds: 600
    name: "Install golangci-lint"
    command: |
      curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.37.1

  - type: Command
    timeoutInSeconds: 600
    name: "Verify golangci-lint version"
    command: |
      /root/go/bin/golangci-lint version

  - type: Command
    timeoutInSeconds: 600
    name: "Run go mod tidy for Go Application"
    command: |
      go mod tidy

  - type: Command
    timeoutInSeconds: 600
    name: "Run go vet for Go Application"
    command: |
      go vet .

  - type: Command
    timeoutInSeconds: 600
    name: "Run gofmt for Go Application"
    command: |
      gofmt -w .

  - type: Command
    timeoutInSeconds: 600
    name: "Run Lint for Go Application"
    command: |
      /root/go/bin/golangci-lint run

  - type: Command
    timeoutInSeconds: 600
    name: "Run Unit Tests for Go Application (with verbose output)"
    command: |
      go test -v
  
  - type: Command
    timeoutInSeconds: 600
    name: "Build Go Application into Executable"
    command: |
      go build -o my-server

  - type: Command
    timeoutInSeconds: 600
    name: "Zip my-server Application Executable along with website"
    command: |
      zip -r my-server.zip website
      zip -rv my-server.zip my-server
  
outputArtifacts:
  - name: myserver-archive
    type: BINARY
    location: ${OCI_WORKSPACE_DIR}/${SOURCE_DIRECTORY}/my-server.zip
```

The build specification consists of three parts: 
    1. Set up - who to run the script as, which shell to use, which variables to use
    2. Build steps - Shell commands to execute on the build server
    3. Output Artifacts - indicate which files at the end of all build steps are meaningful and to be made available to other steps in the pipeline (for example to publish as artifact)

The build steps can be summarized as: 
    1. Print environment variables and currently installed Go version (on the vanilla build server)
    2. Install golangci-lint
    3. Verify success and version of golangci-lint installation
    4. Run `go mod tidy` to organize the go.mod file with dependencies
    5. Run `go vet` to run a first inspection on the Go Sources
    6. Run `go fmt` to format the sources according to generic formatting rules
    7. Run `golangci-lint` to lint (check) the sources against various linting rules
    8. Run unit tests
    9. Build sources into binary executable - called `my-server`
    10. Create zip file `my-server.zip` with the *website* directory and the executable `my-server`


If you are eager to see the managed build stage in action, you can skip the next two sections for now, define the dynamic group and the policies described under *IAM Policies* and then press the button *Start manual run*. The pipeline grinds into action. A build server is acquired, the build specification is located and the steps in the specification are executed. The logs are shown and provide insight into the proceedings. After a little while, the build is complete. An output is created on the build server - but not yet published to the artifact registry. It will now be lost when the stateless build server gets reset for a next run by us or someone else entirely.

We will now define the stage that publishes the artifact, to allow us to really enjoy the fruits of our managed build.

Reference:
[OCI Documentation - Build Specification Reference](https://docs.oracle.com/en-us/iaas/Content/devops/using/build_specs.htm)


#### Second Stage - Publish Artifact

In the overview page for the build pipeline, click on the plus icon at the bottom of the current managed build stage. In the context menu that pops up, click on *Add stage*. The stage wizard appears.

Click on *Deliver artifacts*. Then click on *Next*. 

Enter the name for this stage: *publish-myserver-as-artifact*. We need to select the artifact in the DevOps project that we want to publish. This artifact can be a container image in the image registry or a generic artifact in an artifact registry repository. The latter is the case. Click on button *Select artifact(s)*. Select the *my-server* artifact that we used previously in the deployment pipeline. We will have our build pipeline produce fresh updates of this artifact.

In the area *Associate artifacts with build result* we have to indicate for each of the artifacts selected which of the outcomes of a managed build stage is the source for publishing the artifact. The *build-spec.yaml* file defines an output labeled *myserver-archive*. This output refers to the my-server.zip file that is produced by the build process. Enter this label *myserver-archive* in the field *Build config/result artifact name*. The press the *Add* button to create the *Deliver Artifacts* stage. 

If you feel like it - and already defined dynamic group and policies - you could press the *Start manual run* button. This time the build will not only create a zip file on the build server (that is then lost forever) but it will store that zip file in the artifact registry repository. The *Build run progress* will inform you about it. And when the run is complete and you check the *go-on-oci-artifacts-repo* repository in the Artifact Registry, you will find the file *my-server.zip* with a creation timestamp that is very close to now. This is the work of the build pipeline.

The deployment pipeline that we created earlier uses this very artifact as a starting point. With this freshly built artifact available, you can now manually start a run of the deployment pipeline to have the new Go application installed and started. Or you can wait a little bit longer and trigger the deployment pipeline from the a stage at the end of the build pipeline. When that is in place, triggering the build pipeline will result in an end to end build and deploy flow.    

#### Third Stage - Trigger Deployment Pipeline

In the overview page for the build pipeline, click on the plus icon at the bottom of the *Deliver artifacts* stage. In the context menu that pops up, click on *Add stage*. The stage wizard appears.

Click on *Trigger deployment*. Then click on *Next*. 

Type a name for the stage: *trigger-deployment-of-myserver* and optionally a description. Click on the button *Select deployment pipeline*. Select the pipeline *deploy-myserver-on-go-app-vm* (probably the only deployment pipeline there is to select). Details of the pipeline are shown - such as parameters (none defined at this point) and artifacts used by the deployment.

Click on button *Add* to complete the stage definition and add it to the build pipeline.

This completes the build pipeline: it grabs sources, processes them into a deployable artifact, publishes the artifact to the registry and triggers the deployment pipeline to take it from there. If you have not yet set up a dynamic group and IAM policies, you will do so in the next section. And then we can run the end to end process of build, delivery and deployment.

The next figure visualizes the build pipeline and its relation with the deployment pipeline.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-build-and-deployment-pipelines.png 838 542 "Overview of how the build and deployment pipelines (and other DevOps resources) hang together" %}  

### IAM Policies

Build pipelines require permissions to do the things they are supposed to do. They need to read from a Code Repository and publish artifacts to an Artifact Registry. And they need to trigger a deployment pipeline. For all these actions, the build pipeline has to be granted permission through a dynamic group - just like the deployment pipeline got its permissions. 

#### Create Dynamic Group for the Build Pipeline(s)

To create the dynamic group, type *dyn* in the search bar. Click on the link *Dynamic Groups* in the search results pane.  

On the overview page for dynamic groups, Click on the button *Create Dynamic Group*.

Enter the name for the Dynamic Group for the Deployment Pipeline(s) - for example *build-pipelines-for-go-on-oci* - and optionally type a description. Define the following rule that selects all deployment pipelines that are part of the compartment (in this case we have not even created a single deployment pipeline, but we soon will):

``` 
ALL {resource.type = 'devopsbuildpipeline', resource.compartment.id = '<compartment_id>'}
``` 

Of course, replace `<compartment_id>` with the identifier of the compartment you are working in. Then press *Create*.

It is convenient to define the dynamic group in this broad fashion - simply including all resources in the compartment of type build pipeline. In a realistic environment, it is recommended to define dynamic groups and policies as fine grained as possible - as to not grant more permissions than is needed and than you may realize.

#### Define Policies that bestowe Rights on the Dynamic Group

To create a policy in the console: type *poli* in the search bar and click on *Policies | Identity* in the *Services* area in the search results popup. This takes you to the *Policies* overview page for the current compartment.

The first policy defines the permission for the build pipelines to deliver artifacts to the Artifact Registry. Define a name, a description and the following statement:

```
Allow dynamic-group build-pipelines-for-go-on-oci to manage all-artifacts in compartment go-on-oci
```

To send notifications for the build process, provide access to ONS (notification service) to the build pipelines:

```
Allow dynamic-group build-pipelines-for-go-on-oci to use ons-topics in compartment go-on-oci
```

And to allow the build pipelines to read deployment artifacts in the Deliver Artifacts stage, read DevOps code repository in the Managed Build stage, and trigger deployment pipelines:

```
Allow dynamic-group build-pipelines-for-go-on-oci to manage devops-family in compartment go-on-oci
```

With these policies in place, the build pipeline can be taken for a spin. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-dyngroup-and-policies-buildpipeline.png 722 377 "Providing permissions to the build pipeline through a dynamic group and policies" %}  

### Run the Build Pipeline - and making the application run

The Build Pipeline can be triggered by events in the Code Repository. Simple events such as commits or slightly more complex events such as merge to a specific branch (such as merge of a pull request to the main or master branch) can be set up to trigger the pipeline. It can also be triggered manually. Just started from the console. That is what you will do next.

Click on *Start manual run* in the overview page for the build pipeline. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-start-build-run.png 1200 752 "Starting a run of the three stage build pipeline" %} 

The build pipeline is kicked into action. It acquires a build server, retrieves the code and saves it on the build server. Then it performs the steps in the build specification. The outputs from this build process are published from the build server's file system, uploaded to the Artifact Registry, where they will be waiting for the Deployment Pipeline to come along and fetch them. And indeed this is what happens next: the build pipeline's final stage triggers the deployment pipeline. This has the artifact as its source and continues on to write the artifact to the compute instance and perform the installation steps. You will receive emails about the start and completion of both the build pipeline and the triggered deployment pipeline. You may start to think about setting routing rules to a specific mail folder for emails from OCI DevOps.  



When the Build Pipeline is completed successfully, the triggered deployment can still be running or can have failed miserably. The build pipeline does not hear back from the deployment pipeline. Once you see that the deployment pipeline has completed successfully too, we should be able to access the application that was deployed based on the artifact built based on the sources in the code repository. 

Validate if the application is indeed running. 

```
http://<public IP compute instance>:8080/....
```

### Introducing Parameters

We want our sources as well as our deployment artifacts to be environment independent. The same artifacts can be deployed in different environments and work well, calling to different endpoints perhaps, listening to environment specific ports and writing to environment specific file system locations. At deployment time, the artifact can be combined with these environment specific values. 

OCI DevOps Deployment Pipelines support this way of working. You can use placeholders in the Deployment Configuration file and in [the contents of] artifacts; these placeholders are replaced at deployment time with the value of the corresponding parameters or secrets in OCI Vault. Moreover, the version indication of artifacts can be defined using a placeholder that is replaced at deployment time by the actual value of a parameter. 

Build pipelines can also work with parameters. Parameters can be used in the managed build - replacing placeholders in the build specification. A build pipeline parameter can also be used to determine the version label of the artifact that is published by the pipeline and this parameter can subsequently be leveraged in the deployment pipeline to fetch that exact artifact version to be deployed.

We will now make use of a parameter called `MYSERVER_VERSION` in three places:
* in the custom path of a DevOps Project Artifact's definition
* a parameter in the Deployment Pipeline 
* a parameter in the Build Pipeline

And to show off a little, the parameter can also be used in the `build_spec.yaml` (because any build pipeline parameter is available as environment variable in the build server session) and the [inline] configuration definition (where too environment variables in the deployment environment can be defined based on pipeline parameter values). 

#### Placeholder in DevOps Artifact Version

In the DevOps project, go to the *Artifacts* tab. Click on three dots for the artifact called *my-server* and select *Edit* from the menu. The *Edit artifact* dialog appears. 

Change *Artifact Location* to *Set Custom Location*. The field *Artifact Path* should have the value *my-server.zip* and the Version should be set to *${MYSERVER_VERSION}*. This value means that whenever the DevOps project refers to the artifact - from a Build Pipeline or a Deployment Pipeline - the specific version to use of the artifact is to be derived using the value of parameter *MYSERVER_VERSION*. As a consequence, any reference to the artifact at a time when there is no value set for a parameter with this name is meaningless.

Select *Yes, substitute placeholders* under *Replace parameters used in this artifact* to make sure that the value of the parameter is actually applied to compose the version (and *${MYSERVER_VERSION}* is not regarded as a simple string). 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-edit-myserver-artifact-definition.png 1200 729 "Edit the DevOps Artifact myserver to dynamically select a version based on a parameter derived placeholder" %}  

Press button *Save* to apply the changes in the artifact definition. 

#### Deployment Pipeline Parameter

Deployment Pipelines can have parameters associated with them. These parameters have a name, a default value and a description. When a run is started for a deployment pipeline, the default values of the parameters can be overridden, setting appropriate values for that specific deployment. The values for the parameters are used to resolve `${placeholder}` expressions that can be in the deployment specification, in the artifact's version definition and in the content body of any of the deployed artifacts. 

To set parameter values, go to the *Parameters* tab on the Deployment Pipeline page. Add two parameters:
    1. MYSERVER_VERSION - to define the version of the *my-server* artifact to deploy; set the default value to 4.8
    2. HTTP_SERVER_PORT - to define the port on which the my-server application will listen to incoming HTTP requests; set the default value to 8090 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-deployment-pipeline-parameters.png 1200 389 "Define parameters for the deployment pipeline" %}  

The value for *MYSERVER_VERSION* is immediately meaningful: when you next will run the deployment pipeline, the artifact to retrieve for the deployment is found using the artifact definition in the DevOps project, with path set to `my-server.zip` and version defined as `${MYSERVER_VERSION}`. The value for version is deduced using the value of the parameter.

If you run the deployment pipeline right now, it will fail because there is no artifact `my-server.zip` with version `4.8`. We need to update the build pipeline to produce that artifact (or go to the artifact repository and manually set the version label to this value).

The second parameer - HTTP_SERVER_PORT - has no effect yet. It is defined, it is available when the deployment pipeline is started but it is not yet used. We can change that.

Go to the Artifacts tab in the DevOps project. Click on the link *myserver-to-vm-deployment-configuration* for the inline artifact with the deployment configuration. Then click on *Edit* to update the configuration.

Add two environment variables, as shown next. This will cause two environment variables to be available during deployment, called VERSION_OF_MYSERVER and HTTP_SERVER_PORT with their values derived from the deployment pipeline parameters.. 


```
version: 1.0
component: deployment
env:
  variables:
    VERSION_OF_MYSERVER: ${MYSERVER_VERSION}
    HTTP_SERVER_PORT : ${HTTP_SERVER_PORT}
files:
```

The environment variable *HTTP_SERVER_PORT* is meaningful: it is read in the *my-server* application and interpreted as the HTTP port on which the application is listening to incoming HTTP requests. The default value that was used until now is *8080*. With the environment variable now set from the pipeline parameter that has *8090* as its default value, things will change upon the next deployment: the application will listen on port 8090 - as it states in the deployment log. In the same line, the application also indicates its own version. That information was read from environment variable *VERSION_OF_MYSERVER*.  

To verify that the environment variables are set as desired, you can add this step to the deployment configuration, that will write the two environment variables to the output:

```
  - stepType: Command
    name: Report
    command: echo myserver version to install in this deployment $VERSION_OF_MYSERVER && echo port to make the application listen to $HTTP_SERVER_PORT
    timeoutInSeconds: 60
  - stepType: Command
```

#### Build Pipeline Parameter

Build pipeline parameters can be used during the build process. The parameters are available as environment variables on the build server during the execution of the build process. Additionally, when a deployment pipeline that is triggered from a build pipeline has parameters with the same name as parameters defined in the build pipeline, then the value set to the build pipeline parameter is passed in to the deployment pipeline and used for the corresponding parameter. This is used for example to pass the value of the parameter that identified the artifact version.

Go to the *Parameters* tab for the Build Pipeline. Define a new parameter called *MYSERVER_VERSION*. Its description can be something like *Version of the myserver artifact that is produced*. The default value can be set to *4.8* - or anything else. When you run a build pipeline you can override the default value for every parameter. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-buildpipeline-parameter.png 1200 394 "Define a build pipeline parameter to define the version of the artifact to publish" %}  

#### End to End Parametrized Build and Deployment 

By defining the parameter *MYSERVER_VERSION* for both the build pipeline and the deployment pipeline as well as in the artifact's version label, we have tied the two pipelines together. When we run the Build Pipeline and set the value for *MYSERVER_VERSION* to a value such as *4.8* (or any other version label like string) then the build pipeline will produce the *my-server.zip* artifact with the version set to that value and the deployment pipeline will take that artifact version as its source for the deployment. During build as well as during deployment, environment variables are available based on the parameter(s) defined for the pipeline. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-end-to-end-parameters-in-build-and-deploypipeline.png 1041 813 "Visualizing the parameters (MYSERVER_VERSION and HTTP_SERVER_PORT) and how and where they are used" %}  

Run the build pipeline and when prompted provide a value for the parameter *MYSERVER_VERSION*. It can be 4.8 but 5.7 or 9.3 is fine too. Or anything else.

Inspect the logging for both the build pipeline and the deployment pipeline for the appearances of the environment variables. One of the final log lines in the deployment log reads: *Starting my-server (version 4.8) listening for requests at port 8090* . The version indicated depends on the value you defined for the parameter *MYSERVER_VERSION*. The port similarly depends on the parameter *HTTP_SERVER_PORT*. 

Note that any port different from 8080 has a consequence: *myserver* friendly greet service is currently not accessible from outside the compute instance. For port 8080, we have defined an Ingress rule in the subnet's network security list (in part one of this series) and we have added this port to the firewall on the VM. With the application listening on a different port, we have to make sure that this port is opened up in a similar way as was port 8080. Feel free to do so - or to revert back to port 8080 by changing the value of deployment pipeline parameter *HTTP_SERVER_PORT* to 8080 and running the pipeline again.

Note: opening up the port in the compute instance's firewall rules can be accomplished as part of the deployment by adding this step to the deployment configuration:

```
  - stepType: Command
    name: Report
    runAs: root
    command: firewall-cmd  --permanent --zone=public --add-port=${HTTP_SERVER_PORT}/tcp && firewall-cmd  --reload
    timeoutInSeconds: 60
```

However, this command requires *sudo* permissions and this means that you must grant *sudo* permissions to the Compute Instance Run Command plugin to be able to run the command. The plugin runs as the *ocarun* user and this user must be explicityly allowed to run all commands as *sudo*. See for details on how to realize this:
[OCI Documentation - Running Commands with Administrator Privileges](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/runningcommands.htm#administrator-privileges). 
## API Gateway - exposing My Server to the World

Even though the compute instance to which the myserver application has been deployed has a public IP address, the service is currently not accessible from the outside. The network security that was set up in the first installment in this series were defined to allow traffic to port 8080, but not to 8090. In fact, we do not want any traffic directly to our production servers. And public IP addresses for compute instances probably are generally not a good idea. 

Services that should be accessible to consumers external to our cloud tenancy should be published as APIs on an API Gateway.  Not only can we protect the VM from network traffic from the public internet, we also encapsulate our service's location and implementation, allowing us to change such implementation details without impacting the consumers of the API. Additionally, the API Gateway allows us to aggregate services into a single API, use better defined paths, headers and parameters and enforce authorization. The API Gateway can perform request and response manipulation, enforce throttling rules to protect the backend service and provide detailed insight in the usage of the API.

Without going into all features the API Gateway offers, we will create an API Gateway with a Deployment that has a single route for exposing the service offered by application *myserver*, built from the Go application sources and deployed to the compute instance.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-apigw-to-apponvm2.png 1015 177 "The route on API Gateway is triggered by an incoming HTTP request and uses the backend service on the VM to get a response for the requestor" %}  

### Create API Gateway

Type *gat* into the search bar in the console. Click on the link *Gateways | API Management*.

Click on the button *Create Gateway*. Enter a name for the new gateway, for example *the-api-gateway*. Accept the type *Public*. Select the same VCN used for the Compute Instance and the same public subnet and do not enable network security groups. Accept the default setting under Certificate. Press *Create Gateway*. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-create-api-gateway.png 1200 564 "Create an OCI API Gateway" %}  

Note: we are doing a very simple deployment using the smallest number of OCI cloud resources we can get away with. In a real world scenario, we would most probably not have the API Gateway on the same subnet as the Compute Instance it is routing to- because one of the things we try to achieve is insulate the backend VM from the public internet using the front end API Gateway.

### Create Deployment

The API Gateway will now be created. Once that has been done, navigate to the *Deployments* tab. A Deployment on an API Gateway is a collection of (incoming) routes that are mapped to backend services to handle requests. Click on the button *Create Deployment*.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-create-deployment.png 1200 627 "Initiate creation of a  Deployment - a collection of routes" %}  

The first page of a three page wizard appears. Here we define the name of the deployment - for example *myserver-api* - and the path prefix used by all requests to the API Gateway that are to be handled in this deployment. For example: */my-api*.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-create-deployment-1.png 1200 652 "Step 1 - Basic Information for the Deployment - and settings that apply to all routes" %}  

 Click on *Next* to move to the second page in the wizard.

 On this page, we define each of the routes this deployment will take care of. Let's start by defining just a single one. Type */welcome* as the path. This means that requests to the API Gateway looking like: *https//<URL for API Gateway>/my-api/welcome* will be handled by this route. 

 Select the *GET* method - the only HTTP method this route will be able to handle. 

 Accept the Type *HTTP* . In the *URL* field type the HTTP endpoint for the service exposed by *myserver* on the compute instance. At this moment, it is the same endpoint you have used in the browser to access the service because right now the compute instance has a public IP and the network configuration allows that direct traffic. With the API Gateway handling the inbound traffic, we can restrict network access to the VM - as long of course as the API Gateway can make requests to it.     

{% imgx aligncenter assets/way-to-go-on-oci-article-2-createdeployment2.png 1200 740 "Define a route in the deployment - to handle of a specific URL path and HTTP methods using a specific backend" %}  

Click on button *Next* to go to an overview of the definition of the deployment. Click on *Save* on this third page to create deployment with its single route.

It takes a little while for the API Gateway to be updated with the deployment. 

{% imgx aligncenter assets/way-to-go-on-oci-article-2-createdeployment4.png 1200 564 "The deployment has been created and activated and the public endpoint is available" %}  

### Update Network Security and Invoke API

On the Deployment Details page is the (public) *Endpoint* for the deployment. CLick on the *Copy* link. Now paste the link in your browser's address bar, add */welcome* to the URL and press enter. 

``` 
https://<URL for API Gateway>/my-api/welcome
```

This probably will not give the expected result - not if you expected success at least. 

The request we sent to the API Gateway is sent over HTTPS to the default HTTPS port of 443. The public subnet that we associated with the API Gateway was configured in the previous installment of the series to allow inbound traffic for port 20-22 (for SSH connections) and for port 80 (plain HTTP traffic). We now need to extend that definition to also allow ingress traffic to port 443.

{% imgx aligncenter assets/way-to-go-on-oci-article-2-http-serverport-network-rules.png 896 329 "Overview of the impact of setting the HTTP_SERVER_PORT parameter: on the route definition, the ingress network rule for the VM, the egress rule for the API Gateway and the myserver application" %}  

Type *net* in the search bar and click on link *Virtual Cloud Networks* in the services list. Click on the *VCN* that was created earlier and subsequently on the *Subnet* that was associated to the API Gateway. Click on the *Security List*. Click on *Add Ingress Rule*. 

Define a new Ingress Rule with *Source CIDR* set to `0.0.0.0/0`, *Destination Port Range* set to `443` and optionally a description of the rule. Press button *Add Ingress Rules* to save the new rule.

Now try again once more to access the *welcome* route on the API from your browser:

``` 
https://<URL for API Gateway>/my-api/welcome
```

This time round, you should get the expected response. 

Adding a query parameter:

``` 
https://<URL for API Gateway>/my-api/welcome?name=No+Stranger
```

Requests to the public endpoint of the API Gateway and with the configured path prefix of *my-api* and the one supported route of *welcome* are forwarded to the API Gateway to the *myserver* application on the compute instance and the request is returned to us. In the next section we will show one small example of request manipulation in the API Gateway. 

#### Connecting API Gateway to a private Compute Instance

Because of our earlier work with the go-app-vm compute instance, it has a public ip and is aasociated with a subnet that allows all kinds of inbound network traffic from any source on the public internet. However, in reality it will be more likely to create a compute instance that has no public IP and is associated only with a private subnet. In that case, these are the high level steps to configure the API Gateway to route requests to the VM as backend for an API route. There are three elements that need to be addressed.


    1.	*Firewall on the VM* : as before  make sure that the appropriate ports are added to the firewall on the VM (as we have seen and done before)
    2.	*Network Route Table*: configure the network route table to make sure that traffic can route between the public subnet wth which the API Gateway is associated and the private subnet to which the VM is linked 
    3.	*Network Security Groups (NSG)*: create an NSG for the VM and one for the API Gateway. Add an ingress rule for the VM's NSG to allow traffic from the NSG defined for the API Gateway and on that latter NSG an egress rule to allow traffic to the VM's NSG. You can allow all ports, or limit it to the specific port(s) listend on by the service in the VM. The great thing about NSG is that you do not need to worry about IP addresses of API Gateway or VM: just attach the NSG to the gateway and the VM with the rules in place and it will be configured.

### One tiny little bit of API Gateway Magic

The OCI API Gateway can help us in many ways with handling requests. From authorization, validation and throttling to transformation of headers and parameter, routing and reporting as well as caching. To give you a little taste of that, let's configure the deployment route to set a default value for the *name* query parameter if no value is provided in the request. 

At the moment, when the URL is invoked without a query parameter called *name* 

``` 
https://<URL for API Gateway>/my-api/welcome
```

the response will be *Hello Stranger!* 

We will change that behavior, and ensure the response will be *Hello Friend!*. We can define validations and transformations on query parameters and headers. One simple transformation allows us to set a value for a query parameter if no value was set already. The API Gateway maybe called without query parameter *name* but in that case we will make sure the request to *myserver* will have that parameterm, with the appropriate value of *Friend*.

Go to the details page for the (API) deployment *myserver-api*. Click on *Edit*. Go to the second page, with *Routes*. Click on the link *Show Route Request Policies*. Click on the *Add* button under *Query Parameter Transformations*.

The *Action* is *Set*, *Behavior* is *Skip* (do not change value when already set), the *Query Parameter Name* is *name* and the *Value* is *Friend*.  

{% imgx aligncenter assets/way-to-go-on-oci-article-2-query-param-transform.png 1200 564 "Definition of a request query parameter transformation to provide a default value for the name parameter " %}  

Click on *Apply Changes*. Then click button *Next* and subsequently *Save Changes*. The deployment will be updated with the changes.

When done, try again to access the URL in the browser, without the *name* query parameter:

``` 
https://<URL for API Gateway>/my-api/welcome
```

The response should be *Hello Friend!* thanks to the magic wrought by the API Gateway Query Parameter Transformation.



## Conclusion
In this article, we continued our journey with Go on OCI. The main focus in this article was *automation*. Using the OCI DevOps services, we created pipelines for build and deployment of a Go application, from sources in the Code Repository to a deployed and running application on a Compute Instance. We used API Gateway to expose our service in a decoupled way to external consumers - for better security, reduced dependencies and improved operations. We saw a small example of API Gateway's capabilities for validating and manipulating requests and responses. 

In the next article, we will create Serverless Functions in Go on deploy them on OCI. And we will start using the Go SDK for OCI that enables us to interact with OCI services from Go applications. The first service to be used is the OCI Object Storage service – for creating buckets, writing and reading files from a local Go application and from the Functions deployed to OCI.  

## Resources

[Source code repository for the sources discussed in this article series](https://github.com/lucasjellema/go-on-oci-article-sources) 

[OCI Documentation - Create DevOps project ](https://docs.oracle.com/en-us/iaas/Content/devops/using/create_project.htm#create_a_project
)

[OCI Documentation - Running a Command on an Instance](https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/Content/Compute/Tasks/runningcommands.htm)

[OCI Documentation - IAM Policies on Artifact Registry](https://docs.oracle.com/en-us/iaas/Content/artifacts/iam-policies.htm)


