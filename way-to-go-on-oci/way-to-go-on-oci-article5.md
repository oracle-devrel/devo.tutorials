---
title: Hooking Go applications into OCI Streaming, using OCI Key Vault and Go Deployment on OKE
parent:
- tutorials
- way-to-go-on-oci
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
author: lucas-jellema
xredirect: /tutorials/way-to-go-on-oci/go-on-oci-streaming-vault-oke-article-5
---
{% imgx alignright assets/landing-zone.png 400 400 "OCLOUD landing zone" %}

[OCI Event Streaming Service]: https://technology.amis.nl/oracle-cloud/oracle-cloud-streaming-service-scalable-reliable-kafka-like-event-service-on-oci/

[OCI Documentation for Accessing an OKE Cluster Instance]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengstartingk8sdashboard.htm

Welcome! This is the fifth and final part of a five-part series about *Go and Oracle Cloud Infrastructure.* The series discusses how Go applications can be created and run on Oracle Cloud Infrastructure, either in Compute Instances (VMs) containerized on Kubernetes, or as serverless Functions. From start to finish, we'll walk you through the process of automating the building and deployment of these Go applications using OCI DevOps.  

A particular focus will be on showing you how to use Oracle Cloud Infrastructure (OCI) services from Go applications, both those running on OCI as well as those running Go code elsewhere. Throughout this series, we'll discuss various OCI services, including Object Storage, Streaming, Key Vault, and Autonomous Database.

Just like it says on the tin, the ultimate goal of this series is to make sure that you have everything you need to get Going on OCI!

## Prerequisites

In order to follow along with these articles, you should at least have a basic understanding of how to create Go applications. We'll also assume that you have access to your own Go development environment. And while some of the examples and screenshots specifically mention VS Code as a development tool, don't worry, you're perfectly fine using any other editors and IDEs you feel more comfortable with.

### Examples

To work with the examples presented throughout the series, you'll also need to have access to an OCI tenancy with permissions to create the OCI resources discussed in these articles. Fortunately, most of the resources used are either available to you in the *Always Free Tier* (Compute Instance, VCN, Autonomous Database, Object Storage, Logging, Resource Manager) or have a free allotment tier for limited monthly usage (Functions, API Gateway, Streaming, Vault, DevOps).

### Worth mentioning

For the sake of clarity, we've done our best to present mechanisms in their simplest form and with the least amount of dependencies. While this allows us to demonstrate some of the diverse ways in which you can use Go on OCI, it also means that you shouldn't expect meaningful functionality or production ready code. Just the right amount to get you going!

## Introduction

The first part of this series begins by describing how you can provision a Compute Instance based on the Oracle Linux Cloud Developer image and then open it up for both inbound and outbound network activity. It goes on to show you how to create and run a Go application that serves HTTP requests, and later how to connect it to OCI Logging.

Part two deals with software engineering and demonstrates how you can use the OCI DevOps service to automate the build and deployment of your application. It illustrates how the OCI DevOps services is used for storing the Go source code, building the application executable, and then storing it as an artifact which can deployed to a Compute Instance. The article wraps up by showing you how to expose an HTTP endpoint for the application through an OCI API Gateway.

Part three shows you how to create serverless functions in Go and then deploy them on OCI. Next, you're introduced to the Go SDK for OCI, first for local, stand-alone Go applications and subsequently for use from functions. In each case, resource principal authentication is leveraged. The key takeaway here is that the SDK is used to interact with the OCI Object Storage service for both creating buckets and reading/writing files.

The fourth article discusses the interaction between your Go application and an Oracle Database. This database can be a local, on-premises one, one running on a cloud vendor's IaaS instance, or an instance of an Oracle Cloud Infrastructure Autonomous Database.

This fifth and final article in this series introduces two more OCI services for your Go applications to interact with: OCI Streaming (a high-volume streaming message broker that allows for decoupled interactions between different microservices and other components) and the OCI Key Vault for managing secrets, such as Oracle Wallet with database credentials. This article also introduces a third type of application platform (beyond the VM and serverless function covered in part one) in the form of the managed OCI Kubernetes Engine (OKE). It also shows you how DevOps Deployment Pipelines can deploy your Go applications to OKE in an automated way.

## Publishing Messages from Go application to OCI Streaming

In this scenario, we'll work with the [OCI Event Streaming Service], a managed Pub/Sub message broker service similar to Apache Kafka. In this service, events are published to Streams (aka *Topics*) and can be consumed from those Streams, either by one or multiple consumers. Consumption can be managed in several different ways to provide content that's most relevant to you: starting at a specific time or after a specific offset, opening up to include as many events as are available, or narrowing to only the newest.  
>**NOTE:**  It's important to keep in mind that consumers have to actively come to the service to collect messages; there's no push mechanism that will notify listeners whenever new messages have been published to the Stream. However, there's an upside to this approach and it's what helps distinguish the Event Streaming Service from others. Here, there's no need for a dedicated subscription. All a consumer has to do is create a *cursor* (similar to a session or a [long running] query) and start pulling messages within the context of that cursor.  
{:.alert}

As for the Streams themselves:  

* They can be used for messaging, ingesting high-volume data such as application logs, operational telemetry, web click-stream data, or other use cases in which data is produced and processed continually and sequentially in a publish-subscribe messaging model.
* Messages are retained for up to 7 days.
* While there are limits on how much data they can handle per second, in practical terms these limits are actually fairly high (1MB per partition per second, 1MB maximum message size, five consume calls per second).

With that in mind, let's take a look at what'll be covering in this next section. We'll first create a Stream (aka *Topic*), try it out in the OCI console, and then create a local Go application that can publish messages to the Stream (once again using the Go SDK for OCI).

### Create a Stream

Even with everything they can do, creating a Stream in the Console is remarkably easy, as is *Producing a Test Message* and *Consuming the Test Messages*. In fact, you can get going in 3 minutes or less!

Let's look at how to set this up.

1. In the OCI Console search field, enter **str** and then select **Streaming | Messaging**.

1. Select **Create Stream**.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-create-stream0.png 1200 334 "Create a new Stream" %}  

   Provide some details on the stream:

   * its name (e.g., *go-on-oci-stream*)  
   * the number of partitions (leave at one)
   * the retention time (24 hours should be fine for our purposes)

   >**NOTE:** Leave the radio button selected for *Auto-Create a Default Stream Pool*.
   {:.alert}

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-create-stream1.png 1200 555 "Provide details for the new Stream go-on-oci-stream" %}  

1. Select **Create Stream**.
   At this point, the Stream will be created and should take only a few seconds to complete.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-streamcreated.png 1200 774 "The new stream is ready for accepting messages" %}  

### Try out the new Stream

Once the Stream has been created and is active:

1. Select **Produce Test Message**.  
1. Enter a message and select **Produce**.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-producemessage.png 1097 591 "Publish a simple first test message on the new stream" %}

   The console will indicate that the message was produced successfully.  

1. Select the **Cancel** link to close the popup window.

1. Select **Load Messages**.  
   All recently published messages (within the last 60 seconds) on the Stream are displayed. You should see the test message that you just published.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-loadmessages.png 922 224 "Inspect the last 60 seconds worth' of messages on the stream" %}  

### Go Message Producer

#### Go client

The file, `producer.go` is a Go client for a Stream on OCI. It is located within `applications/message-producer` in the source code repository of this article series. This file assumes a local `$HOME/.oci/config` file that provides details for connecting to OCI as a user with permissions on the stream. When the client is first launched, `StreamClient` is initialized and the function **PutMessages** is invoked with a request targeted at the `streamOCID` for the new stream that contains two messages.

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

#### Running the client

Before you're able to run `producer.go`, you'll first need to:

1. Set the appropriate values for `streamOCID` and `streamMessagesEndpoint`.
2. In the directory that contains `producer.go`, run `go mod tidy` on the command line.

With that set, you're all ready to run the client.

1. Execute `go run producer.go`.
1. Use the OCI Streaming console to inspect the arrival of messages and select **Load Messages**.  
   In the console, you'll see the messages produced by the Go application. At this point, feel free to change the content/number of messages produced, or run the producer again and check again for the messages in the console.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-messages-published-by-producer.png 962 573 "Messages published to stream by the producer application" %}  

### Consume Messages from a Stream in a Go application

Really, a Stream isn't much use to us if we're just able to send messages to it. In order for the process to be really useful, messages need to be *consumed* before they expire.

The next application that we'll discuss does exactly this. You can find it in the `applications\message-consumer` directory of the source code repository.  

So, how does it work its magic? First, it creates a client for OCI Streaming using the Go SDK for OCI from Go code. Then it makes a *cursor request*. A *cursor* is pointer to a location in a stream and represents a specific consumer. The application uses the cursor to make requests for messages. If more messages are available on the stream beyond the current cursor's offset, then the next batch of messages is delivered (and the offset is moved). When all messages have been retrieved through the cursor, the request will result in a response without any messages. From there, the client can continue polling (with) the cursor for new messages on the stream.  

### Running the application

First, run `go mod tidy` at the command line. Then, run this application using `go run consumer.go`.  

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

**Sample output:**
Depending on what messages have been produced to the topic (and are still retained), the output will look similar to:

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

### Types

Multiple values for *Type* can be defined to specify where the cursor should start fetching message from the Stream:

* `AFTER_OFFSET:` The partition position immediately following the offset you specify. (Offsets are assigned when you successfully append a message to a partition in a stream.)
* `AT_OFFSET:` The exact partition position indicated by the offset you specify.
* `AT_TIME:` A specific point in time.
* `LATEST:` The most recent message in the partition that was added after the cursor was created.
* `TRIM_HORIZON:` The oldest message in the partition that is within the retention period window.

>**NOTE:** When `AFTER_OFFSET` or `AT_OFFSET` are defined, the value for offset **must** be provided. When `AT_TIME` is set as type, a value for time is mandatory.
{:.warn}

**Example -** Where message retrieval should start after offset 5:

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

#### Consumer groups

Effectively, each consumer is represented by an active cursor. This means that instead of explicitly defining individual, isolated cursors that link up with a specific partition, we can use the concept of *consumer groups* and leave it to the Streaming Service to associate partitions with specific consumers. In that case, the body of function `main` becomes:

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

It is common for applications to use configuration settings as part of their operation. These settings can help determine part of the behavior of the application, instructing it on how to deal with endpoints, file system locations, or credentials for making connections. Not unsurprisingly, configuration settings can also be environment dependent. For instance, the same application in a test environment uses different values than it would in the production environment. And as you might imagine, some of the configuration settings are sensitive, such as passwords or private keys.

So far, the Go applications discussed in this series haven't worked explicitly with configuration settings. For example purposes, some applications contain hard-coded references to compartment, bucket, and stream, or are committed to the code repository with a database wallet and hard-coded database connection details. This certainly isn't ideal, and in practice you'll want to avoid doing the same for your own applications.

### Vaults

From this point on, we'll improve our way of working and use OCI Vault instead. The Vault service on OCI lets you create vaults in your tenancy as containers for encryption keys and secrets. Vaults are logical entities where the Vault service creates and durably stores keys and secrets. The type of vault you choose  determines features and functionality such as degrees of storage isolation, access to management and encryption, and scalability.  

If needed, a *virtual private vault* provides you with a dedicated partition in a *hardware security module* (HSM), offering a level of storage isolation for encryption keys that’s effectively equivalent to a virtual independent HSM. Keys are stored on highly available and durable HSMs that meet Federal Information Processing Standards (FIPS) 140-2 Security Level 3 security certification. The Vault service uses the Advanced Encryption Standard (AES) as its encryption algorithm and uses AES symmetric keys. Note that the virtual private vault is a paid service whereas the default vault is always free.

Keys are logical entities that represent one or more key versions that contain the cryptographic material used to encrypt and decrypt data, protecting the data where it's stored. When processed as part of an encryption algorithm, a key specifies how to transform plaintext into ciphertext during encryption and how to transform ciphertext into plaintext during decryption. Plain text in this sense can either be a base64 representation of binary content or a JSON document that contain many configuration settings in a single key.

Vaults are first and foremost associated with secrets that contain sensitive information. However, even information that may not be very sensitive can be stored in a key. This means that an application can use keys as configuration settings during deployment or at runtime to help define the environment-specific settings and behavior. And a reference to the Vault Secret is all that the application needs to retrieve the *secret* that provides the required settings. What this means is that secrets can now be managed independently from an application. You can avoid using hard coding that runs contrary to standard best practices and makes it impossible to use a single code base for all environments.
>**NOTE:** It's important to keep in mind that when the value of secret changes and you want the application to start using the new values, you have to make sure to reinitialize the application using the changed values.
{:.alert}

### Create an OCI Vault

In this section, we'll create a Vault and a simple secret that we can read from a Go application. Next, we'll create a secret that contains an Oracle Wallet and then a second secret through a JSON document that contains additional database connection details. Using this secret, we can create an application that works with an Oracle Database and which learns at runtime how to connect to the database when it accesses the secret. All you need to connect to a different database is change the secret and then restart the application. That's it!

Let's create the vault.

1. In the OCI console, enter **vau** in the search field and then select the link **Vault | Identity & Security**.  
   The overview page with all of vaults in the current compartment is shown, most likely without any entries.

2. Select **Create Vault** and in the **Create Vault** form enter the name for the new vault: **go-on-oci-vault**.  
   The new vault doesn't have to be a *Virtual Private Vault*, so leave the checkbox unchecked.  

3. Select the **Create Vault** button to create the vault.
   {% imgx aligncenter assets/way-to-go-on-oci-article-5-createvault.png 1200 370 "Create a Vault" %}  

   A list of vaults is returned. This time though, it'll contain your new vault with the status *creating*.  
   >**NOTE:** It can take up to one minute or so for the vault to be initialized.
   {:.notice}

4. When the new vault's status is *Active*, select the name of your new vault and then navigate to its details page.  
5. Create the *master encryption key* for the vault.  We'll need to do this before we can start creating secrets in it.  
   1. Enter the name for the master key (e.g., *go-on-oci-vault-master-key*).
   2. Accept all default values.
   3. Select **Create Key**.  
      It'll take a little time for this new master key to be produced.

      {% imgx aligncenter assets/way-to-go-on-oci-article-5-createmasterkey.png 1200 564 "Generate a master key to use for encrypting secrets for the vault" %}  

### Create a Secret

We now have a vault and a master key to encrypt any secrets we'll want to store. At this point, we're ready to define secrets in the vault.  

Let's start with a very simple one.

1. Select the link for the **Secrets** and select **Create Secret**.  
   A page is presented where a new secret can be created.

1. Enter the name for the secret (e.g., *greeting-of-the-day*.)
1. Select the master key we set up for the vault in the previous section and leave the selection list **Secret Type Template** at *Plain Text*.  
1. Enter the value of the secret greeting.  
   (e.g., *Have a wonderful day!*)
1. Select **Create Secret** to save the new secret to the store.  
   This is the start of what's commonly referred to as a *secret bundle*. A secret bundle consists of the secret contents, properties of the secret and secret version (such as version number or rotation state), and user-provided contextual metadata for the secret. When you rotate a secret, you provide new secret contents to the Vault service to generate a new secret version. The complete version history of all values that have been assigned to the secret will be retained.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-createsecretgreeting.png 1200 564 "Create a secret to be encrypted and held within the vault" %}  

### Read Secret from Go application

The secret that you just defined is now required in our Go application. Let's see how we can use the application to access the values of secrets.  

Probably the most straightforward example of how to retrieve a secret from an OCI Vault from Go lives in the file `secret-reader.go` (located in `applications/secret-reader` of the source code repository). It uses the Go SDK for OCI and the only piece of information it really needs (outside of the `$HOME/.oci/config` file) is the OCID for the secret to be retrieved.  
>**NOTE:** The assumption here is that whichever user's credentials are defined in the config file also has read permissions for the secret.
{:.alert}

In the code below, make sure to replace `secretOCID` with the appropriate OCID value.

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
 secretOCID = "<OCID of the Secret to be Read from a Vault>"
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

#### Run the application

To run the application, execute `go run secret-reader.go` at the command line.  This should echo the content of the secret that you just created to the command line.

To see the effect of managing configuration settings separate from the application source code, update the secret in the OCI Console and run the application again. You should now see the changed content since the application will always retrieve the latest version of the secret.  

So, let's review. Not only does the code not contain the highly sensitive value of the secret, it also remains unchanged until the application has been restarted.  

In a broader context, refreshing updated values of configuration settings in live applications is an interesting and relevant topic, but one we'll leave for another moment.  

In the next section, we'll explore how to create secrets that actually contain sensitive information.

### Store Oracle Database connection details and Wallet in Vault

In the [previous article](way-to-go-on-oci-article4.md), details about the database connection and the Oracle Wallet Information were hard coded into our source code and left completely exposed in our repository. In a real environment, that would be inexcusable.  

The proper way to handle such sensitive data would be using a vault. When an application runs it knows it has to connect to a database, but unless we tell it, it doesn't know where that database is or which credentials it needs to connect with. That particular information can be retrieved from the vault provided that:

* we use the secret identifiers
* the application is running as a user or on a host that has permissions for reading the content of these secrets.

#### Create secret

Storing the database connection details (e.g., the `autonomousDB` *struct* in the file *data-service.go* in application *data-service* discussed in the previous article) in a secret isn't difficult at all.  

1. Create a JSON-formatted string from the data in the struct:

   ```json
   { "service":        "k8j2fvxbaujdcfy_goonocidb_medium.adb.oraclecloud.com",
     "username":       "demo",
     "server":         "adb.us-ashburn-1.oraclecloud.com",
     "port":           "1522",
     "password":       "thePassword1"
   }
   ```

1. Navigate to the vault page for *go-on-oc-vault* in the OCI console.  
1. In the **Secrets** tab, select **Create Secret** and enter the name for the secret: *autonomousDB-demo-credentials*.  
1. Select the **master encryption key**.
1. In the **Secret Contents** area, copy and paste the JSON content containing the database connection details from step 1 above.  
   >**NOTE:** Make sure to keep the type template on *Plain-Text*.
   {:.alert}
1. Select **Create Secret**.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-create-secret-autonomousdb-credentials.png 1200 697 "Create a Secret with a JSON string with database credentials" %}  

#### Define type

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

#### Decode secret

Now, create code that decrypts content from the secret and stores it in a variable based on this type:

```go
    secretReq := secrets.GetSecretBundleRequest{SecretId: common.String(secretOCID)}
 secretResponse, _ := secretsClient.GetSecretBundle(context.Background(), secretReq)
 contentDetails := secretResponse.SecretBundleContent.(secrets.Base64SecretBundleContentDetails)
    decodedSecretContents, _ := b64.StdEncoding.DecodeString(*contentDetails.Content)
 var dbCredentials DatabaseConnectDetails
    json.Unmarshal(decodedSecretContents, &dbCredentials)
 fmt.Println("database connect details for user: " + dbCredentials.Username)
```

#### Store the wallet file

Next, we need to also store the wallet file *cwallet.sso* in a secret. Since this file contains binary content, we'll first need to convert it into a string representation before we can store this information as a secret. All we need to do is encode the content in base64.  

We can easily do this on the Linux command line by running:

```console
base64 -i cwallet.sso > cwallet-sso-base64.txt
```

The resulting file, `cwallet-sso-base64.txt` contains the content we want to use for the secret.  

Now that we have the content in the proper format, let's save the wallet file.

1. From the vault page for *go-on-oc-vault* in the OCI console navigate to the **Secrets** tab and select **Create Secret**.  
1. Enter the name for the secret: *autonomousDB-cwallet-sso*.
1. Select the **master encryption key** and paste the base64 content with database wallet details into the *Secret Contents*.
   >**Note:** Make sure to keep the type template set on *Base64*.
   {:.notice}
1. Select **Create Secret**.  

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-createsecret-for-cwallet.png 1200 648 "Create a secret to hold the base64 encoded contents of the database wallet" %}  

#### Retrieve the wallet file

The contents of this secret can be retrieved from the Go code in the same way as before. However, this time the application needs to write a local `cwallet.sso` file with the contents from the secret:

```go
 decodedSecretContents, _ := b64.StdEncoding.DecodeString(*contentDetails.Content)
 _ = os.WriteFile("./cwallet.sso", decodedSecretContents, 0644)
```

This allows the application, using only the OCID values for the two secrets (the database connection details and the database wallet file), to initiate communications with the database it needs to use in its current environment. Just as we promised, nothing hard coded, nothing exposed!

### Connecting a Go application to an Oracle Database using Secrets from Vault

The code for a simple Oracle Database client can be found in the application Directory (`applications/safe-database-client`) of this article's source-code repository. If you've been following along with the series, the client code is very similar to what we discussed in article four's `applications/go-orcl-db`. The main difference here is that this application contains neither a wallet file nor any database connection details. And at this point, you can probably see where this is all going. What the database client does require are references to two OCI Secrets. The first OCID refers to the secret with connection details (in JSON string format) while the second OCID refers to the secret that contains the base64-encoded representation of the `cwallet.sso` file.  

#### Provide the OCIDs

In order to run the `oracle-database-client-app.go` application, you'll need to provide the values for those two OCID references we just mentioned.  These references are contained in the variables: `autonomousDatabaseConnectDetailsSecretOCID` (connection details) and `autonomousDatabaseCwalletSsoSecretOCID` (wallet file).

```go
const (
 autonomousDatabaseConnectDetailsSecretOCID = "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caabn37hbdsu7dczk6wpxvr7euq7j5fmti2zkjcpwzlmowq"
 autonomousDatabaseCwalletSsoSecretOCID     = "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caazzhfhfsy2v6tqpr3velezxm4r7ld5alifmggjv3le2cq"
)
```

With these values, the application will be able to retrieve the two secrets from the vault. Once retrieved, the wallet file `cwallet.sso` is written to the local directory, and the other is used to construct an instance of type `DatabaseConnectDetails` that contains login details for the database (username, password, host, port, and service). At this point, the application has all the information it needs to establish a connection to the database. This connection process is the same as the one used by `godror-based-oracle-database-client.go`.

#### Run the database client

You can run the application on the command line with:

```console
go run *.go  
```

The client will connect to the Autonomous Database and perform some small SQL feats. The nice thing about this example is that the application doesn't require any information whatsoever about the database it's going to interact with.

>**NOTE:** In order to run an application on OCI that needs to read secrets from an OCI Vault, you'll need to make sure that the following policy applies to the host that runs the code (using either **Resource Principal** or **Instance Principal** authentication):
>
>```console
>allow dynamic-group my-secret-group to read secret-family in compartment go-on=oci where target.secret.name = 'my-secret'
>```
>
{:.alert}

## From Streaming Messages to new Database Records

So far, we've been working in separate components to achieve what we needed. But, we're really at the point where we can pull everything together into a single application that doesn't require any configuration (except for some OCID values for secrets in the OCI vault).

So what should this application be able to do? It will need to subscribe to a Stream in OCI, poll and consume messages, and create records in an Autonomous Database on OCI for every message received from the Stream.

Such an application can be visualized in the following image:

{% imgx aligncenter assets/way-to-go-on-oci-article-5-endtoend-readsecrets-consumemessages-createdbrecords.png 1077 657 "Application from Stream to Database - read secret to get details for consuming from Stream and to connect to Autonomous Database" %}  

### Code repository

All of the code you'll need for this application resides in the directory, `applications/from-stream-to-database`. The files should be to familiar to you by now:

* `consumer.go` retrieves the secret with details for subscribing to the stream.  
* `oracle-database-client-app.go` does the same thing for the database connection details.  
  This file also exposes the function `PersistPerson` that can be invoked with an instance of type `Person` and subsequently turned into a new database record.  
  Remember to make same changes in `oracle-database-client-app` as in the previous section. You'll need add the OCID values for both the database connection details and the database wallet secrets.

### Creating a secret in the OCI Vault

Next, you'll need to create a secret in the OCI vault.  

The secret will contain the stream details in a JSON string similar to the following:

 ```json
 {
  "streamMessagesEndpoint" : "https://cell-1.streaming.us-ashburn-1.oci.oraclecloud.com" ,
  "streamOCID"             : "ocid1.stream.oc1.iad.amaaaaaa6sde7caa56brreqvzptc37wytom7pjk7vx3qaflagk2t3syvk67q"
 }
 ```

 >**NOTE:** Make sure to set the values that apply to your environment.
 {:.alert}

1. **Name the secret -** For the purposes of this example, you can call the secret *stream-connection-details*.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-secret-stream-connection-details.png 1200 523 "JSON content for secret with Stream connection details" %}  

1. **Use the OCID for this new secret to set the value for `const streamDetailsSecretOCID` -** You will need to set the value in the file `consumer.go`, located in `applications/from-stream-to-database/consumer.go`.  
   The `main` function in this file subscribes to the stream and starts a series of iterations in which it polls the stream for new messages. Whenever a message is consumed, this function holds details for a person in a valid JSON message. This message is decoded into a Person instance and then subsequently passed on to `PersistPerson`.

1. **Publish messages to the stream in the OCI Console**  
   1. Navigate to the page for the stream in the console.  
   2. Select **Produce Test Message** and enter a valid JSON message with Person details that looks similar to the following:

      ```json
      {
       "name" : "John Doe",
       "age" : 34,
       "comment" : "Nice chap, good looking; not too bright"
      }
      ```

   3. Select **Produce** to publish the message on the topic and make it available for processing by the consumer.

      {% imgx aligncenter assets/way-to-go-on-oci-article-5-producepersontestmessage.png 1113 711 "Produce a test person mesage on the Stream" %}  

   There's no real need to worry, so feel free to publish the message multiple times. It won't result in multiple database records since the name is used as identifier. The only difference you're likely to see will be in the logging of the application. Of course, if you make changes in the name between the messages, no matter how small, you'll wind up with a lot of additional records in the database.

>**NOTE:** The code is not very robust. It will likely choke on messages with a different format, so make sure you stay consistent with what's been presented.
{:.warn}

## Deploy Person Producer on OKE

So far, we've discussed several runtime platforms for our Go applications on OCI. However, there's still one we've yet to talk about: Kubernetes. Or, more specifically, Oracle Container Engine for Kubernetes (OKE).  

Over the course of the series, we've taken our executable (compiled from the Go source code), deployed it on a compute instance, and then converted the source code into a serverless function. In order to begin our exploration of Kubernetes, we'll containerize a standalone application and deploy it on an OKE cluster instance in this final section of the article.

There'll be a lot of ground to cover, so let's review the steps ahead of us:

* build and run the enhanced *Person Producer* application locally
* create a lightweight container image for the *Person Producer* application
* run a local container to prove that the image is complete and correct
* push the container image to the OCI Container Image Registry
* **(optional)** in order to ascertain that the images were all pushed correctly to the image registry, pull the container image from the registry and run it in one of the following: the Cloud Shell, on the *go-app-vm* compute instance, or in some other environment
* create an OKE cluster instance (using the quick start wizard and consisting of a single node)
* run the *Person Producer* application on the OKE cluster instance (manually deploying from *kubectl and passing the OCID of the publication stream as an environment variable)
* create an OCI DevOps deployment pipeline to publish the *Person Producer* container image to the OKE cluster instance; run the pipeline
* create an OCI DevOps build pipeline to build the *Person Producer* from the source code repository, publish the image to the container image registry, and trigger the deployment pipeline

When it all comes together, the end result can be visualized as:

{% imgx aligncenter assets/way-to-go-on-oci-article-5-visualization-personproducer-dev-build-depl.png 1200 758 "End to end visualization of Person Producer - from local development via Code Repository, Build and Deployment Pipelines to OKE Cluster" %}  

### Build and Run the Person Producer Application locally

The Go application that publishes person messages to the Stream on OCID can be found in directory, `applications/person-message-producer`, in the source code repository for this article series. The code for the message producer is in file, `person-producer.go`.

#### Set up the message producer application

The code needs to have an environment variable set that indicates which secret in the OCI vault contains the stream details. If you recall, that secret was defined earlier in this article as *stream-connection-details*.

1. Set the `STREAM_DETAILS_SECRET_OCID`:

   ```console
   export STREAM_DETAILS_SECRET_OCID="ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caa6m5tuweeu3lbz22lf37y2dsbdojnhz2owmgvqgwwnvka"
   ```

1. Replace the value with the OCID of the secret in your environment.  
   >**NOTE:** You just used this OCID in the previous section to set the value for `const streamDetailsSecretOCID` in the file `consumer.go`.
   {:notice}

1. Verify that there's an OCI config file  
   In order to run the application locally, there needs to be an OCI configuration file.  By default, this config file is assumed to be called `config` and located in `$HOME/.oci`. However, you're free to use a different file name or even a different location.  All you need to do is specify the fully-qualified path to the configuration file using the environment variable *OCI_CONFIG_FILE*.  
   As noted above, the default value of *OCI_CONFIG_FILE* is `$HOME/.oci/config`.

#### Run the message producer application

With the reference to the OCI configuration file in place, we're ready to run the application and start producing random person messages to the OCI Stream (`go-on-oci-stream`).

1. To start the application from the command line using, run:

   ```console
   export INSTANCE_PRINCIPAL_AUTHENTICATION="NO"
   go run person-producer.go
   ```

   On the command line this looks like:

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-commandline-output.png 1109 430 "Locally running the Person Producer application" %}  

1. To check the messages that are published to the stream in the console:
   {% imgx aligncenter assets/way-to-go-on-oci-article-5-personmessages-in-console.png 1200 704 "Messages published to Stream from Person Producer application" %}  

### Build a lightweight Container Image for the Application

In may still seem far off, but the ultimate goal is to run the message producer as a containerized application on an OKE cluster. An essential step to getting there is creating a container image for the application.

The Go application is already built into a binary executable, so the resulting container image is just a single binary executable file. Well, almost. Ideally, we want the container image to be small. So, for example, something akin to the lean Alpine Linux base image.  

We also need to make that the right ca-certificates are installed in the image, otherwise the requests to the HTTPS API endpoints will fail.  

Lastly, the Go application needs to be compiled for the proper runtime environment.  

In this case, the specific build command we need to create the smallest possible executable able to run inside the Alpine container is:

```console
CGO_ENABLED=0 GOOS=linux go build -o person-producer -ldflags="-s -w" -tags=containers
```

>**NOTE:** The result of this command is a standalone binary executable file of about 6MB.
{:.alert}

#### Set up the container image

The container image is built from a Dockerfile called `DockerfileAlpine` and is located in the same directory as `person-producer.go`.  

It has the following content:

```docker
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

What this code accomplishes:

* The container image is created from the latest Alpine image.  
* A directory called `/app` is created and used for copying various files to.  
* The files that are copied to `/app` are:  
  * `config` (the OCI Configuration file)
  * `oci_api_key.pem` (the private key file referenced from the OCI Configuration file)
  * `person-producer` (the binary executable produced using `go build`).  
* The `RUN apk` line adds the required certificates to the image.  
* `CMD ["./person-producer"]` makes the application start up when a container based on this image starts running

#### Build the container image

1. Copy the file `$HOME/.oci/config` and the referenced \.pem file, *oci_api_key.pem*, to the current directory.  
1. Update the  `config` file by setting the `key_file` parameter to:

   ```text
   key_file=/app/oci_api_key.pem
   ```

   >**NOTE:** Normally, adding the OCI config and private key file should never be done in a container image that leaves your machine. We're only doing so now to test the image locally. Once we're certain everything is working properly, we'll rebuild the image without these files and only then push it to the container image registry.
   {:.warn}

1. Build the container image locally using this command:

   ```console
   docker build -t person-producer:1.0.0 -f DockerfileAlpine .
   ```

   >**NOTE:** The first time through, building the container will take a while since the base image needs to be loaded. In subsequent iterations, it should only take 15 seconds on average.
   {:.alert}

1. To check the success of the build process, inspect the command line output using `docker images | grep person-producer` and then run a container based on the image:

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

   And if you check in the OCI console for the Stream details, you'll find new Person messages published by the application running in the container. This is just what we're looking for and gives us confidence in the container image.  

#### Prepare the container image for non-local deployment

We're almost ready to move outside the local environment, but we're not quite there yet. We still need to remove the secrets references in the image.

1. Open the file `DockerfileAlpine`.  
1. Either comment out or remove lines 7 and 8 that copy the OCI Config and private key file.  
1. Rebuild the container image:

   ```console
   docker build -t person-producer:1.0.1 -f DockerfileAlpine .
   ```

   The console should echo something similar to the following:

   ```console
   The 1.0.1 image does not have the private parts that we do not want to ship.
   ```

   And now, we're all set!  

### Push the Container Image to the OCI Container Image Registry

Now that we have a container image free of secrets, it will need to be pushed to the OCI Container Image Registry before it can be deployed to an OKE Cluster. We'll go through the steps in the current section.

Before we dive into the specifics, lets give some context about what we'll be doing in the Container Image Registry. First some definitions. A repository inside the container registry is a collection point for versions of a container image. So far, fairly straightforward. Such a repository is created when an image is pushed, based on the name of the image. The name given to the repository is typically drawn from: `<region key>/<namespace>/<prefix>/<image-name>:<version tag>`. The *prefix* and *image-name* together become the name of the repository. It's important to note here that this name is *not* tied to a compartment. However, in order to organize the Container Image Registry in a way similar to how you've organized compartments, you may consider explicitly creating the repository in a specific compartment. This can be done through the OCI Console, the OCI CLI, or even through an API or Terraform operation. By establishing the repository beforehand, you can create it in the context of a specific compartment. The name of the resulting compartment (or even the names of levels of nested compartments) becomes part of the prefix of the container images.

**Example:**

Let's create a repository in the OCI Container Image Registry in the context of compartment `go-on-oci` and call the repository `person-producer`. When the container image is pushed as `<region key>/<namespace>/go-on-oci/person-producer:<version tag>`, this image will be stored in the repository.
>**NOTE:** If you don't create the repository before pushing the image, a repository is created automatically in the context of the root compartment and has the name, `go-on-oci/person-producer`. Everything will still work fine, but the repository structure is just a little less nice.
{:.notice}

{% imgx aligncenter assets/way-to-go-on-oci-article-5-create-image-repository.png 1200 347 "Create Container Image Registry Repository for person-producer images in compartment go-on-oci" %}  

1. On the command line of your development environment, `docker login` to `<region key>.ocir.io`, using your specific region key. You may recall, we did this in the third article in the series.  
   You'll need the login name and the authentication token.

   ```console
   docker login iad.ocir.io
   ```

1. Tag the locally-built image for use in the OCI Container Image Registry by running the command:

   ```console
   docker tag person-producer:1.0.1 <region key>/<namespace>/<prefix>/person-producer:1.0.1
   ```

   Example:

   ```console
   docker tag person-producer:1.0.1 iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
   ```

1. With the login done and this tag in place, the container image can be pushed.

   ```console
   docker push <region key>/<namespace>/<prefix>/person-producer:1.0.1
   ```

   Example:

   ```console
   docker push iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
   ```

1. To check the success of the push, inspect the OCI Container Image Registry through the OCI console.

### (Optional) Run a Container from the Image in Cloud Shell

There's an easy way to verify the existence of the container image.  

Open the Cloud Shell from the OCI Console and run:

```console
docker run -e INSTANCE_PRINCIPAL_AUTHENTICATION=NO iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:1.0.1
```

The will be download the image. If you run the image, it'll quickly exit because no OCI configuration file can be found. But, this shouldn't be too surprising. However, it does show us that the image was pushed successfully to the image registry.

### Create an OKE Cluster Instance

Creating an Kubernetes cluster on OCI may sound like a daunting task, but it's actually really simple. OCI provides a convenient wizard that will handle the entire process for you with minimal input.

Through the wizard, you can specify the number of nodes (either *Compute Instances* or *VMs*) in the cluster and what the shape of these VMs should be. You're not locked into this configuration, so you can easily change this later on.

After you've made that decision (or accepted the default settings), you can leave it to the wizard to take care of the network configuration, the compute instances, the node pool formed by the instances, and the Kubernetes cluster that sits on top of the node pool itself. It might take a few minutes, but once the OKE instance is available, you're all ready to accept deployments.

#### OCI wizard

1. Enter *ok* in the search box and then select the link **Kubernetes Clusters (OKE) | Containers & Artifacts**.
1. Select **Create cluster**.
   A popup window appears with two radio buttons: *Quick create* and *Custom create*.  
1. Accept the first one (*Quick create*) and then select **Launch workflow**.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-quickstart-oke.png 1200 389 "Create an OKE Cluster the Quickstart way" %}  

   >You're now in the wizard.
   {:.notice}

1. **[Wizard]**
   1. Select **Public Endpoint** and then **Private Workers**.  
      1. You can accept the shape *VM.Standard.E3.Flex* or pick a different one.  
      2. You can accept three as the number of nodes, but just one node is enough for our purposes.
      3. Select **Next**.

      {% imgx aligncenter assets/way-to-go-on-oci-article-5-quickcreate-oke-step1.png 1200 564 "Configure the OKE Cluster Quickstart wizard" %}  

   1. This next part of the wizard provides an overview of what the wizard will do on our behalf.  
      Here, you'll be able to perform a final inspection.
      If you like the proposed action, select **Creat cluster**.

      {% imgx aligncenter assets/way-to-go-on-oci-article-5-quickcreate-oke-step2.png 1200 754 "Overview o intended operations by the OKE Cluster Quickstart wizard " %}  

The wizard will provide all required resources and perform any actions that are needed, including network configuration, creating a new compute instance, and provisioning the OKE master. There's also a progress page available so you can keep track of the status of the actions.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-progress-page-oke-wizard.png 1105 902 "Progress overview of the actions performed by the OKE Cluster Quickstart wizard " %}  

#### Inspecting the Kubernetes cluster

Once all actions are complete, you can inspect the details of the new Kubernetes cluster, the node pool, the network resources, and the compute instance.  

The following images shows the details for the node pool and the node(s) in the pool.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-nodepool-for-oke.png 1200 564 "The Node Pool (with a single node) for the OKE Cluster " %}  

>**NOTE:** The dynamic group *go-on-oci-instances* that was defined in the first article in this series was created in such a way that it includes all compute instances in the compartment. This means that if you're still working in that same compartment and the OKE cluster is now also running in that compartment, the node in the OKE instance is a member of the dynamic group and inherits *all OCI IAM permissions granted to the group*. Containers running in Pods on the OKE instance and scheduled on this node also inherit these privileges when they use instance principal authentication.
{:.alert}

### Connect to the OKE Cluster instance

Interaction with a Kubernetes Cluster is typically done through the `kubectl` command line tool. We can use either the `kubectl` installation included in Cloud Shell, or a local installation of `kubectl`. However, before we can use `kubectl` to access a cluster, we have to specify the cluster on which to perform operations by setting up the cluster’s `kubeconfig` file.  

>**NOTE:** At the time of writing, to access a cluster using `kubectl` in Cloud Shell, the Kubernetes API endpoint must have a public IP address. Fortunately for us, our cluster alreadt does, thanks to the wizard!
{:.alert}

#### Set up

1. In the **Cluster Details** window, select **Access Cluster** to display the **Access Your Cluster** dialog box.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-accesscluster.png 1200 564 "Instructions for accessing the OKE Cluster - from Cloud Shell or any other environmenmt" %}  

1. Select **Cloud Shell Access** and then select **Copy** to copy the shell statement under (2) to the clipboard.  
1. Select **Launch Cloud Shell** to display the Cloud Shell window if it's not already open.  
1. Paste the shell statement into the Cloud Shell and then press enter to execute the statement.

#### Config file

Once this is complete, the config file in `$HOME/.kube` of your cloudshell environment is written (or updated if it already existed) with details for the new OKE cluster. Note that the OCI CLI understands the string PUBLIC_ENDPOINT and writes the proper Public IP Address for the cluster into the configuration file.

As long as we don't change the name or location of the config file from its default, we don't have to explicitly set the `KUBECONFIG` environment variable to refer to it, and we can now run `kubectl` to interact with our new cluster.

#### Interacting with the new cluster

**Local interaction:**
In addition to cluster access in Cloud Shell, we probably want to have local interaction from our laptop. It should have `kubectl` running already, as well as OCI CLI with configuration settings that provide access to the OCI tenancy.

1. In the OKE Cluster Details window in OCI Console, select **Access Cluster** again to display the **Access Your Cluster** dialog box.
1. This time, select  **Local Access**.
1. Copy the first statement (for public IP endpoint) in step 2 and execute it locally.  
   At this point, `kubectl` should be set up and ready for action. The file `$HOME/.kube/config` is either created or extended with an extra context. The current-context is set to this newly created one for the OKE cluster.  

**Test interaction:**
For a quick test, let's lists the node(s) that make up the OKE cluster. If you were to run the following command locally, you'll now get the same result as in cloud shell.

```console
kubectl get nodes
```

#### Kubernetes Dashboard

The Kubernetes Dashboard is a well-known UI for monitoring and managing the Kubernetes Cluster. While many other tools are available to make life easier, the dashboard remains as a comfortable and familiar fallback option.  

Perhaps not unsurprisingly, the Dashboard itself is a Kubernetes application, since it's just a collection of resources that needs to be created on the cluster. This means that there's a predefined collection of yaml files available that can be applied with a single command:

```console
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
```

**Example - check pods:**

1. Let's take a look at the pods in the newly-created namespace *kubernetes-dashboard*:

   ```console
   kubectl -n kubernetes-dashboard get pods
   ```

2. Access the dashboard in the browser, using: `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=default`

3. When the GUI appears in the browser, you'll be prompted for either a `kubeconfig` file or a token.  
   Let's go with the token:
   1. **Create the service account and `clusterbinding`** - Use the YAML file, `oke-admin-service-account.yaml`, to create both the service account and the `clusterrolebinding` in the cluster (as described in the [OCI Documentation for Accessing an OKE Cluster Instance]):

      ```console
      kubectl apply -f oke-admin-service-account.yaml
      ```

   2. **Generate token -** Run the following command:

      ```console
      kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep oke-admin | awk '{print $1}')
      ```

      This will result in a token be written to the console output:

      ```console
      Name:         oke-admin-token-4dg6k
      Namespace:    kube-system
      Labels:       <none>
      Annotations:  kubernetes.io/service-account.name: oke-admin
                    kubernetes.io/service-account.uid: 1e68cd7b-d362-4de4-8ce8-293ff9afecb4

      Type:  kubernetes.io/service-account-token

      Data
      ====
      token:      eyJhbGciOiJSUzI1NiIsImtpZCI6InZ1WFprUDRfTjRLYWpNNTVmYmFIMkNpY24yamxhN21IUmdpdjAyZzlVUVkifQ.ZWFjY291bnQvc2VjcmV0L...Weiw-zWpS1bG9GWlSVQxTQa1fVGOqWEQRtKHt_A0YEVn1bise-R_INwKmDkNQ7nbA1jmZycUOOgAePtIFqbjtvlY6QkA2lAkCQz0-YshIc01XCT7yieymzbyxhBWedbr9bIlHZW3qRb0IeEs_taAghkLHf23S71GxIbF558UUpE9w
      ca.crt:     1285 bytes
      namespace:  11 bytes
      ```

      >**NOTE:** The token is the section of output that starts with *eyJh* and ends with *pE9w*.  
      {:.notice}
   3. **Apply token -** Copy and paste this value into the window that prompts you for a token.

### Run the Person Producer Application on the OKE Cluster instance

The file, `person-producer-deployment.yaml`, contains the specification for the Kubernetes resources that we'd like to deploy on the cluster. Ultimately, we're looking to deploy with a Pod based on the container image (`<region key>.ocir.io/<namespace>/go-on-oci/person-producer:1.0.1`) that we [pushed a little while back](#push-the-container-image-to-the-oci-container-image-registry).

Here are the contents of the deployment specification:

```yaml
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
        - name: STREAM_DETAILS_SECRET_OCID
          value: "ocid1.vaultsecret.oc1.iad.amaaaaaa6sde7caa6m5tuweeu3lbz22lf37y2dsbdojnhz2owmgvqgwwnvka"
      imagePullSecrets:
    # enter the name of the secret you created  
      - name: ocirsecret
```

1. Update values in `person-producer-deployment.yaml`:
   * **`STREAM_DETAILS_SECRET_OCID`** - Change the value of this *env* key to the value that applies in your environment.  
   * **`image`** - Update the value to correspond with the image you pushed to the OCI Container Image Registry.

1. **Authentication -** The OKE Cluster can't just start pulling container images from the registry. It needs to use proper authentication details to log in to the registry. These details are represented in this deployment specification by the secret `ocirsecret`. However, the one wrinkle is that this secret doesn't exist yet on the OKE cluster.  
   **Create `ocirsecret` -** Run the following command in `kubectl`:

   ```console
   kubectl create secret docker-registry <secret-name> --docker-server=<region-key>.ocir.io --docker-username='<tenancy-namespace>/<oci-username>' --docker-password='<oci-auth-token>' --docker-email='<email-address>'
   ```

   This creates a secret in Kubernetes that can be used when needed to pull container images.

   The command should resolve to something similar to:

   ```console
   kubectl create secret docker-registry ocirsecret --docker-server=iad.ocir.io --docker-username='idtwlqf2hanz/jellema@chimney.nl' --docker-password='y&aya1PCjJFW8xk1.7o' --docker-email='jellema@chimney.nl'
   ```

1. **Apply the deployment specification -** After creating the secret, you can apply the deployment specification using `kubectl`, creating the deployment and the pod and pulling the image to run the container:

   ```console
   kubectl apply -f person-producer-deployment.yaml
   ```

   The somewhat underwhelming output of this command is just:

   ```console
   deployment.apps/personproducer-deployment created
   ```

   Here a little means a lot. And this is telling us that the Pod is starting, the container image is being pulled, and the application will soon run and start publishing messages.

1. **Check on the deployment -** There are multiple ways you can do this:
   * You can check the logs from the Pod in the Kubernetes Dashboard.  
   * You can also verify in the OCI Console if the expected messages arrive on the stream.  
   * You can even run application `applications/from-stream-to-database` and see if new database records get created.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-container-on-oke.png 579 743 "Overview of how the Person Producer container runs on a node in OKE, based on an image in OCI Container Image Registry and connects to Vault and Streaming" %}  

   **NOTE:**
   Logging may reveal problems with an application that has permissions for OCI resources. If the resource issue involves either retrieving the secret with stream details or producing messages to the stream itself, you may need to check if policy statements have been defined for the dynamic group `go-on-oci-instances` that allow all compute instances.

   At the compartment level, if the errors relate to the ability of the OKE cluster node (and by extension any application running in a container on this VM) to read secrets and work with streams, you'll need to do the following:  

   ```console
   allow dynamic-group go-on-oci-instances to read secret-family in compartment go-on-oci 

   allow dynamic-group go-on-oci-instances to manage streams in compartment go-on-oci
   ```

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-policies-on-streams-secrets-for-dyngroup-instances.png 887 571 "IAM Policies for the Dynamic Group with Compute Instances for accessing secrets and streams" %}  

### Create and run an OCI DevOps Deployment Pipeline to publish the Application to the OKE cluster

A *Deployment Pipeline* will take a Kubernetes manifest that manipulates K8S resources (e.g., creating a Pod or a Deployment) and apply it to a designated OKE cluster. The manifest contains a reference to a container image, most likely located in the OCI Container Image Registry (although it's also possible for to be in a public or other private registry). The manifest can also contain value placeholders of the form, `${parameterName}`. If present, these are replaced by the actual values of the parameters when the pipeline is executed.

How would this work in practice? The pipeline can be used to deploy specific, varying versions of images and also to set values in the manifest that translate to environment variables inside the container. For example, the value for *STREAM_DETAILS_SECRET_OCID* is provided by a pipeline parameter. This value is replaced before the deployment starts in the manifest and that value is available as environment variable to be read by the *person-producer* application.

#### Create an Inline Artifact with Kubernetes Manifest for a Deployment

1. Create an artifact in the DevOps Project,`person-producer-deployment-yaml`.
   * Type:  *Kubernetes manifest*
   * `Artifact source`: *inline*.
1. Paste in this Kubernetes manifest definition for creating a deployment based on a container image:

   ```yaml
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

   **NOTE:**
   * You have to replace part of the image name to make it fit your environment:  
     `iad.ocir.io/idtwlqf2hanz/go-on-oci/` => `<region key>/<namespace>/<repository prefix>`

     {% imgx aligncenter assets/way-to-go-on-oci-article-5-define-artifact-k8s-deployment.png 535 826 "Define an inline artifact of type Kubernetes manifest to create a K8S Deployment" %}  

   * Also keep in mind that the manifest contains two placeholders: \${STREAM_DETAILS_SECRET_OCID} and \${imageVersion}. These are replaced when the artifact is used by values from parameters set at deployment time.  
     Make sure to set the field `Replace parameters used in this artifact` to *Yes, substitute placeholders*.

1. Select **Save**.

#### Define a DevOps Environment for the OKE Cluster

1. Define an environment in the DevOps Project:
   * Type: *Oracle Kubernetes Engine*
   * Name: *go-on-oci-oke*
2. Select **Next**.
3. Select the cluster instance that you just created and then select **Create environment**.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-create-environment-for-oke.png 1200 557 "Create a DevOps (Deployment) Environment for the OKE Cluster" %}  

#### Define a Deployment Pipeline

1. Create a new Deployment Pipeline in the DevOps Project:
   1. Give it a name: *deploy-person-producer-to-oke*.
   1. Add a stage of type *Apply manifest to your Kubernetes cluster*.
   1. Select **Next** to define details.
   1. Assign a name: *apply-person-producer-deployment*
   1. Select the environment *go-on-oci-oke*.
   1. Select artifact *person-producer-deployment-yaml* as an artifact to apply.
      **Note:** Multiple *Kubernetes manifest* artifacts can be included in this stage.
   1. You can accept or change the Kubernetes namespace.
      Select **Save** to create the stage.

      {% imgx aligncenter assets/way-to-go-on-oci-article-5-define-deployment-pipeline-oke.png 1200 498 "Define a Deployment Pipeline for deploying a Container Image to the OKE Cluster" %}  

2. Define two Pipeline Parameters:
   * `STREAM_DETAILS_SECRET_OCID` - Its default value should be the OCID of the secret that contains the Stream details (message endpoint and stream OCID).
   * `imageVersion` - Its default value can be *1.0.1*. This parameter determines the version of the container image *person-producer* to get from the image registry and deploy onto the OKE cluster.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-deployment-pipeline-parameters.png 1200 338 "Define the deployment pipeline parameters - for the image version and the secret ocid" %}

#### Run the Deployment Pipeline to Deploy Person-Producer on OKE Cluster

Finally, the pipeline is ready to run! You can kick it off and have the Deployment created on Kubernetes. If you wish, you can provide overrides for the parameters, but more than likely, these aren't needed.

As you might imagine, running the pipeline is a little more impressive if you first removed the Pod and Deployment for person-producer from the OKE cluster. It should automatically be built by the pipeline, so if it makes a reappearance, you know it was the pipeline that did it.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-run-deployment-pipeline1.png 1200 716 "Run the deployment pipeline" %}  

The output from running the pipeline is definitely reassuring, green checkmarks all the way:
{% imgx aligncenter assets/way-to-go-on-oci-article-5-running-deployment-pipeline-output.png 1200 666 "Output from running the deployment pipeline" %}  

**Check status:**
At this point, there are a lot of different ways you can inspect the health of the system. You can:

* check on the Stream to find new messages being published,
* check in the Kubernetes Dashboard on the state of the Deployment and the Pod, *or*
* check in `kubectl` with `kubectl get pods` to find a very recently kicked-off Pod for `personproducer-deployment`.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-overview-personproducer-deployment-pipeline.png 593 654 "Overview of the DevOps Deployment Pipeline creating K8S deployment resource on OKE Cluster from person-producer container image" %}  

### Create an OCI DevOps Build Pipeline

As a final step, we'll create a new DevOps Build Pipeline that has more of a real-world application. This pipeline will build the Container Image for the `person-producer` application from the Go sources in the code repository, publish the container image to the registry, and then trigger the deployment pipeline. This means that whenever we commit a code change, we can run a pipeline that takes care of the end-to-end redeployment on the Kubernetes cluster for the changed application code.

The are quite a few steps, but they's are all fairly straightforward:

1. Create a DevOps artifact for the container image, `person-producer`.
1. Create the build pipeline.
1. Add the parameter `imageVersion*` - this determines the version for the container image to produce.
1. Add a managed build stage - this builds and tags the container image locally (on the build server).
1. Add a stage to publish the freshly built image to the container image registry.
1. Add a final stage to trigger the deployment pipeline,  *deploy-person-producer-to-oke*.

Now, let's test it out! Make a change to the application source code and commit the change to the code repository to trigger the build pipeline. This might take a few minutes, but afterwards, inspect the Stream for messages that carry the change made in the source code of the application.

#### Define DevOps Artifact

1. Add a new artifact in the DevOps project:
   * Name: `PersonProducerImage`
   * Type: `Docker image`
   * Artifact repository path: `iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:${imageVersion}`
1. Replace the *region key*, *namespace*, and *repository prefix* with values that conform to your environment.
1. Set `Replace parameters used in this artifact` to *Yes, substitute placeholders*.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-define-devopsartifact-for-containerimage.png 1200 447 "Define a DevOps Artifact for the  person-producer container image (with placeholder for version tag)" %}  

#### Create Build Pipeline and Add Parameter `imageVersion`

1. Create a new Build Pipeline in the DevOps Project:
   * Any name will do, but a good example might be: *build-person-message-producer*.
   * Optionally provide a description.
1. Define a parameter for the build pipeline:
   `imageVersion`: *1.0.5* (for this example)
   This parameter contains a string that defines the version label assigned to the container image produced by the build pipeline. The value of that parameter is also made available to the deployment pipeline to determine the container image to fetch from the container image registry and use in the Pod created on the OKE cluster instance.

{% imgx aligncenter assets/way-to-go-on-oci-article-5-define-buildpipeline-parameter.png 1200 441 "Define build pipeline parameter imageVersion" %}  

#### Add Managed Build Stage - to build the Container Image

1. Add a stage to the build pipeline.
   This stage has a lot to do. It will first gather the input sources from the source repository and build them into a linted, tested, vetted, and formatted Go application executable. From there, it will be converted into a lean container image.

   Name: *build-container-image-for-go-application*
   Type: *Managed Build*
   `build spec file path`: `/applications/person-message-producer/build_spec.yaml`

   This refers to the file `build_spec.yaml` in the root of the application directory for application *person-message-producer*. This file contains the build steps required to take the Go sources, perform the automated build steps on them, and finally build a lightweight, stand-alone executable suitable for the Alpine Linux container image. The last step performs the `docker build` into a container image, with the local tag `fresh-person-producer-container-image`. The output from the stage of type *DOCKER_IMAGE* is labeled `person-producer-image` and references the `fresh-person-producer-container-image`. This output is used in the next stage that publishes the container image to the container image registry.

2. Select the source code repository `go-on-oci-sources` and set the *Build source name* to `go-on-oci-sources`.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-add-managed-build-stage-for-container-image.png 1200 560 "Add a managed build stage  for building the Go application into a container image" %}  

3. Select **Save** to complete the stage definition.

#### Add a Stage to Publish the freshly built image to the container image registry

1. Add a second stage in the build pipeline.
   This stage will take care of taking the output of the managed build stage and pushing the container image to the registry, with the right version tag based on the build pipeline's parameter.

   * Name: *push-container-image*
   * Type: *Deliver artifacts*
1. Select the artifact to publish.
   * `PersonProducerImage`: the *Docker image*
   * Path: `iad.ocir.io/idtwlqf2hanz/go-on-oci/person-producer:${imageVersion}`
     This was defined as an artifact in the DevOps Project [earlier](#define-devops-artifact).

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-create-stage-to-publish-image.png 1173 815 "Create build stage to publish the container image to the registry" %}  

1. Select **Save** to complete the stage definition.

#### Add a stage to Trigger the Deployment Pipeline

1. Add a stage to the build pipeline.  
   * Name: *trigger-person-producer-deployment-pipeline*
   * Type: *Trigger deployment*
   * Deployment pipeline to be triggered by this stage: *deploy-person-producer-to-oke*.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-create-pipeline-stage-to-trigger-deployment-pipeline.png 1200 796 "Create Pipeline stage to trigger deployment pipeline" %}  

1. Select **Save** to complete the stage definition.

   {% imgx aligncenter assets/way-to-go-on-oci-article-5-buildpipeline-container-image.png 971 717 "Dependencies for the Build Pipeline - with code repository, artifact, container image registry and deployment pipeline" %}  

#### Run Build Pipeline, Create Container Image, and Run Deployment Pipeline

We're done! The Build Pipeline is complete. You can run it, set the value for parameter *imageVersion* and wait for the source code to be converted into a running Pod on OKE. In a typical workflow, you'll make a change to the application source code and commit that change to the code repository to trigger the build pipeline. After a few minutes, when the two pipelines are done, the changed application will be running. For reference, the end-to-end flow (triggering the build pipeline to completion of the deployment on the OKE instance) for the example presented in this article should take around three minutes.

Some things to keep an eye out for during the execution of the build pipelie:

* Midway through, the console should look similar to:
{% imgx aligncenter assets/way-to-go-on-oci-article-5-midway-build-pipeline.png 1200 564 "Build Pipeline in progress" %}  

* The output from the deployed application can be seen as the Pod logs in the Kubernetes Dashboard:

  {% imgx aligncenter assets/way-to-go-on-oci-article-5-pod-logs-in-dashboard.png 1200 308 "Checking the logs from the Person Producer Pod in the Kubernetes Dashboard" %}  

* You can also check out the logs from the Pod using kubectl:

  ```console
  kubectl logs -l app=personproducer
  ```

## Conclusion

This article demonstrated how a Go application, through the Go SDK for OCI, can easily publish messages to OCI Streaming topics as well as consume such messages. This application is varsatile and can run either on OCI or outside of it. It's credentials and other secrets are ideally managed using OCI Key Vault, something which the article also introduced and showed how it can be used from Go applications. Finally, a third type of application runtime platform was introduced, the managed OCI Kubernetes Engine (OKE). This application exists next to the VM and the serverless function. Once a Build Pipeline has created a container image for the application, OCI DevOps Deployment Pipelines can deploy our Go applications to OKE in an automated fashion.

The five articles that make up the series "Way to Go on OCI" have provided Go developers (*Gophers*) with a overview of how OCI provides a valuable platform both for engineering and running Go based applications as well as for leveraging relevant platform services from Go applications. The series demonstrates automated build and deployment of Go applications as stand alone executables on Compute Instances, as serverless functions and as containers on a Kubernetes cluster. Throughout the articles, introductions are given of these OCI services used from Go applications: Object Storage, Functions, API Gateway, Autonomous Database, Streaming and Key Vault. Additional, platform services used for engineering and operations were discussed, including DevOps Build and Deployment Pipelines, Code Repositories, Artifact Registry, Container Image Registry, IAM and Logging.

## Resources

[Source code repository for the sources discussed in this article series](https://github.com/lucasjellema/go-on-oci-article-sources)

[Oracle Cloud Infrastructure Blog - Automating a pod identity solution with Oracle Container Engine for Kubernetes (OKE) - by Ed Shnekendorf](https://blogs.oracle.com/cloud-infrastructure/post/automating-a-pod-identity-solution-with-oracle-container-engine-for-kubernetes-oke) - this article describes the use of instance principals for the nodes (OCI Compute Instances) in the OKE cluster to provide permissions for the Pods running on the node to access OCI services

[Oracle Functions - Connecting To An ATP Database With A Wallet Stored As Secrets - article by Todd Sharp on retrieving Oracle Wallet from OCI Vault from Functions](https://blogs.oracle.com/developers/post/oracle-functions-connecting-to-an-atp-database-with-a-wallet-stored-as-secrets)

[Protect Your Sensitive Data With Secrets In The Oracle Cloud - article by Todd Sharp on use of OCI Vault](https://blogs.oracle.com/developers/post/protect-your-sensitive-data-with-secrets-in-the-oracle-cloud)

[OCI Streaming — create producer/consumer use case using ATP, OIC and Kafka connect](https://medium.com/oracledevs/oci-streaming-create-producer-consumer-use-case-using-atp-oic-and-kafka-connect-e5be254edea3)

[Oracle Cloud Streaming Service – Scalable, Reliable, Kafka-like Event service on OCI](https://technology.amis.nl/oracle-cloud/oracle-cloud-streaming-service-scalable-reliable-kafka-like-event-service-on-oci/)

[SDK for Go Streaming Quickstart](https://docs.oracle.com/en-us/iaas/Content/Streaming/Tasks/streaming-quickstart-oci-sdk-for-go.htm#go-sdk-streaming-quickstart)

[Getting started (again) with Kubernetes on Oracle Cloud](https://technology.amis.nl/cloud/getting-started-again-with-kubernetes-on-oracle-cloud/)

[Compiling Your Go Application for Containers](https://medium.com/pragmatic-programmers/compiling-your-go-application-for-co-ntainers-b513190471aa)
