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

Create an OCI Vault. 

Store Oracle Wallet in Vault. 

Extend Go App from article #4 with functionality to retrieve Oracle Wallet from the Vault. Remove Oracle Wallet from Artifact Repository. Update Deployment Pipeline. 

```
allow dynamic-group my-secret-group to read secret-family in compartment go-on=oci where target.secret.name = 'my-secret'
```

check https://blogs.oracle.com/developers/post/oracle-functions-connecting-to-an-atp-database-with-a-wallet-stored-as-secrets


## From Streaming Messages to new Database Records

Extend the application with functionality to consume message from Streaming Topic. The contents from the messages is used to create records in the autonomous database. Extend deployment pipeline to pass parameters (for vault secret & stream topic) to the Go application.

Run the pipelines – which cause the application to run.
Run the local Go application to produce messages to the Streaming Topic. 
Verify whether database records based on these messages have been created in the database table.


## Deploy Message Publisher on OKE

...
Create Compute Instance
Create OKE instance with that instance in the pool 
Create build pipeline for producing container image for Go application (similar to for Go Fn Function)
Create deploy pipeline for deployment of image to OKE instance


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