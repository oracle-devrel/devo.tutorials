---
title: The Way to Go on OCI

parent:
- tutorials
- way-to-go-on-oci
redirect_from: "/tutorials/way-to-go-on-oci/go-on-oci-article-1"
tags:
- open-source
- devops
- get-started
- back-end
- go
categories:  [clouddev, cloudapps]
thumbnail: assets/landing-zone.png
date: 2022-05-01 11:00
description: How to build and run Go applications on Oracle Cloud Infrastructure Compute Instances. How to produce logging from the Go application and capture the logging into OCI Logging.
toc: true
author: lucasjellema
redirect: https://developer.oracle.com/tutorials/way-to-go-on-oci/go-on-oci-article-1/
---
{% imgx alignright assets/landing-zone.png 400 400 "OCLOUD landing zone" %}



This is the first installment in a five part series about Go and Oracle Cloud Infrastructure. This series discusses how Go applications can be created and run on Oracle Cloud Infrastructure - in Compute Instances (VMs), containerized on Kubernetes or as serverless Functions. The articles show how to automate the build and deployment of these Go applications using OCI DevOps. An important topic is how to use OCI services from Go applications - both those running on OCI as well as Go code running elsewhere. Some of the OCI services discussed are Object Storage, Streaming, Key Vault and Autonomous Database.

In order to follow along with these articles, readers should have at least basic knowledge of how to create Go applications. It is assumed that readers have access to their own Go development environment. Some of the examples and screenshots will specifically mention VS Code as development tool. However, other editors and IDEs can be used as well. The Go code presented in these articles demonstrates a number of mechanisms in their simplest form for maximum clarity and with the least dependencies. Readers should not expect meaningful functionality or production ready code. 

The articles describe how to get Going on OCI and to try out the examples, readers will need to have access to an OCI tenancy with permissions to create the OCI resources discussed in these articles. Most of the resources used are available in the *Aways Free Tier* (Compute Instance, VCN, Autonomous Database, Object Storage, Logging, Resource Manager) or have a free allotment tier for limited monthly usage (Functions, API Gateway, Streaming, Vault, DevOps). 


## 1. Get Going on OCI

The first objective is to create a Compute Instance (a VM) on OCI and create and run a Go application in it. This simple Go application handles HTTP requests from outside the OCI tenancy. Subsequently, the logging from this Go application is channeled into the OCI Logging service where it is available for monitoring and analysis purposes.    

The steps in this article:
* create an OCI Compute Instance and set up Network Security List rules
* create a Go application in the new Compute Instance and run it to handle HTTP requests
* extend the application to produce logging; then route this logging into the OCI Logging service

The final state at the end of the article is shown in the next figure.
![](assets/way-to-go-on-oci-1-end-of-article1.png) 

### Create and Configure OCI Compute Instance

Oracle Cloud Infrastructure offers a wide range in Compute Instances - from bare metal or virtual and from fairly small and always free to quite substantial in terms of CPU and memory resources and associated costs. For the purpose of this article, we can settle for an always free shape for the VM. The image selected is the Oracle Linux Cloud Developer 8 that comes with a wide range of tools and runtimes preinstalled. We will need to associate the Compute Instance with a VCN (a virtual cloud network) and a public subnet - either preexisting ones or to be created along with the new compute instance. 

A public IP address is requested to the compute instance - to allow external consumers to access the HTTP endpoint on which the Go application will process requests and also to make an easy SSH connection to create and run the application in the first place. Note: for serious activities, use of a Bastion server or hands-off operations through automated processes is recommended. An SSH Key Pair is generated and associated with the VM; we need the private key half of this pair in order to establish the SSH connection to the VM.  

To keep your OCI tenancy well organized and have a good overview of the resources created for these *Go on OCI* explorations, it is recommended to create a dedicated compartment. These are free, can easily be created and allow fine grained administration. The compartment used in the examples below is called *go-on-oci*.

![](assets/way-to-go-on-oci-1-create-compartment.png)


#### Create Compute Instance
Open the OCI console in your browser. Switch to the compartment in which you intend to create the Compute Instance.

Type *instance* in the search bar. A popup appears that shows a heading *Services* and below the link *Instances*. 

![](assets/way-to-go-on-oci-1-search-instances.png)
Click this link - that takes you to an overview of the Compute Instances currently present in the compartment. Click on the button *Create Instance*.
![](assets/way-to-go-on-oci-1-create-instance.png)

A simple wizard *Create Compute Instance* is presented. It is a form that allows you to provide the specifications for the compute instance you want to have provisioned. 

First, give it a name; for example *go-app-vm*. Verify that the indicated compartment is indeed the correct one.

Unless you have a reason to customize the *Placement* settings you can accept the defaults.
![](assets/way-to-go-on-oci-1-create-instance-edit-image-shape.png)
Click on the *Edit* link in the *Image and Shape* section. Next, click on the button *Change image*. A list of available VM images appears. Mark the checkbox for image Oracle Linux Cloud Developer. [read the Terms of Use for the image and ] mark the checkbox to indicate you have reviewed the document. Click on *Select image*.
![](assets/way-to-go-on-oci-1-create-instance-select-image.png)

The shape selected by default - always free eligible AMD VM.Standard.E2.1.Micro - is fine, so no need to change it.

Next, turn your attention to the *Networking* settings. The default settings are acceptable. However, if you want to specify better names for the new VCN and subnet or associate the new VM with an existing VCN and (public) subnet, then click on the *Edit* link and define the appropriate settings. Make sure that a public IP address will be assigned.
![](assets/way-to-go-on-oci-1-create-instance-network.png)

In order to connect to the VM once it is running we need to be able to establish an SSH connection. An SSH key pair is used to authenticate our connection to the VM. The VM has the public key and we need the private key to encrypt messages to the VM. Click on *Save Private Key* in order to download this private key to a local file. You will need this file later on so make sure to hang on to it. You do not need the public key.

The default Boot Volume settings are acceptable, so we can skip this section. 

You are now ready to have the Compute Instance provisioned. Click on *Create* to start this action.

![](assets/way-to-go-on-oci-1-create-instance-keypair-boot-done.png)

When you press the *Create* button, there will be a small pause when OCI accepts your provisioning request. Then a page is presented that shows the Provisioning (in progress) overview. 

![](assets/way-to-go-on-oci-1-create-instance-provisioning.png)

After a little while - typically within 1-2 minutes - the Compute Instance is running and the page is refreshed with the runtime details. This page contains the public IP address for the new VM - you will need this value. 

![](assets/way-to-go-on-oci-1-create-instance-running-vm.png)

From this page, you can perform administrative tasks - such as stop, reboot, terminate, audit, add to instance pool, configure agents and create a custom image for additional VMs. 

#### Configure Rules in Subnet Security List 
In order to allow the necessary network traffic out from and into the VM, we need to configure a few rules in the Security List for the Subnet to which the VM is connected. In order to do so, click on the subnet link on the Compute Instance overview page. Alternatively, type *virtual* in the OCI console's search bar, navigate to *Virtual Cloud Network*, click on the VCN created or selected for the VM and click on the relevant subnet.

![](assets/way-to-go-on-oci-1-security-list-subnet.png)
Click on the security list for the subnet. 

Two categories of rules can be defined: Ingress rules that govern traffic coming into the VM and Egress rules for traffic that goes out of the VM. We need the following types of traffic allowed:

* *Ingress*: port 22 - SSH connection from our development environment (public internet)
* *Ingress*: port 8080 (or any other port that we select) - HTTP requests from external consumers of the HTTP server we will implement in Go

![](assets/way-to-go-on-oci-1-security-list-subnet-overview.png)

* *Egress*: port 443 - outbound HTTPS traffic for fetching Go modules (for example with `go get` or `go mod download` ) and performing *git* commands (including `git clone`)

Depending on whether you used an existing subnet or had a new one set up when the VM was created, you may need to configure some or all of these rules. Note: use `0.0.0.0/0` as the Source CIDR in all cases.

The next image shows creation of an Ingress rule for allowing incoming TCP traffic on port 8080, from any originating network address or port.
![](assets/way-to-go-on-oci-1-security-list-subnet-rules.png)

#### Connect to Compute Instance with SSH

There are various tools available that make managing SSH sessions very simple, such as MobaXTerm and Putty. From a Linux command line, the probably most straightforward way to open an SSH connection is like this: 

1. copy the downloaded private key file to current directory

2. Change the accessibility of the private key file

```
chmod 400 <private key file>
```

3. initiate the SSH session:
```
ssh –i <private key file> opc@<public ip address of instance>
```
And to celebrate the success of making the connection, we could do a little looking around in our new OCI Compute Instance. Check for example what versions are available in the VM of some language runtimes:

```
git version
go version
java -version
node -v
python --version
terraform -version
oci --version
```

You could even create a very simple first Go application inside the VM and run it as well.

Type `vi app.go` to bring up the editor (or alternatively use the *nano* or *vim* editor). Enter *Insert* mode by typing `i`. Paste or type this Go code into the editor:

```
package main
import "fmt"

func main() {
        fmt.Println("Hello You")
}
```

Type `esc` followed by `:wq`. This writes the file content and returns you to the command line. You can now this simplest of Go applications, with:

```
go run app.go
```

The program is compiled and executed and the output will appear. You are now officially *going on OCI*.


### Create and Run Go application in Compute Instance

At this point, we have a running OCI Compute Instance that we can connect to via SSH from our local environment. The VM has a number of tools and language runtime environments that allow us to create, compile and run applications. We have prepared inbound network connectivity on port 8080 to the VM. Let us now create a Go application that listens to such inbound [HTTP] requests and serves them with a simple response.

#### Connect to Compute Instance VS Code Remote SSH extension (optional)

There are several tools that facilitate interaction with a remote server over SSH. You can of course pick the one you like best. One option that I have come to appreciate is an extension for Visual Studio Code: the Remote SSH Extension.

In case you use VS Code and are interested in this extension, I will briefly share the steps to get started with it.

Open the *Extensions* tab in VS Code. Type *ssh* in the search bar. A list of extensions will appear with the *Remote SSH* extension at or near the top. 
![](assets/way-to-go-on-oci-1-vscode-remotessh-extension.png)

Install the extension. 

Click on the Remote SSH FS icon. Then click on the icon to create a new SSH FS connection.

![](assets/way-to-go-on-oci-1-vscode-remotessh-createnewconnection.png) 

Provide the name for the new configuration - for example *go-on-oci* - and click on *Save*

![](assets/way-to-go-on-oci-1-vscode-remotessh-namenewconfig.png)

A form is presented in which you provide details for the Compute Instance: – the host's public IP address and SSH port (22), the username (which is *opc* on Oracle Linux images such as the one used for the Compute Instance) and the private key file.

![](assets/way-to-go-on-oci-1-remote-ssh-edit-configuration.png)

(this screenshot only contains the relevant fields; you can ignore other aspects of the configuration)

Click on Save.

With this in place, you can open terminal windows on the OCI Compute Instance from within your local VS Code environment and also explore and manipulate the file system contents of the remote VM from inside VS Code.

![](assets/way-to-go-on-oci-1-vscode-remotessh-opensshsession.png)

Apart from the obvious latency, developing against the remote Compute Instance on Oracle Cloud Infrastructure is the same as working locally in VS Code.

#### Create and Run a Web Server in Go on OCI 

Create a new directory on the remote OCI Compute Instance, called *myserver* - either through the VS Code user interface or on the terminal command line with  `mkdir myserver`.

Create a file `my-server.go`in this directory. Paste the following contents into this file:

```
package main

import (
	"fmt"
	"log"
	"net/http"
)

const DEFAULT_HTTP_SERVER_PORT = "8080"

func greetHandler(response http.ResponseWriter, request *http.Request) {
	log.Printf("Handle Request for method %s on path %s", request.Method, request.URL.Path)
	if request.Method != "GET" {
		http.Error(response, "Method is not supported.", http.StatusNotFound)
		return
	}
	name := "Stranger"
	queryName := request.URL.Query().Get("name")
	if len(queryName) > 0 {
		name = queryName
		log.Printf(" --  query parameter name is set to %s", name)
	}
	fmt.Fprintf(response, "Hello %s!", name)
}

func fallbackHandler(response http.ResponseWriter, request *http.Request) {
	log.Printf("Warning: Request for unhandled method %s on path %s", request.Method, request.URL.Path)
	http.Error(response, "404 path/method combination not supported.", http.StatusNotFound)
	return
}

func main() {
	fileServer := http.FileServer(http.Dir("./website"))
	http.Handle("/site/", http.StripPrefix("/site/", fileServer))
	http.HandleFunc("/greet", greetHandler)
	http.HandleFunc("/", fallbackHandler)

	log.Printf("Starting server at port %s\n", DEFAULT_HTTP_SERVER_PORT)
	if err := http.ListenAndServe(":"+DEFAULT_HTTP_SERVER_PORT, nil); err != nil {
		log.Fatal(err)
	}
}
```

This Go program will start an HTTP Server that listens on port 8080 or incoming requests. Requests with URL path /site are handled by the static content handler that returns files from the local *website* directory (that does not exist yet). Requests with a URL path */greet* are handled by the *greetHandler* function. This function will return a response with a friendly *Hello*, followed by either the value of the query parameter *name* or the hard coded string *Stranger*. Other requests are handled in the *fallbackHandler* function, that returns a 404 HTTP StatusNotFound result.

Under directory *myserver*, create a subdirectory *website*. Create file *index.html* in this subdirectory and paste the following content to this file:

```
<html>
  <head>
    <title>My Website</title>
  </head>
  <body>
    <h2>My Website full of interesting things</h2>
  </body>
</html>
```

![](assets/way-to-go-on-oci-1-remotessh-go-webserver.png)

Our Web Server is ready for some action. Or so it would seem. However, the Oracle Linux image we are using for the VM is configured to reject just any inbound network request (resulting in "Route to host not found" error messages). This is an element of security hardening that comes on top of the Network Security List rules that we discussed earlier. In order to make the operating system accept the inbound requests for port 8080, you need to execute the following statements:

```
sudo firewall-cmd  --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd  --reload
```

And now the Web Server can really get *going*. Execute this command to run the application:

```
go run my-server.go
```
After a few seconds - compilation, initialization - the application is running as you can tell from the logging.

#### Access the Go Web Server

Try to access the Web Server from your local environment, using a curl command 

```
curl <public IP address for Compute Instance>:8080/greet?name=Your+Name
```
![](assets/way-to-go-on-oci-1-go-webserver-response-on-commandline.png)
or in a web browser with this URL:
```
http://<public IP address for Compute Instance>:8080/greet?name=YourNameOrSomeoneElses
```
and:
```
http://<public IP address for Compute Instance>:8080/site/index.html
```
The response should come in - and the logging from the Go application should also indicate the request that was handled. 

![](assets/way-to-go-on-oci-1-go-webserver-response-in-browser.png)



## Connect Go application to OCI Logging service

The Go application *my-server* write log entries - to mark important activities such as starting up the HTTP Server and handling individual HTTP requests. Currently, this logging is written to the standard output. During development, that might be useful. However, for code that runs inside a cloud based compute instance - a VM that runs by itself - it is less useful to write logging to this standard output. 

Oracle Cloud Infrastructure provides facilities for collecting, monitoring and analyzing logging from OCI managed resources as well as custom code running on OCI in a consistent way in a generic, all encompassing environment. OCI Logging ingests log entries from files written in VMs, containers, serverless functions in addition to the logging produced by the OCI sercvices themselves. 

In order to make our Go application's custom logging part of OCI Logging, we will update the Go application to write logging to a file. Subsequently, we will create the configuration on OCI required to feed this logging into the Logging service.  

Modify the code in `my-server.go`. Add the function 

```
func initLogging() (logfile *os.File) {
	syslogWriter, e := syslog.New(syslog.LOG_NOTICE, "greet-app")
	if e == nil {
		log.SetOutput(syslogWriter)
	} else {
		log.Println(e)
	}
	log.SetFlags(log.Ldate | log.Lmicroseconds | log.Llongfile)
	log.SetPrefix("greet-app: ")
	log.Println("Logging initialized upon application restart")
	return logfile
}
```

Add an import of module *os*:

```
import (
    "fmt"
    "log"
    "log/syslog"
    "net/http"
    "os"	
)
```

and add a call to *initLogging()* as first line in function *main* :

```
func main() {
    initLogging()
    ...
```

Run the application again:

```
go run my-server.go
```

This time, we will not get any feedback on the command line from the application. It is still writing log output -  but now it is sent to the Linux syslog. Verify if logging is indeed still being produced using the following command on a different terminal into the OCI Compute Instance: 

```
sudo tail -f /var/log/messages
```

This will show a live feed of all system log messages, including those produced by *my-server*.


### Configure Custom Logging from Compute Instance

There are a few hoops to jump through in order to get the logging written inside the compute instance from the Go application loaded into OCI Logging. The next diagram gives an overview of these steps. In short:
* the Compute Instance needs permission to send logs to the Logging service; this handled through a Dynamic Group and a Policy 
* a Log Group needs to be set up to provide a container for the log that the compute instance will write to
* an Agent Configuration needs to be created that is associated with the Dynamic Group (for the Compute Instance), a custom Log (in the Log Group) and the log file path /var/log/* from which the logs are to be ingested
* the Management Agent plugin needs to be enabled in the Compute Instance's Oracle Cloud Agent configuration

![](assets/way-to-go-on-oci-1-oci-logging-design.png)

#### 1. Dynamic Group go-on-oci-instances

In order to create the Dynamic Group for all Compute Instances in the Compartment, we need the OCID (the Oracle Cloud [resource] Identifier) for the Compartment. To get it, type *comp* in the search bar. Click on the link *Compartments* in the Services section. This will list all visible compartments. Locate the compartment that contains the Compute Instance that you created earlier. Hover your mouse over the value for the compartment in the *OCID* column. Click on the *Copy* link to move the OCID into the clipboard. 
![](assets/way-to-go-on-oci-1-compartment-ocid.png)

Type *dyn* in the search bar. Click on *Dynamic Groups*. Click on the button *Create Dynamic Group*.
![](assets/way-to-go-on-oci-1-create-dynamic-group.png)

Enter the name for the Dynamic Group - for example *go-on-oci-instances* - and type optionally a description. Define the following rule that selects all [compute] instances that are part of the compartment (in this case only the compute instance *go-app-vm*):

``` 
instance.compartment.id = '<compartment_id>'
``` 

Then press *Create*.

![](assets/way-to-go-on-oci-1-define-dynamic-group.png)

#### 2. Create Log Group go-on-oci-logs

Create the log group in OCI Logging. A log group is a logical container for organizing logs. All logs to be generated are associated with a log group.

Type *log g* in the OCI console's search bar. Click on the link *Log Groups* in the Services section of the panel that is shown. An overview page is shown listing all Log Groups in the compartment. 

![](assets/way-to-go-on-oci-1-loggroups-overview.png)

Click on the button *Create Log Group*. 

Creating a Log Group is very straightforward: provide a name and optionally a description. I have called the log group *go-on-oci-logs*; however, any name will do. 

![](assets/way-to-go-on-oci-1-create-loggroup.png)


#### 3. Create the Custom Log and Logging Agent Configuration
To have the custom logs from the Go application on the Compute Instance sent to the Log Group, we need to create a Custom Log Agent Configuration. This Agent Configuration is an instruction for agents running on the Compute Instances about collecting log entries from specific files and sending them to a custom log in a Log Group. An Agent Configuration associates one or more dynamic groups (identifying  compute instances) on which the specific log files should be ingested into the Log Group.

Type *log* in the OCI Console searchbar. Click on the *Logs* link in the *Services* section. This takes you to the Logs page. Click on the button *Create Custom Log*. 

![](assets/way-to-go-on-oci-1-create-custom-log.png)

You now enter a two step wizard for defining the Custom Log and Agent Configuration. Enter the name for the custom log, for example `go-on-oci-log`. The compartment should be set correctly - if not select the compartment that contains the Log Group you have created in the previous section. If not already set, also select the Log Group you have just created. 

![](assets/way-to-go-on-oci-1-create-custom-log-page1.png)

Click on the button *Create Custom Log* to move to the next page.

The second page collects details on the Agent Configuration.

Type the name of the configuration, for example *go-on-oci-log-agent-configuration*. Optionally provide a description, such as *Configuration for log agent to collect Linux system logs from compute instances in dynamic group*. 

The *Group Type* should be set to *Dynamic group*. Select the Dynamic Group *go-on-oci-instances* that you created earlier. Now click on the button *Create* to create a policy for allowing the compute instances in the dynamic group to interact with the OCI Logging service. 

![](assets/way-to-go-on-oci-1-create-custom-log-page2a.png)

A message is presented with the name of and a link to the policy that was created. Its policy statement says *allow dynamic-group go-on-oci-instances to use log-content in tenancy*.

Set the *Input type* to *Log path*. Type a value for *Input name*, such as *linuxsystemlog*. Add the *File path* `/var/log/*`. Note: multiple file paths can be defined for ingesting log files from. 

The fields under the heading *Log Destination* will already be set; these specify the Custom Log in the Log Group and Compartment that were selected on the previous page.

![](assets/way-to-go-on-oci-1-create-custom-log-page2b.png)
Click on the button *Create Custom Log* to create the *Agent Configuration*. 

#### 4. Enable the Management Agent plugin in the compute instance. 
The *Agent Configuration* has been created. It applies to the Cloud Agent that runs inside the Compute Instance that runs the Go application. However, before that agent will actually sent any logs, we have to ensure that the 

Type *instance* in the search bar in the console. Navigate to *Instances*. Drill down to the instance created earlier for running the Go application. Switch to the tab *Oracle Cloud Agent*. Compute Instances based on one of the predefined OCI images - like the Oracle Linux Developer image used for this instance - contain the Oracle Cloud Agent. This is a lightweight process that manages plugins running on the instance. Plugins collect performance metrics, install OS updates, and perform other instance management tasks. The *Management Agent* plugin needs to be enabled. It is this plugin that collects log entries inside the compute instance and sends them to OCI Logging. 

Enable the *Management Agent* plugin if it is not currently enabled. It may take some time for this plugin to go from *disabled* via status *Starting* to status *Running*. 

![](assets/way-to-go-on-oci-1-enable-agent.png)

Once the plugin has status *Running*, it will read new log entries to the files in */var/log/* and send them to the custom log *go-on-oci-log* in the Log Group *go-on-oci-logs*.

To check on the status of the monitoring agent from within the VM, you can execute the statement in a remote SSH session to the Compute Instance:
```
systemctl status unified-monitoring-agent
```
The output should indicate that agent - a Fluentd based data collector for OCI - is running.
![](assets/way-to-go-on-oci-1-logging-agent-running-in-vm.png)


#### 5. Explore logs from Go Application in OCI Logging
The logging agent will scrape and forward new log entries from the system logs in */var/log*. The Go application writes its logging to the system logs which means to */var/log/messages*.

Now *make some noise* - by starting the my-server application if it is not still running and making some HTTP requests to the /greet path and/or the /site path. It will take between 1-2 minutes before the logs that result from these requests are available in the Log Explorer in the OCI Console.

To take a look at the logs in the console, type *log* in the search bar. Then click on Logs.
![](assets/way-to-go-on-oci-1-navigate-to-log-explorer.png) 
The Logs in the compartment are shown. Click on the link for *go-on-oci-log* (or whatever name you assigned to the log).

This takes you to the Log Explorer - a page for browsing and searching through the log entries.
![](assets/way-to-go-on-oci-1-log-explorer.png)
When you scroll down, there is a table with the most recently ingested log entries. In this table will be various Linux system log messages alongside the output from the my-server application.
![](assets/way-to-go-on-oci-1-log-explorer-table-of-entries.png)
To track down the specific log output from *my-server*, we can search for the log prefix assigned in the Go code: *greet-app:*. Click on the link *Explore with Log Search*. The Log Search panel is shown. An

Enter the string *greet-app:* in the field *Custom Filters* and press enter. This string is now a search filter. Press the *Search* button to perform search over the indicated time range of log entries for this filter.
![](assets/way-to-go-on-oci-1-log-entries-from-my-server.png)
The log entries can be expanded for closer inspection. Details are shown for when and where this entry was ingested and how it is stored in the OCI Logging service. The source (instance), source file and type are indicated as well.  
![](assets/way-to-go-on-oci-1-log-entry-expanded.png)

There are three timestamps available - one produced by the Go application, one from the Linux system log handler and one from the Logging agent at the time of scraping the log entry. The delta between the first two is not meaningful and the application really does not have to add the timestamp. The difference between the second and third should be small. The fourth timestamp - when the log record was created in the OCI Log and  became available for scrutiny - is not shown. It would not add eaning to the log entry.

Note: The Cloud Agent is capable of parsing log entries. This means that a log entry does not end up as a single long string in OCI Logging, but instead is parsed into individual fields, that can be searched on using the Logging Query Language. Logging from Go in JSON or CSV format and to application specific logfiles instead of system logs can easily be done. However: on the Always Free Tier Compute Instance shape used in this article, the ability to parse custom logs is not available - neither parsing these logs nor even reading custom log files. 

## Conclusion
In this article, we made the first few steps with Go on OCI. 

After provisioning a Compute Instance based on the Oracle Linux Cloud Developer image we had to set the right network security rules in order to allow outbound traffic (https to fetch modules and perform git operations) and inbound traffic (SSH connection and incoming HTTP requests). Through an SSH connection and using the Go runtime available the VM, we created a simple HTTP Server that can be invoked from anywhere on the public internet. The final stage of the article discussed configuration of logging facilities that enabled the flow of application log entries to the OCI Logging service. The Cloud Agent that is preinstalled in the Compute Instance was configured to scrape and forward the desired log entries. 

In the next article, we will focus on automation of the software engineering process for a somewhat more complex Go application: how to use OCI DevOps for storing the source code, building the executable and storing it as deployable artifact, deploying that artifact to a Compute Instance, exposing an HTTP endpoint for that application through an OCI API Gateway and finally checking its health status after deployment. All using automated pipelines. 


## Resources

[Source code repository for the sources discussed in this article series](https://github.com/lucasjellema/go-on-oci-article-sources) 

[Documentation on OCI Compute](https://docs.oracle.com/en-us/iaas/Content/Compute/home.htm)

[Document on OCI Networking - Security Lists](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/securitylists.htm#Security_Lists)

[Oracle Linux Cloud Developer Image for Compute Instances](https://docs.oracle.com/en-us/iaas/oracle-linux/developer/index.htm#About-the-Oracle-Linux-Cloud-D)

[Documentation on OCI Logging](https://docs.oracle.com/en-us/iaas/Content/Logging/home.htm#top)

[Documentation on OCI Cloud Agent](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/manage-plugins.htm)

[Documentation on OCI Dynamic Groups](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingdynamicgroups.htm)

[VS Code - Remote Development using SSH ](https://code.visualstudio.com/docs/remote/ssh)
