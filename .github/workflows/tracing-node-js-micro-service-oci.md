---
title: Tracing A Node.js with OCI Application Performance Monitoring and Zipkin
parent:
- tutorials
toc: false
tags:
- open-source
- oci
- nodejs
languages:
- nodejs
categories:
- frameworks
- cloudapps
thumbnail: assets/ociemailimage-10.jpg
description: Using Zipkin as an open-source tracking tool with OCI Application Performance
  Monitoring.
date: 2022-02-25 19:42
mrm: WWMK220224P00058
author:
  name: Javier Mugueta
  home: https://javiermugueta.blog/author/javiermugueta/
xredirect: https://developer.oracle.com/tutorials/tracing-node-js-micro-service-oci/
slug: tracing-node-js-micro-service-oci
---
OCI Application Performance Monitoring (APM) provides a comprehensive set of features to monitor applications and diagnose performance issues.  

APM integrates with open-source tracing system tools (aka, open-source tracers) such as Jaeger and **[Zipkin]** allowing you to upload trace data from your application. It also supports context propagation between Application Performance Monitoring agents and open-source tracers.  

In this tutorial, we'll cover how to set up APM on your system, configure your Node.js for tracing, and run some sample queries using Trace Explorer.  

## Configure APM

1. Go to **APM > Administration**
2. Select the **Create APM Domain** button and provide the information requested in popup window.  

   {% imgx assets/ociapmzipkinimage-92.jpg %}

   {% imgx assets/ociapmzipkinimage-93.jpg %}

   {% imgx assets/ociapmzipkinimage-94.jpg %}

## Grab domain details

In the APM domain details you created, get the **Data Upload Endpoint** URL and the **`auto_generated_public_datakey`** values, we’ll need them in the next [step](#configure-your-nodejs-app).  

{% imgx assets/ociapmzipkinimage-95.jpg %}

## Configure your Node.js app

Before we get started, make sure to:  

- **Configure Zipkin for your app -** Follow the steps in the [Zipkin JS repo] to configure Zipkin for your app.
- **Set up OCI APM -** Follow the step in this [document] to configure tracers for OCI.  

For the rest of this tutorial, we'll work with [sample code] in the Zipkin repo.  

First, clone the repo and then edit the sample code as noted below.

### Edit `web/recorder.js`

{% imgx assets/ociapmzipkinimage-96.jpg %}

#### First section of code

```console
/* eslint-env browser */
const {
BatchRecorder,
jsonEncoder: {JSON_V2}
} = require('zipkin');
const {HttpLogger} = require('zipkin-transport-http');
```

Replace the last line with:  

 ```console
 const CLSContext = require('zipkin-context-cls');
 ```

#### Second section of code  

```console
const debug = 'undefined' !== typeof window
 ? window.location.search.indexOf('debug') !== -1
 : process.env.DEBUG;
```

#### Third section of code

```console
// Send spans to Zipkin asynchronously over HTTP
const zipkinBaseUrl = 'http://localhost:9411';

// data upload endpoint example is something like https://aaaa...aaapi.apm-agt.eu-frankfurt-1.oci.oraclecloud.com/20200101/observations/public-span?dataFormat=zipkin&dataFormatVersion=2&dataKey=QM...3D
```

1. **Adjust `BaseURL` -** Of course, the `BaseURL` will not be a `localhost`, so replace `const zipkinBaseUrl = '<http://localhost:9411>;'` with:  

      ```console
      const httpLogger = new HttpLogger({
      endpoint: '<domain data upload endpoint in step 2>/20200101/observations/public-span?dataFormat=zipkin&dataFormatVersion=2&dataKey=<public data key in step 2>',
      jsonEncoder: JSON_V2
      })
      ```

2. **Remove the logger and add a tracer -**  
   1. Remove this:  

        ```console
        const httpLogger = new HttpLogger({
          endpoint: `${zipkinBaseUrl}/api/v2/spans`,
          jsonEncoder: JSON_V2
        });
        ```

   2. And add this:  

        ```console
        // Setup the tracer
        const tracer = new Tracer({
          ctxImpl: new CLSContext('zipkin'), // implicit in-process context
          recorder: new BatchRecorder({
            logger: httpLogger
          }), // batched http recorder
          localServiceName: 'mytest', // name of this application
          supportsJoin: false //Span join disable setting
        });
        ```

#### Remainder of code

A this point, the rest should look like this:  

```console
function recorder(serviceName) {
  return debug ? debugRecorder(serviceName) : new BatchRecorder({logger: httpLogger});
}

function debugRecorder(serviceName) {
  // This is a hack that lets you see the data sent to Zipkin!
  const logger = {
    logSpan: (span) => {
      const json = JSON_V2.encode(span);
      console.log(`${serviceName} reporting: ${json}`);
      httpLogger.logSpan(span);
    }
  };

  const batchRecorder = new BatchRecorder({logger});

  // This is a hack that lets you see which annotations become which spans
  return ({
    record: (rec) => {
      const {spanId, traceId} = rec.traceId;
      console.log(`${serviceName} recording: ${traceId}/${spanId} ${rec.annotation.toString()}`);
      batchRecorder.record(rec);
    }
  });
}
module.exports.recorder = recorder; 
```

## Restart your node app

{% imgx assets/ociapmzipkinimage-97.jpg %}

## APM Trace Explorer

Go to APM Trace Explorer and run a query:  

{% imgx assets/ociapmzipkinimage-98.jpg %}

Traces can be observed in the list!  

{% imgx assets/ociapmzipkinimage-91.jpg %}

## What's next

That’s all! Quick and easy!  

If you’re curious about the goings-on of Oracle Developers in their natural habitat, come join us in our [public Slack channel]!  

And don't forget our [free tier], where you can try out what we just discussed.  

To explore more information about development with Oracle products:  

- [Oracle Developers Portal]
- [Oracle Cloud Infrastructure]

<!--- links -->

[Zipkin]: (https://zipkin.io)
[Zipkin JS repo]: https://github.com/openzipkin/zipkin-js#readme
[document]: https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-open-source-tracing-systems.html
[sample code]: https://github.com/openzipkin/zipkin-js-example

[free tier]: https://signup.cloud.oracle.com/
[public Slack channel]: https://oracledevrel.slack.com/join/shared_invite/zt-uffjmwh3-ksmv2ii9YxSkc6IpbokL1g#/shared-invite/email

[Oracle Developers Portal]: https://developer.oracle.com/
[Oracle Cloud Infrastructure]: https://www.oracle.com/cloud/