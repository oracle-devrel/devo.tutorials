---
title: Hooking Go applications into OCI Streaming, using OCI Key Vault and Go Deployment on OKE
parent:
- tutorials
- way-to-go-on-oci
redirect_from: "/tutorials/way-to-go-on-oci/go-on-oci-streaming-vault-oke-article-5"
tags:
- open-source
- devops
- get-started
- automation
- iac
categories:  [clouddev, cloudapps]
thumbnail: assets/landing-zone.png
date: 2022-05-01 11:00
description: Hooking Go applications into OCI Streaming, using OCI Key Vault and Go Deployment on OKE
toc: true
author:
  name: Lucas Jellema
  bio: developer, solution architect, blogger, Oracle Groundbreaker Ambassador, Oracle ACE Director
  home: https://technology.amis.nl
  twitter: lucasjellema
  github: lucasjellema
  linkedin: lucasjellema
  location: The Netherlands
  email: lucasjellema@gmail.com
redirect: /tutorials/way-to-go-on-oci/go-on-oci-streaming-vault-oke-article-5
---
{% imgx alignright assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

This is the fifth and therefore last part of a five part series about Go and Oracle Cloud Infrastructure. This series discusses how Go applications can be created and run on Oracle Cloud Infrastructure - in Compute Instances (VMs), containerized on Kubernetes or as serverless Functions. The articles show how to automate the build and deployment of these Go applications using OCI DevOps. An important topic is how to use OCI services from Go applications - both those running on OCI as well as Go code running elsewhere. Some of the OCI services discussed are Object Storage, Streaming, Key Vault and Autonomous Database. 

In order to follow along with these articles, readers should have at least basic knowledge of how to create Go applications. It is assumed that readers have access to their own Go development environment. Some of the examples and screenshots will specifically mention VS Code as development tool. However, other editors and IDEs can be used as well. The Go code presented in these articles demonstrates a number of mechanisms in their simplest form for maximum clarity and with the least dependencies. Readers should not expect meaningful functionality or production ready code. 

The articles describe how to get Going on OCI and to try out the examples, readers will need to have access to an OCI tenancy with permissions to create the OCI resources discussed in these articles. Most of the resources used are available in the *Aways Free Tier* (Compute Instance, VCN, Autonomous Database, Object Storage, Logging, Resource Manager) or have a free allotment tier for limited monthly usage (Functions, API Gateway, Streaming, Vault, DevOps). 


## Introduction

The first part of these series describes provisioning of a Compute Instance based on the Oracle Linux Cloud Developer image, opening it up for inbound and outbound network activity, creating and running a Go application that serves HTTP requests and connecting logging produced by the application to OCI Logging. 

Part two deals with software engineering, automation of build and deployment of the application with the OCI DevOps service. This service is used for storing the Go source code, building the application executable and storing it as deployable artifact, deploying that artifact to a Compute Instance. The article also shows how to expose an HTTP endpoint for the application through an OCI API Gateway. 

Part three shows how to create serverless functions in Go and deploy them on OCI. The Go SDK for OCI is introduced - first for local, stand alone Go applications and subsequently for use from functions - leveraging resource principal authentication. This SDK is used to interact with the OCI Object Storage service for creating buckets and writing and reading files. 

The fourth article discusses the interaction from your Go application with an Oracle Database. This can be a local or on premises database or a database running on some cloud vendor's IaaS instances or an Oracle Cloud Infrastructure Autonomous Database.    

This fifth and last article in this series adds two more OCI services for Go applications to interact with: OCI Streaming - a high volume streaming message broker that allows for decoupled interactions between different microservices and other components - and the OCI Key Vault for managing secrets - such as Oracle Wallet with database credentials. This article also introduces a third type of application platform - next to VM and serverless function - in the shape of the managed OCI Kubernetes Enginer (OKE), and it shows how DevOps Deployment Pipelines can deploy our Go applications to OKE in an automated way.   

## Publishing Messages from Go application to OCI Streaming

In this scenario we will work with the OCI [Event] Streaming Service - a managed Pub/Sub message broker service, similar to Apache Kafka. Events are published to Streams (aka Topics) and can be consumed from those Streams, by one or multiple consumers. Consumption can be done from several starting point (at or from a specific offset, from a specific time, as much as is available, only new events) . Note that consumers have to actively come to the Streaming service and collect messages. There is no push mechanism that will trigger listeners whenever new messages have been published to the Stream. There is no concept of subscription: consumers just create a 'cursor' (somewhat similar to a session or a [long running] query) and start pulling messages in the context of that cursor.

Streaming can be used for messaging, ingesting high-volume data such as application logs, operational telemetry, web click-stream data, or other use cases in which data is produced and processed continually and sequentially in a publish-subscribe messaging model. Messages are retained for up to 7 days. There are limits on how much data a Stream can handle per second, but these limits are fairly high (1MB per partition per second, 1MB maximum message size, five consume calls per second).

We will first create a Stream (aka Topic), try it out in the OCI console and then create a local Go application that can publish messages to the Stream (using the Go SDK for OCI once again).

### Create Stream 

Creating a Stream in the Console is dead easy. Producing a Test Message too and Consuming the Test Messages as well. Getting going this way takes all of three minutes, if not less.

Type *str* in the OCI Console search box. Then click on *Streaming | Messaging*. 

Click on button *Create Stream*.

![](assets/go5-create-stream0.png)  

Provide some details on the stream – its name (*go-on-oci-stream*), the number of partitions (leave at one), the retention time (24 hours should be fine for our purposes). Leave the radio button selected for *Auto-Create a Default Stream Pool*.

![](assets/go5-create-stream1.png)  

Then press button *Create Stream*. Now the Stream will be created, which takes a few seconds to complete.

![](assets/go5-streamcreated.png)  

### Try out the new Stream

When the Stream has been created and is active, click on button *Produce Test Message*. Type a message and press *Produce*. 

![](assets/go5-producemessage.png) 

The console will indicate that the message was produced successfully. Press the *Cancel* link to close the popup window. 

Click on the button *Load Messages*. All recently (last 60 seconds) published messages on the stream are displayed. The test message that was published moments ago should show up.

![](assetsd/5go-loadmessages.png)  


### Go Message Producer

The file `producer.go` in the directory `applications/message-producer` in the source code repository for this article series is a Go client for a Stream on OCI. This file assumes a local `$HOME/.oci/config` file that provides the details to connect to OCI - as a user with permissions on the stream. A `StreamClient` is initialized and function PutMessages is invoked with a request targeted at the `streamOCID` for the new stream that contains two messages.

The code is quite straightforward:


```go
package main

import (
	"github.com/oracle/oci-go-sdk/v65/common"
	"github.com/oracle/oci-go-sdk/v65/streaming"
)

const (
	streamMessagesEndpoint = "<the messages endpoint for the stream>"
	streamOCID             = "<the OCID of the stream>"
)

func main() {
	streamClient, _ := streaming.NewStreamClientWithConfigurationProvider(common.DefaultConfigProvider(), streamMessagesEndpoint)
	putMsgReq := streaming.PutMessagesRequest{StreamId: common.String(streamOCID),
			PutMessagesDetails: streaming.PutMessagesDetails{
				// two messages are put on the Stream in the single request 
				Messages: []streaming.PutMessagesDetailsEntry{
					{Key: []byte("key dummy-0" ), Value: []byte("my happy message-")},
					{Key: []byte("key dummy-1-"), Value: []byte("hello dolly and others-")}}},
		}
	streamClient.PutMessages(context.Background(), putMsgReq)
}
```

Before you can run `producer.go`, you have to set the appropriate values for `streamOCID` and `streamMessagesEndpoint`. Then run `go mod tidy` on the command line in the directory that contains `producer.go`.

Execute `go run producer.go`. Use the OCI Streaming console to inspect the arrival of messages. Click on the button `Load Messages`. You will see the messages produced by the Go application. Feel free to change the content or number of messages produced, run the producer again and check again for the messages in the console.

![](assets/go5-messages-published-by-producer.png)  


### Consume Messages from a Stream in a Go application

A stream is not much use if we can only produce messages to it: messages need to be consumed before they expire. If they do not, they have been pointless. 

The next application - to be found in the source code repository in directory `applications\message-consumer` - does exactly this. From Go code, using the Go SDK for OCI, it creates a client for OCI Streaming. Then it makes a *cursor request*. A cursor is pointer to a location in a stream and represents a specific consumer. The application uses the cursor to make requests for messages. If more messages are available on the stream beyond the current cursor's offset, then the next batch of messages is delivered (and the offset is moved). When all messages have been retrieved through the cursor, the request will result in a response without messages. The client can continue polling (with) the cursor for new messages on the stream.  

```go
package main

import (
	"context"
	"fmt"

	"github.com/oracle/oci-go-sdk/v65/common"
	"github.com/oracle/oci-go-sdk/v65/streaming"
)

const (
	streamMessagesEndpoint = "https://cell-1.streaming.us-ashburn-1.oci.oraclecloud.com"
	streamOCID             = "ocid1.stream.oc1.iad.amaaaaaa6sde7caa56brreqvzptc37wytom7pjk7vx3qaflagk2t3syvk67q"
)

func main() {
	streamClient, _ := streaming.NewStreamClientWithConfigurationProvider(common.DefaultConfigProvider(), streamMessagesEndpoint)
	partition := "0" 
	createCursorRequest := streaming.CreateCursorRequest{
		StreamId: common.String(streamOCID),
		CreateCursorDetails: streaming.CreateCursorDetails{Type: streaming.CreateCursorDetailsTypeTrimHorizon,
			Partition: &partition, // mandatory: which partition to read from; note: with a GroupCursor, OCI Streaming assigns partitions to consumers (represented by cursors)
		}}
	createCursorResponse, _ := streamClient.CreateCursor(context.Background(), createCursorRequest)
  // using the cursor, go retrieve messages 
	consumeMessagesLoop(streamClient, streamOCID, *createCursorResponse.Value)
}

func consumeMessagesLoop(streamClient streaming.StreamClient, streamOcid string, cursorValue string) {
	getMessagesFromCursorRequest := streaming.GetMessagesRequest{Limit: common.Int(5), // optional: how many messages to collect in one request
		StreamId: common.String(streamOcid),
		Cursor:   common.String(cursorValue)}
	for i := 0; i < 15; i++ {
    // fetch a next batch of maximum Limit (==5) messages
		getMessagesFromCursorRequest.Cursor = common.String(cursorValue)
		// (Try to) fetch new messages from the cursor (starting from just after the offset of the previous call)
		getMessagesFromCursorResponse, _ := streamClient.GetMessages(context.Background(), getMessagesFromCursorRequest)
		for _, message := range getMessagesFromCursorResponse.Items {
			fmt.Println("Key : " + string(message.Key) + ", value : " + string(message.Value) + ", Partition " + *message.Partition)
		}
		cursorValue = *getMessagesFromCursorResponse.OpcNextCursor
	}
}
```

Run this application on the command line - after `go mod tidy` - using `go run consumer.go`. The output - depending on what messages have been produced to the topic (and are still retained) - will look similar to:

```console
starting iteration  0
Key : , value : My first messge - hello dolly!, Partition 0
Key : key dummy-0-0, value : value dummy-0, Partition 0
Key : key dummy-1-0, value : value dummy-0, Partition 0
Key : key dummy-0-1, value : value dummy-1, Partition 0
Key : key dummy-1-1, value : value dummy-1, Partition 0
starting iteration  1
Key : key dummy-0-2, value : value dummy-2, Partition 0
Key : key dummy-1-2, value : value dummy-2, Partition 0
```

Multiple values for *Type* can be defined that define where the cursor should start fetching message from the Stream:

- `AFTER_OFFSET:` The partition position immediately following the offset you specify. (Offsets are assigned when you successfully append a message to a partition in a stream.)
- `AT_OFFSET:` The exact partition position indicated by the offset you specify.
- `AT_TIME:` A specific point in time.
- `LATEST:` The most recent message in the partition that was added after the cursor was created.
- `TRIM_HORIZON:` The oldest message in the partition that is within the retention period window.

When `AFTER_OFFSET` or `AT_OFFSET` are defined, the value for offset must be provided to. When `AT_TIME` is set as type, then a value for time is mandatory.

For example - where message retrieval should start after offset 5:

```go
	partition := "0"
	offset := common.Int64(5)
	createCursorRequest := streaming.CreateCursorRequest{
		StreamId: common.String(streamOCID),
		CreateCursorDetails: streaming.CreateCursorDetails{Type: streaming.CreateCursorDetailsTypeAfterOffset,
			Offset:    &offset,
			Partition: &partition,
		}}
```

Instead of explicitly defining individual, isolated consumers (aka cursor) that link up with a specific partition, we can use the concept of consumer groups and leave it to the Streaming Service to associate partitions with specific consumers (aka cursors because each consumer is represented by an active cursor). In that case, the body of function `main` becomes:

```go
func main() {
	streamClient, _ := streaming.NewStreamClientWithConfigurationProvider(common.DefaultConfigProvider(), streamMessagesEndpoint)
	// Type can be CreateGroupCursorDetailsTypeTrimHorizon, CreateGroupCursorDetailsTypeAtTime, CreateGroupCursorDetailsTypeLatest
	createGroupCursorRequest := streaming.CreateGroupCursorRequest{
		StreamId: common.String(streamOCID),
		CreateGroupCursorDetails: streaming.CreateGroupCursorDetails{Type: streaming.CreateGroupCursorDetailsTypeTrimHorizon,
			CommitOnGet:  common.Bool(true), // when false, a consumer must manually commit their cursors (to move the offset).
			GroupName:    common.String("consumer-group-1"),
			InstanceName: common.String("go-instance-1"), // A unique identifier for the instance joining the consumer group. If an instanceName is not provided, a UUID will be generated
			TimeoutInMs:  common.Int(1000),
		}}
	createGroupCursorResponse, _ := streamClient.CreateGroupCursor(context.Background(), createGroupCursorRequest)
	consumeMessagesLoop(streamClient, streamOCID, *createGroupCursorResponse.Value)
}
```

As long as there is only a single instance in the group, all messages on all partitions are handed to this consumer's cursor. When multiple instances are added to the group, they will each get one or more partitions assigned to them (if enough partitions are available for the stream) and receive messages from those partitions. Multiple consumers can work in parallel on processing the messages on the stream without any message being processed more than once. 

## Create an OCI Vault and Store Secrets

Applications often use configuration settings to run. These settings determine part of the behavior of the application or instruct the application about endpoints, file system locations and credentials for making connections. The configuration settings can be enviroment dependent: the same application in a test environment uses different values than in the production environment. Some of the configuration settings are sensitive - such as passwords or private keys.

The Go applications discussed so far in this series did not work very explicitly with such configuration settings. Some applications contain hard coded references to compartment, bucket and stream or are committed to the code repostory with a database wallet and hard coded database connection details. This is really not a proper way of working.

From this point on, we will improve our way of working, using OCI Vault. The Vault service on OCI lets you create vaults in your tenancy as containers for encryption keys and secrets. Vaults are logical entities where the Vault service creates and durably stores keys and secrets. The type of vault you choose  determines features and functionality such as degrees of storage isolation, access to management and encryption, and scalability. The type of vault you have also affects pricing.

If needed, a virtual private vault provides you with a dedicated partition in a hardware security module (HSM), offering a level of storage isolation for encryption keys that’s effectively equivalent to a virtual independent HSM. Keys are stored on highly available and durable hardware security modules (HSM) that meet Federal Information Processing Standards (FIPS) 140-2 Security Level 3 security certification. The Vault service uses the Advanced Encryption Standard (AES) as its encryption algorithm and its keys are AES symmetric keys. Note that the virtual private vault has a substantial price tag (several $ per hour) whereas the default vault can be used for free.

Keys are logical entities that represent one or more key versions that contain the cryptographic material used to encrypt and decrypt data, protecting the data where it is stored. When processed as part of an encryption algorithm, a key specifies how to transform plaintext into ciphertext during encryption and how to transform ciphertext into plaintext during decryption. Plain text in this sense can be base64 representation of binary content and can also be a JSON document that contain many configuration settings in a single key.

Vaults are first and foremost associated with secrets that contain sensitive information. And of course that is what they are good at. However, even information that may not be very sensitive can be stored in a key to be used by the application during deployment or at runtime to help define the environment specific settings and behavior. A reference to the Vault Secret is all that the application needs to retrieve the *secret* that provides the required settings. No more hard coding that is ugly, against any best practices and that makes it impossible to use a single code base for all environments. Secrets can be managed independently of an application. However, when the value of secret changes and you want the application to start using the new values, you have to make sure the application reinitializes using the changed values.

We will create a *Vault* and create a simple secret that we read from a Go application. Next we will create a secret that contains an Oracle Wallet and a second secret with a JSON document with additional database connection details. Using this secret, we create an application that can work with an(y) Oracle Database and only learns at runtime when it accesses the secret how to connect to the database. Change the secret, restart the application and a different database is connected to.


### Create an OCI Vault. 

Type *vau* in the search box in the OCI Console. Then click on the link *Vault | Identity & Security*. The overview page with all vaults in the current compartment is shown - probably without any entries.

Click on button *Create Vault*. In the *Create Vault* form enter the name for the new vault: *go-on-oci-vault*. The new vault does not have to be a *Virtual Private Vault*, so leave the checkbox unchecked. Press the *Create Vault* button to have the vault creating.
![](assets/go5-createvault.png)  
You are returned to the list of vaults - this time with the new vault, in the status *creating*. It can take up to one minute or so for the vault to be initialized.

When the new vault's status is *Active*, click on the name of the vault to navigate to the details page. We need to create a *master encryption key* for the vault before we can start creating secrets in it. Enter the name for the master key - for example *go-on-oci-vault-master-key*. Accept all default values and click on *Create Key*. It will take a little time for this new master key to be produced.

![](assets/go5-createmasterkey.png)  

### Create a Secret

We now have a vault and a master key to encrypt any secrets we will store in the vault. We are ready to start defining secrets in the vault. Let's start with a very simple one. 

Click on the link for tab *Secrets*. Then click on button *Create Secret*. A page is presented where a new secret can be created.

Type the name for the secret - for example *greeting-of-the-day*. Select the master key we have just set up for the vault. Leave the selection list *Secret Type Template* at *Plain Text*. Then type the value of the secret greeting, for example *Have a wonderful day*. Or anything else, it does not really matter right now. Click on *Create Secret* to save the new secret to the store. This is the start of what internally is called a *secret bundle*. A secret bundle consists of the secret contents, properties of the secret and secret version (such as version number or rotation state), and user-provided contextual metadata for the secret. When you rotate secret, you provide new secret contents to the Vault service to generate a new secret version. The complete version history of all values that will be assigned to the secret, throughout time are retained.

![](assets/go5-createsecretgreeting.png)  

### Read Secret from Go application
The secret that you just defined is now urgently required in our Go application. Let's explore how from our application we can get hold of the values of secrets. File `secret-reader.go` in directory `applications/secret-reader` in the source code repository contains the probably most straightforward example of how to retrieve a secret from an OCI Vault from Go. It uses the Go SDK for OCI and the only piece of information it needs - in addition to the `$HOME/.oci/config` file is the OCID for the secret to be retrieved. Note: the assumption is that whichever user's credentials are configured in the config file has read permissions on the secret.

```go
package main

import (
	"context"
	b64 "encoding/base64"
	"fmt"

	"github.com/oracle/oci-go-sdk/v65/common"
	"github.com/oracle/oci-go-sdk/v65/secrets"
)

const (
	secretOCID = "<OCID of the Secret to be Read from a Vault"
)

func main() {
	secretsClient, _ := secrets.NewSecretsClientWithConfigurationProvider(common.DefaultConfigProvider())
	secretReq := secrets.GetSecretBundleRequest{SecretId: common.String(secretOCID)}
	secretResponse, _ := secretsClient.GetSecretBundle(context.Background(), secretReq)
	contentDetails := secretResponse.SecretBundleContent.(secrets.Base64SecretBundleContentDetails)
	decodedSecretContents, _ := b64.StdEncoding.DecodeString(*contentDetails.Content)
	fmt.Println("Secret Contents:", string(decodedSecretContents))
}
```

Run the application - after you have changed the value of *secretOCID* - using `go run secret-reader.go`. This should result in the content of the secret that you have just created being printed on the command line.

To see the effect of managing configuration settings separate from the application source code, update the secret in the OCI Console and run the application again. You should now see the changed content - because without further instructions the application will always retrieve the latest version of the secret. Not only does the code not contain the highly sensitive value of the secret - it also remains unchanged when the value of the secret is updated. In this case, we had to restart the application to get the updated value. How to refresh the updated values of configuration settings in live applications is an interesting topic - for another moment. Let's first create secrets that actually contain sensitive information. 

### Store Oracle Database connection details and Wallet in Vault

Information that we stored hard coded in our source code and stored completely exposed in our source code repository in the previous article were the database connection details and the Oracle Wallet. In a real environment that would be inexcusable. A proper way to handle such data would be using the vault. The application knows it has to connect to a database - but it does not know where it is and using which credentials it can be connected with. That information can be retrieved from the vault - using the secret identifiers and only if the application is running as a user or on a host that has permissions for reading the content of these secrets.

Storing the database connection details - the `autonomousDB` *struct* in the file *data-service.go* in application *data-service* discussed in the previous article - a secret is not very difficult at all. Create a string formatted as JSON from the data in the struct:

```
{ "service":        "k8j2fvxbaujdcfy_goonocidb_medium.adb.oraclecloud.com",
  "username":       "demo",
  "server":         "adb.us-ashburn-1.oraclecloud.com",
  "port":           "1522",
  "password":       "thePassword1"
}
```

Go to the vault page for *go-on-oc-vault* in the OCI console. In the *Secrets* tab, click on *Create Secret*. Enter the name for the secret: *autonomousDB-demo-credentials*. Select the master encryption key. Paste the JSON content with database connection details as the *Secret Contents* - with type template still on *Plain-Text*. The click on button *Create Secret*. 

![](assets/go5-create-secret-autonomousdb-credentials.png)  

In the Go application, define a type to hold the database credentials:

```go
type DatabaseConnectDetails struct {
	Service        string `json:service`
	Username       string `json:username`
	Server         string `json:server`
	Port           string `json:port`
	Password       string `json:password`
	WalletLocation string `json:walletLocation`
}
```

and write code to decode the content from the secret into a variable based on this type 

```go
    secretReq := secrets.GetSecretBundleRequest{SecretId: common.String(secretOCID)}
	secretResponse, _ := secretsClient.GetSecretBundle(context.Background(), secretReq)
	contentDetails := secretResponse.SecretBundleContent.(secrets.Base64SecretBundleContentDetails)
    decodedSecretContents, _ := b64.StdEncoding.DecodeString(*contentDetails.Content)
	var dbCredentials DatabaseConnectDetails
    json.Unmarshal(decodedSecretContents, &dbCredentials)
	fmt.Println("database connect details for user: " + dbCredentials.Username)
```

Next we need to also store the wallet file *cwallet.sso* in a secret. This file contains binary content. In order to store this content as a secret we turn it into a string representation by encoding as base64. On the Linux command line this can easily be done, for example with the command:

```console
base64 -i cwallet.sso > cwallet-sso-base64.txt
```

File `cwallet-sso-base64.txt` contains the content we want to use for the secret. Just as before from the vault page for *go-on-oc-vault* in the OCI console, go to the  *Secrets* tab and click on *Create Secret*. Enter the name for the secret: *autonomousDB-cwallet-sso*. Select the master encryption key. Paste the base64 content with database wallet details as the *Secret Contents* - with type template set to on *Base64*. The click on button *Create Secret*.  

![](assets/go5-createsecret-for-cwallet.png)  


The contents of this secret can be retrieved from the Go code in the same way as before. However, this time the application needs to write a local `cwallet.sso` file with the contents from the secret:

```go
	decodedSecretContents, _ := b64.StdEncoding.DecodeString(*contentDetails.Content)
	_ = os.WriteFile("./cwallet.sso", decodedSecretContents, 0644)
```

This allows the application - using only the OCID values for the two secrets with database connection details and the database wallet file - to initiate communications with the database it needs to use in its current environment. Nothing hard coded, nothing exposed.
### Go application connecting with Oracle Database based on Secrets from Vault

Directory `applications/safe-database-client` in the source code repository for the article contains the code for a simple Oracle Database client application. It is very similar to what we discussed in article four regarding the application `applications/go-orcl-db`. The main difference: this application does not contain a wallet file or any database connection details. However, it does require two references to OCI Secrets - one OCID refers to the secret with the JSON string with connection details and the other OCID is for a secret that contains the base64 encoded representation of the `cwallet.sso` file.  

The code in file `oracle-database-client-app.go` has two variables that you need to provide values for in order to run this application:

```go
const (
	autonomousDatabaseConnectDetailsSecretOCID = "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caabn37hbdsu7dczk6wpxvr7euq7j5fmti2zkjcpwzlmowq"
	autonomousDatabaseCwalletSsoSecretOCID     = "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caazzhfhfsy2v6tqpr3velezxm4r7ld5alifmggjv3le2cq"
)
```

Using these  values, two secrets are retrieved from the vault. One is used to write the file `cwallet.sso` in the local directory, the other is used to construct an instance of type `DatabaseConnectDetails` that contains login details for the database: username, password, host, port, service. The connection is created - as was the case in the previous article - in the file `godror-based-oracle-database-client.go`. 

You can run the application on the command line with `go run *.go`. It will connect to the Autonomous Database and perform some small SQL feats. The relevance of this example is that the application does not require any information at all about the database it is going to interact with.

Note: in order to run an application on OCI that needs to read secrets from an OCI Vault, you need to make sure that through Resource Principal or Instance Principal authentication the following policy applies to the host that runs the code:

```
allow dynamic-group my-secret-group to read secret-family in compartment go-on=oci where target.secret.name = 'my-secret'
```

## From Streaming Messages to new Database Records

It is not too hard to pull the previous steps we took together and create a single application that contains no configuration - except for some OCID values for secrets in the OCI vault - and still can subscribe to a Stream in OCI, poll and consume messages and create database records in an Autonomous Database on OCI for every message received from the Stream. With the preparations we have made in the previous sections, this is easily accomplished.

The application we are discussing now is visualized in the next figure:

![](assets/go5-endtoend-readsecrets-consumemessages-createdbrecords.png)  

The code for this application is in directory `applications/from-stream-to-database`. The files are familiar: `consumer.go` retrieves the secret with details for subscribing to the stream and `oracle-database-client-app.go` does the same thing for the database connection details. This last file also exposes function `PersistPerson` that can be invoked with an instance of type `Person` that is subsequently turned into a new database record. Make same changes in `oracle-database-client-app` as in the previous section - with the OCID values for the secrets for database connection details and the database wallet.

You need to create a secret in the OCI vault - with Stream details in a JSON string similar to this one (make sure to set the values that apply to your environment):

```
{
 "streamMessagesEndpoint" : "https://cell-1.streaming.us-ashburn-1.oci.oraclecloud.com" ,
 "streamOCID"             : "ocid1.stream.oc1.iad.amaaaaaa6sde7caa56brreqvzptc37wytom7pjk7vx3qaflagk2t3syvk67q"
}
```

You can call the secret *stream-connection-details*.

![](assets/go5-secret-stream-connection-details.png)  

Use the OCID for this new secret to set the value for `const streamDetailsSecretOCID` in file `consumer.go` in `applications/from-stream-to-database/consumer.go`. The `main` function in this file subscribes to the stream and starts a series of iterations in which it polls the stream for new messages. Whenever a message is consumed, it is supposed to hold details for a person in a valid JSON message that is decoded into a Person instance and passed to `PersistPerson`.

You can publish messages to the stream in the OCI Console. Go to the page for the stream in the console. Click on button *Produce Test Message*. Type or paste a valid JSON message with Person details that looks as the next message. 

```
{
	"name" : "John Doe",
	"age" : 34,
	"comment" : "Nice chap, good looking; not too bright"
}
```

Then press button *Produce* to publish the message on the topic and make it available for processing by the consumer.

![](assets/go5-producepersontestmessage.png)  

Feel free to publish the message multiple times. It will not result in multiple database records (the name is used as identifier) but you will see some effect in the logging of the application. Of course if you make changes in the name - however small - between the messages, you will get many more records created in the database. 

Note: the code is not very robust. It will likely choke on messages with a different format, just so you know.

## Deploy Message Publisher on OKE

One runtime platform for our Go applications on OCI that we have not discussed yet is Kubernetes. Or more specifically: Oracle Container Engine for Kubernetes or OKE for short. We have taken our executable compiled from the Go source code and deployed them on a compute instance and we have turned the source code into a serverless function. We have not yet containerized a standalone application and deployed it on an OKE cluster instance. That is what we will do in this final section of this article series.

The steps in short:
* build and run the enhanced *message producer* application locally (or on the *go-app-vm* compute instance)
* create a light weight container image for the *message producer* application
* run a local container to provde the image is complete and correct
* push the container image to the OCI Container Image Registry
* optionally: pull the container image from the registry and run a container in the Cloud Shell or on the *go-app-vm* compute instance
* create an OKE cluster instance (using the quick start wizard and consisting of a single node)
* run the *message producer* application on the OKE cluster instance (manual deployment from *kubectl*, passing the OCID of the stream to publish to as environment variable)
* create an OCI DevOps deployment pipeline to publish the *message producer* container image to the OKE cluster instance - and run the pipeline
* create an OCI DevOps build pipeline to build the *message producer* container image from the source code repository, publish the image to the container image registry and trigger the deployment pipeline

### build and run the enhanced *message producer* application locally (or on the *go-app-vm* compute instance)

Directory `applications/person-message-producer` in the source code repository for this series of articles contains the Go application that publishes person messages to the Stream on OCI. The code for the message producer is in file `person-producer.go`.

The code needs to have an environment variable set that indicates the secret in the OCI vault for the details for the stream. That secret was defined earlier in this article as *stream-connection-details*. The environment variable is set as:

```console
export STREAM_DETAILS_SECRET_OCID="ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caa6m5tuweeu3lbz22lf37y2dsbdojnhz2owmgvqgwwnvka"
```

Replace the value with the OCID of the secret in your environment. Note: you have just used this OCID in the previous section to set the value for `const streamDetailsSecretOCID` in file `consumer.go` in `applications/from-stream-to-database/consumer.go`.

To run the application successfully locally, there needs to be an OCI configuration file called `config` in `$HOME/.oci`. If it is called differently or if it is located in a different directory, you can specify the fully qualified path to the configuration file using environment variable OCI_CONFIG_FILE. Its default (assumed) value is `$HOME/.oci/config`.

With the (implicit) reference to the OCI configuration file in place, the application that starts producing random person messages to the OCI Stream `go-on-oci-stream` can be started from the command line using:

```console
export INSTANCE_PRINCIPAL_AUTHENTICATION="NO"
go run person-producer.go
```

On the command line this looks like:

![](assets/go5-commandline-output.png)  

You can check the messages that are published to the stream in the console (if you get there within one minute)
![](assets/go5-personmessages-in-console.png)  

### create a light weight container image for the *message producer* application

The objective we are working towards is running the message producer as a containerized application on an OKE cluster. An essential step to get there is creating a container image for the application.

The Go application is built into a binary executable, so the resulting container image is dead simple: just a single binary executable file. Well, almost. We want the container image to be small. So for example based on the lean `alpine` Linux base image. We also need to make that the right ca-certificates are installed in the image - otherwise the requests to the HTTPS API endpoints fail. And the Go application needs to be compiled for the proper runtime environment. The specific build command we need in this case to create the smallest possible executable that can run inside the Alpine container is:

```console
CGO_ENABLED=0 GOOS=linux go build -o person-producer -ldflags="-s -w" -tags=containers
```

The result of this command is a standalone binary executable file of about 6MB.

The container image is built from a Dockerfile called `DockerfileAlpine`; it is located in the same directory as `person-producer.go`. It has the following content:

```
FROM alpine:latest

WORKDIR /app

# copy the OCI Configuration file and the associated private key file - note: only for testing the container image locally; 
# remove these lines before building the image that is pushed to the container image registry 
COPY config  ./ 
COPY oci_api_key.pem  ./ 

# add ca-certificates to allow signed communications
RUN apk --no-cache add ca-certificates

# copy the application's binary executable 
COPY person-producer  ./ 
CMD ["./person-producer"]
```

The container image is created from the latest *alpine* image. A directory called */app* is created and used for copying various files to. The files that are copied to `/app` are: `config` (the OCI Configuration file), `oci_api_key.pem` (the private key file referenced from the OCI Configuration file) and `person-producer` (the binary executable produced using `go build`). The `RUN apk` line adds the required certificates to the image. The last line `CMD ["./person-producer"]` makes the application start up when a container based on this image starts running 

Copy the file `$HOME/.oci/config` and the referenced *.pem file as *oci_api_key.pem* to the current directory. Update file `config` and set the parameter `key_file` to:
```
key_file=/app/oci_api_key.pem
```

Note: adding the OCI config and private key file should (of course) never be done in a container image that leaves you machine. We only do it now to locally test the image. Then we will rebuild the image without these files and only then push it to the container image registry.


### build and run a local container to provde the image is complete and correct

Build the container image locally using this command:

```console
docker build -t person-producer:1.0.0 -f DockerfileAlpine .
```

Building the container will take some time the first time - when the base image needs to be loaded - and probably lasts less than 15 seconds on any subsequent iteration.

You can check the success of the build process by inspecting the command line output, using `docker images | grep person-producer` and by running a container based on the image:

```console
docker run --name person-messenger -e OCI_CONFIG_FILE=/app/config -e INSTANCE_PRINCIPAL_AUTHENTICATION=NO -e STREAM_DETAILS_SECRET_OCID=$STREAM_DETAILS_SECRET_OCID person-producer:1.0.0
```

There will be some positive output from the container:

```console
docker run -e OCI_CONFIG_FILE=/app/config -e INSTANCE_PRINCIPAL_AUTHENTICATION=NO -e STREAM_DETAILS_SECRET_OCID=$STREAM_DETAILS_SECRET_OCID person-producer:1.0.0
Welcome from Container - About to publish some person records to the stream
OCI_CONFIG_FILE (only relevant when not doing instance principal authentication): /app/config
{ RawResponse={200 OK 200 HTTP/1.1 1 1 map[Access-Control-Allow-Credentials:[true] Access-Control-Allow-Methods:[POST,PUT,GET,HEAD,DELETE,OPTIONS] Access-Control-Allow-Origin:[*] Access-Control-Expose-Headers:[access-control-allow-credentials,access-control-allow-methods,access-control-allow-origin,connection,content-length,content-type,opc-client-info,opc-request-id,retry-after] Connection:[keep-alive] Content-Length:[134] Content-Type:[application/json] Opc-Request-Id:[873706f4a
....
```

And if you check in the OCI console for the Stream details you will find new Person messages that are published by the application running in the container. 

This gives us confidence in the container image. It is almost ready to be used outside the local environment. But not quite.

Open file `DockerfileAlpine`. Comment out or remove the two lines (7 and 8) that copy the OCI Config and private key file. Then rebuild the container image:

```console
docker build -t person-producer:1.0.1 -f DockerfileAlpine .
```

The 1.0.1 image does not have the private parts that we do not want to ship.  
###  push the container image to the OCI Container Image Registry

The container image needs to be pushed to the OCI Container Image Registry before it can be deployed to an OKE Cluster. The steps for pushing are as described below.

A repository inside the container registry is a collection point for versions of a container image. Such a repository is created when an image is pushed - based on the name of the image. The name is typically composed of `<region key>/<namespace>/<prefix>/<image-name>:<version tag>`. The *prefix* and *image-name* together become the name of the repository; this name is not tied to a compartment. However, in order to organize the Container Image Registry in a similar way as you have organized compartments you may consider to create the repository expicitly in a a specific compartment, through the OCI Console or using the OCI CLI or even an API or Terraform operation. When you create the repository beforehand, you can create it in the context of a specific compartment. The name of the compartment (or even the names of levels of nested compartments) become part of the prefix of the container images. 

For example: create a repository in the OCI Container Image Registry in the context of compartment `go-on-oci` and call the repository `person-producer`. Next when the container image is pushed as `<region key>/<namespace>/go-on-oci/person-producer:<version tag>`, this image will be stored in the repository. If you do not create the repository beforing pushing the image, a repository is created automatically in the context of the root compartment, with a name of `go-on-oci/person-producer`. Everything will still work fine. The repository structure is just a little less nice.

![](assets/go5-create-image-repository.png)  

After either creating the repository or not creating the repository (your choice), on the command line of your development environment do a docker login to `<region key>.ocir.io` where you have to provide your region key. We did this in the third article in the series. You wil need the login name and the authentication token. 

```console
docker login iad.ocir.io
```

Next, the locally built image is tagged for use in the OCI Container Image Registry, using this command:

```console
docker tag person-producer:1.0.1 <region key>/<namespace>/<prefix>/person-producer:1.0.1
```

In my case, the command is as follows:

```console
docker tag person-producer:1.0.1 iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
```

With the login done and this tag in place, the container image can be pushed. 

```console
docker push <region key>/<namespace>/<prefix>/person-producer:1.0.1
```

In my case, the command resolves to:

```console
docker push iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
```

You can check the success of the push by checking the OCI Container Image Registry through the OCI console. 


### optionally: pull the container image from the registry and run a container in the Cloud Shell or on the *go-app-vm* compute instance

An easy way to verify the existence of the container image is on OCI Cloud Shell. Simply open the Cloud Shell from the OCI Console. Then run:

```
docker run -e INSTANCE_PRINCIPAL_AUTHENTICATION=NO iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
``` 

The image will be downloaded. Then running it quickly exits because no OCI configuration file is found. This does show that the image was pushed successfully to the image registry. 


### create an OKE cluster instance (using the quick start wizard and consisting of a single node)

Creating an Kubernetes cluster may sound like a daunting task. At least it always sounds somewhat intimidating to me. However, on OCI it is really the simplest of things. You run a simple wizard. The main choices you have: how many nodes (Compute Instances or VMs) should there be in the cluster (this can easily be changed later on) and what should be the shape of these VMs. After you have made that decision - or even accepted the default settings - you can leave it to the wizard to take care of the network configuration, the compute instances and the node pool formed by the instances and finally the Kubernetes cluster on top of the node pool. It takes a few minutes - and then the OKE instance is available, ready to accept deployments.

Type *ok* in the search box and click on link *Kubernetes Clusters (OKE) | Containers & Artifacts*. Then click on button *Create cluster*. 

A popup window appears with two radio buttons: *Quick create* and *Custom create*. Accept the first one - *Quick create* - and click on *Launch workflow*.

![](assets/go5-quickstart-oke.png)  

In step one of a two step wizard, select *Public Endpoint* and *Private Workers*. You can accept the shape *VM.Standard.E3.Flex* - or pick any different one. You can accept three as the number of nodes, but just one node is enough for our purposes. Click button *Next*. 

![](assets/go5-quickcreate-oke-step1.png)  

Step two provides an overview of what the wizard will do on our behalf. Time for a final inspection. If you like the proposed action, then press button *Creat cluster*.
![](assets/go5-quickcreate-oke-step2.png)  

The wizard will create all required resources - quite a bit of network configuration, creating a new compute instance and provisioning the OKE master. A progress page is shown to indicate the status of the actions. 

![](assets/go5-progress-page-oke-wizard.png)  


Once all actions are complete, you can inspect the details for the new Kubernetes cluster, the node pool, the network resources and the compute instance. The screenshot shows the details for the node pool and the node(s) in the pool. 

![](assets/go5-nodepool-for-oke.png)  

Note: the dynamic group *go-on-oci-instances* that was defined in the first article in this series was created in such a way that it includes all compute instances in the compartment. That means that if you are still working in that same compartment and the OKE cluster is also running now in that compartment that now the node in the OKE instance is member of the dynamic group and inherits all OCI IAM permissions granted to the group. Containers running in Pods on the OKE instance and scheduled on this node also inherit these privileges when they use instance principal authentication. 

### Connect to OKE instance

Interaction with a Kubernetes Cluster is typically done through the kubectl command line tool. We can use the kubectl installation included in Cloud Shell, or a local installation of kubectl. Before we can use kubectl to access a cluster, we have to specify the cluster on which to perform operations by setting up the cluster’s kubeconfig file. Note: at the time of writing, to access a cluster using kubectl in Cloud Shell, the Kubernetes API endpoint must have a public IP address – which our cluster does, thanks to the wizard setting.

In the Cluster Details window, click the Access Cluster button to display the Access Your Cluster dialog box.

![](assets/go5-accesscluster.png)  

Click Cloud Shell Access. Click on *Copy* to copy the shell statement under (2) to the clipboard. Then click *Launch Cloud Shell* to display the Cloud Shell window – if it is not yet open. Paste the shell statement into the Cloud Shell. Then press enter to execute the statement.

The config file in `$HOME/.kube` in your cloudshell environment is written (or updated if it already existed) with details for the new OKE cluster. Note that the OCI CLI understands the string PUBLIC_ENDPOINT and writes the proper Public IP Address for the cluster into the configuration file.

As long as we do not change the name or location of the config file from it default, we do not have to explicitly set the KUBECONFIG environment variable to refer to it, and we can now run kubectl to interact with my new cluster. For example to list the node(s) that make up the cluster:

```console
kubectl get nodes
```

In addition to cluster access in Cloud Shell, we probably want to have local interaction from our laptop. It should have kubectl running already, as well as OCI CLI with configuration settings that provide access to the OCI tenancy.

In the OKE Cluster Details window in OCI Console, click the *Access Cluster* button again to display the *Access Your Cluster* dialog box and click on *Local Access* this time. 

Copy the first statement (for public IP endpoint) in step 2 and execute it locally. At this point, kubectl should be set up and ready for action. The file `$HOME/.kube/config` is create or extended with an extra context. The current-context is set to this newly created one for the OKE cluster. Running


```console
kubectl get nodes
```

locally will now give the same result as in cloud shell: it lists the node(s) that make up the OKE cluster.

#### Kubernetes Dashboard

The Kubernetes Dashboard is a well known UI for monitoring and managing the Kubernetes Cluster. Many other tools are available to make life easier. However, the dashboard as a fallback option is a sort of anchor or beacon. So let’s get it running on my cluster.

The Dashboard itself is a Kubernetes application – collection of resources that needs to be created on the cluster. And for which a predefined collection of yaml files is available that can be applied with a single command:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
```

Check for example on the pods that were created in the newly created namespace *kubernetes-dashboard*:

```
kubectl -n kubernetes-dashboard get pods
```

Now you can access the dashboard in the browser, using: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=default

When GUI appears in the browser, you will be prompted for a kubeconfig file or a token. Let's create a token. First, use YAML file `oke-admin-service-account.yaml` to create a service account and the clusterrolebinding in the cluster  (as described in the [OCI Documentation for Accessing an OKE Cluster Instance](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengstartingk8sdashboard.htm)):

```
kubectl apply -f oke-admin-service-account.yaml
```

You can now generate a token to use for accessing the dashboard using this command:

```console
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep oke-admin | awk '{print $1}')
```

This will result in a token be written to the console output:

```
Name:         oke-admin-token-4dg6k
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: oke-admin
              kubernetes.io/service-account.uid: 1e68cd7b-d362-4de4-8ce8-293ff9afecb4

Type:  kubernetes.io/service-account-token

Data
====
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6InZ1WFprUDRfTjRLYWpNNTVmYmFIMkNpY24yamxhN21IUmdpdjAyZzlVUVkifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0L...Weiw-zWpS1bG9GWlSVQxTQa1fVGOqWEQRtKHt_A0YEVn1bise-R_INwKmDkNQ7nbA1jmZycUOOgAePtIFqbjtvlY6QkA2lAkCQz0-YshIc01XCT7yieymzbyxhBWedbr9bIlHZW3qRb0IeEs_taAghkLHf23S71GxIbF558UUpE9w
ca.crt:     1285 bytes
namespace:  11 bytes
```

The token is the section that starts with *eyJh* and ends with *pE9w*. Copy this value to the clipboard and paste it into the winodw that prompts for a token when you try to access the dashboard application.

### run the *message producer* application on the OKE cluster instance (manual deployment from *kubectl*, passing the OCID of the stream to publish to as environment variable)

File `person-producer-deployment.yaml` contains the specification of the Kubernetes resources that we would like to deploy on the cluster. A Deployment with a Pod based on the container image `<region key>.ocir.io/<namespace>/go-on-oci/person-producer:1.0.1` that we have pushed a little while back.

Here is the contents of the deployment specification:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: personproducer-deployment
spec:
  selector:
    matchLabels:
      app: personproducer
  replicas: 1
  template:
    metadata:
      labels:
        app: personproducer
    spec:
      containers:
      - name: personproducer
    # enter the path to your image, be sure to include the correct region prefix    
        image: iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
        env:
        - name: INSTANCE_PRINCIPAL_AUTHENTICATION
          value: "YES"
        - name: STREAM_DETAILS_SECRET_OCID
          value: "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caa6m5tuweeu3lbz22lf37y2dsbdojnhz2owmgvqgwwnvka"
      imagePullSecrets:
    # enter the name of the secret you created  
      - name: ocirsecret
```

You need to update the value for the *env* key *STREAM_DETAILS_SECRET_OCID* - to the value that applies in your environment. You also need to update the *image* to correspond exactly with the image as you pushed to the OCI Container Image Registry.

The OKE Cluster cannot just start pulling container images from the registry. It need to use proper authentication details to login to the registry. These details are represented in this deployment specification by the secret *ocirsecret*. However, that secret does not exist yet on the OKE cluster. To create it, execute the following command in kubectl:

```
kubectl create secret docker-registry <secret-name> --docker-server=<region-key>.ocir.io --docker-username='<tenancy-namespace>/<oci-username>' --docker-password='<oci-auth-token>' --docker-email='<email-address>'
```

This create a secret in Kubernetes that can be used when needed to pull container images. For me, the command resolved to something like:

```
kubectl create secret docker-registry ocirsecret --docker-server=iad.ocir.io --docker-username='idtwlqf2hanz/jellema@chimney.nl' --docker-password='y&aya1PCjJFW8xk1.7o' --docker-email='jellema@chimney.nl'
```

After creating the secret, you can apply the deployment specification using kubectl, creating the deployment and the pod and pulling the image to run the container:

```
kubectl apply -f person-producer-deployment.yaml
``` 

The somewhat understated output from this action reads: 

```
deployment.apps/personproducer-deployment created
```

That means that the Pod is starting, the container image is being pulled and the application will soon run and start publishing messages. You can check the logs from the Pod, for example in the Kubernetes Dashboard. You can also verify in the OCI Console if the expected messages arrive on the stream. You can even run application `applications/from-stream-to-database` and see if new database records get created.

Note: if the logging reveals problems for the application with permissions on OCI resources - specifically retrieving the secret with stream details or producing messages to the stream itself, you may need to check if policy statements have been defined for dynamic group `go-on-oci-instances` to allow all compute instances - including the node of the OKE cluster and by extension any application running in a container on this VM to read secrets and work with streams in the compartment:

```
allow dynamic-group go-on-oci-instances to read secret-family in compartment go-on-oci 

allow dynamic-group go-on-oci-instances to manage streams in compartment go-on-oci
```


### Create and Run OCI DevOps Deployment Pipeline to publish the Application to the OKE cluster

A Deployment Pipeline will take a Kubernetes manifest that manipulates K8S resources - for example for creating a Pod or a Deployment - and apply it to a designated OKE cluster. The manifest contains a reference to a container image - probably in the OCI Container Image Registry but possibly in a public or other private registry. The manifest can contain placeholders defined as `${parameterName}`. These are replaced when the pipeline is executed by the values supplied for these parameters. The pipeline can for example be used to deploy specific, varying versions of images and also to set values in the manifest that translate to environment variables inside the container. In this example, the value for *STREAM_DETAILS_SECRET_OCID* is provided by a pipeline parameter. This value is replaced before the deployment starts in the manifest and that value is available as environment variable to be read by the *person-producer* application. 
#### Create Inline Artifact with Kubernetes Manifest for creating Deployment

Create an artifact in the DevOps Project called *person-producer-deployment-yaml* of type *Kubernetes manifest* and with *Artifact source* set to: *inline*. Then paste this Kubernetes manifest definition for creating a deployment based on a container image:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: personproducer-deployment
spec:
  selector:
    matchLabels:
      app: personproducer
  replicas: 1
  template:
    metadata:
      labels:
        app: personproducer
    spec:
      containers:
      - name: personproducer
    # enter the path to your image, be sure to include the correct region prefix    
        image: iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:${imageVersion}
        env:
        - name: STREAM_DETAILS_SECRET_OCID
          value: ${STREAM_DETAILS_SECRET_OCID}
      imagePullSecrets:
    # enter the name of the secret you created  
      - name: ocirsecret

```

Note: you have to replace part of the image name to make it fit your environment: `iad.ocir.io/idtwlqf2hanz/go-on-oci/` => `<region key>/<namespace>/<repository prefix>`.

![](assets/go5-define-artifact-k8s-deployment.png)  

Also note that the manifest contains two placeholders: ${STREAM_DETAILS_SECRET_OCID} and ${imageVersion}. These are to be replace when the artifact is used in a deployment, with values from parameters set at deployment time. Make sure to set field *Replace parameters used in this artifact* to *Yes, substitute placeholders*.

Click on button *Save*.

#### Define a DevOps Environment for the OKE Cluster

Define an environment in the DevOps Project. Pick *Oracle Kubernetes Engine* as the type. Set the name to *go-on-oci-oke*. Click button *Next*. Select the cluster instance that you created earlier on. Then click button *Create environment*.

![](assets/go5-create-environment-for-oke.png)  

#### Define a Deployment Pipeline

Create a new Deployment Pipeline in the DevOps Project. Set the name to *deploy-person-producer-to-oke*. Add a stage of type *Apply manifest to your Kubernetes cluster*. Press *Next* to define details. Call the stage  *apply-person-producer-deployment*. Select environment *go-on-oci-oke*. Select artifact *person-producer-deployment-yaml* as an artifact to apply. Multiple *Kubernetes manifest* artifacts can be included in this stage.

You can accept or change the Kubernetes namespace. Press *Save* to create the stage.

![](assets/go5-define-deployment-pipeline-oke.png)  

Now define two Pipeline Parameters. One is called *STREAM_DETAILS_SECRET_OCID* - and its default value should be the OCID of the secret that contains the Stream details (message endpoint and stream OCID). The second parameter is called *imageVersion*. Its default value can be *1.0.1*. This parameter determines the version of the container image *person-producer* to get from the image registry and deploy onto the OKE cluster. 

![](assets/go5-deployment-pipeline-parameters.png)  

#### Run the Deployment Pipeline to Deploy Person-Producer on OKE Cluster

The pipeline is ready to be run. You can kick it off, provide overrides for the parameters - but these are probably not needed - and have the Deployment created on Kubernetes. Of course the effect of running the pipeline is most impressive if before running you have removed the Pod and Deployment for person-producer from the OKE cluster. If it then makes a reappearance, you know it is the pipeline that did it.

![](assets/go5-run-deployment-pipeline1.png)  

The output from running the pipeline is reassuring - green checkmarks:
![](assets/go5-running-deployment-pipeline-output.png)  

Check on the Stream to find new messages being published, or check in the Kubernetes Dashboard on the state of the Deployment and the Pod. Or simply check in `kubectl` with `kubectl get pods` to find a very recently kicked off Pod for `personproducer-deployment`.

### create an OCI DevOps build pipeline to build the *message producer* container image from the source code repository, publish the image to the container image registry and trigger the deployment pipeline

As a final step we create DevOps Build Pipeline that builds the Container Image for the `person-producer` application from the Go sources in the code repository and triggers the deployment pipeline. That means that with committing a code change, we can run a pipeline that takes care of the end to end redeployment on the Kubernetes cluster of the changed application code. 

The steps are straightforward:
* create the build pipeline 
* add managed build stage - that builds and tags the container image locally (on the build server)
* add a stage to publish the freshly built image to the container image registry
* add a final stage to trigger the deployment pipeline *deploy-person-producer-to-oke*
* make a change to the application source code, commit the change to the code repository and trigger the build pipeline; wait for a few minutes and inspect the Stream for messages that carry the change made in the source code of the application


## Conclusion

This article demonstrated how a Go application through the Go SDK for OCI can easily publish messages to OCI Streaming topics as well as consume such messages. The Go application that publishes or consumes can run on OCI or outside of it. Management of credentials and other secrets is ideally done using OCI Key Vault. This article introduced Key Vault and showed how it can be used from Go applications. Finally, a third type of application runtime platform was introduced that exists next to VM and serverless function: the managed OCI Kubernetes Engine (OKE). OCI DevOps Deployment Pipelines can deploy our Go applications to OKE in an automated way, once a Build Pipeline has created a container image for the application.  

The five articles that make up the series "Way to Go on OCI" have provided Go developers (*Gophers*) with a overview of how OCI provides a valuable platform both for engineering and running Go based applications as well as for leveraging relevant platform services from Go applications. The series demonstrates automated build and deployment of Go applications as stand alone executables on Compute Instances, as serverless functions and as containers on a Kubernetes cluster. Throughout the articles, introductions are given of these OCI services used from Go applications: Object Storage, Functions, API Gateway, Autonomous Database, Streaming and Key Vault. Additional, platform services used for engineering and operations were discussed, including DevOps Build and Deployment Pipelines, Code Repositories, Artifact Registry, Container Image Registry, IAM and Logging.

## Resources

[Source code repository for the sources discussed in this article series](https://github.com/lucasjellema/go-on-oci-article-sources) 

[Oracle Cloud Infrastructure Blog - Automating a pod identity solution with Oracle Container Engine for Kubernetes (OKE) - by Ed Shnekendorf](https://blogs.oracle.com/cloud-infrastructure/post/automating-a-pod-identity-solution-with-oracle-container-engine-for-kubernetes-oke) - this article describes the use of instance principals for the nodes (OCI Compute Instances) in the OKE cluster to provide permissions for the Pods running on the node to access OCI services]

[Oracle Functions - Connecting To An ATP Database With A Wallet Stored As Secrets - article by Todd Sharp on retrieving Oracle Wallet from OCI Vault from Functions](https://blogs.oracle.com/developers/post/oracle-functions-connecting-to-an-atp-database-with-a-wallet-stored-as-secrets)

[Protect Your Sensitive Data With Secrets In The Oracle Cloud - article by Todd Sharp on use of OCI Vault](https://blogs.oracle.com/developers/post/protect-your-sensitive-data-with-secrets-in-the-oracle-cloud)

[OCI Streaming — create producer/consumer use case using ATP, OIC and Kafka connect](https://medium.com/oracledevs/oci-streaming-create-producer-consumer-use-case-using-atp-oic-and-kafka-connect-e5be254edea3)

[Oracle Cloud Streaming Service – Scalable, Reliable, Kafka-like Event service on OCI](https://technology.amis.nl/oracle-cloud/oracle-cloud-streaming-service-scalable-reliable-kafka-like-event-service-on-oci/)

[SDK for Go Streaming Quickstart](https://docs.oracle.com/en-us/iaas/Content/Streaming/Tasks/streaming-quickstart-oci-sdk-for-go.htm#go-sdk-streaming-quickstart)

[Getting started (again) with Kubernetes on Oracle Cloud](https://technology.amis.nl/cloud/getting-started-again-with-kubernetes-on-oracle-cloud/)

[Compiling Your Go Application for Containers](https://medium.com/pragmatic-programmers/compiling-your-go-application-for-co-ntainers-b513190471aa)