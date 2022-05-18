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
---
OCI Application Performance Monitoring (APM) provides a comprehensive set of features to monitor applications and diagnose performance issues.

Application Performance Monitoring integrates with open-source tracing system tools (open-source tracers) such as Jaeger and **[Zipkin](https://zipkin.io)** and enables you to upload trace data. It also supports context propagation between Application Performance Monitoring agents and open-source tracers.

## STEP 1: Configure APM

Go to APM->Administration, click in [Create APM Domain] button and provide the information requested in popup window.


{% imgx assets/ociapmzipkinimage-92.jpg %}

{% imgx assets/ociapmzipkinimage-93.jpg %}

{% imgx assets/ociapmzipkinimage-94.jpg %}

## STEP 2: Grab domain details

In the APM domain details you created, get the **[Data Upload Endpoint]** URL and the **auto_generated_public_datakey** values, we’ll need them in step 3.


{% imgx assets/ociapmzipkinimage-95.jpg %}

## STEP 3: Configure your Node.js app

Follow the steps [here](https://github.com/openzipkin/zipkin-js) to configure Zipkin in your app. [Here's the doc](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-open-source-tracing-systems.html) from OCI APM with detailled instructions for the OCI part. 

If you want to use an example, use [this](https://github.com/openzipkin/zipkin-js-example), as it's the code we're going to use for this post. Clone the repo and edit file web/recorder.js according to the instructions below (note the changes we'll make):

{% imgx assets/ociapmzipkinimage-96.jpg %}

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

We continue with:

```console
const debug = 'undefined' !== typeof window
  ? window.location.search.indexOf('debug') !== -1
  : process.env.DEBUG;
```

Of course, the BaseURL will not be a localhost, so remove the line below the comment here:

```console
// Send spans to Zipkin asynchronously over HTTP
const zipkinBaseUrl = 'http://localhost:9411';

// data upload endpoint example is something like https://aaaa...aaapi.apm-agt.eu-frankfurt-1.oci.oraclecloud.com/20200101/observations/public-span?dataFormat=zipkin&dataFormatVersion=2&dataKey=QM...3D
```

And replace **const zipkinBaseUrl = 'http://localhost:9411;'** with:

```console
const httpLogger = new HttpLogger({
  endpoint: '<domain data upload endpoint in step 2>/20200101/observations/public-span?dataFormat=zipkin&dataFormatVersion=2&dataKey=<public data key in step 2>',
  jsonEncoder: JSON_V2
})
```

Here we'll remove this logger and add a tracer. First remove this:

```console
const httpLogger = new HttpLogger({
  endpoint: `${zipkinBaseUrl}/api/v2/spans`,
  jsonEncoder: JSON_V2
});
```

And add this:

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

The rest should look like this:

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

## STEP 4: Restart your node app

{% imgx assets/ociapmzipkinimage-97.jpg %}


## STEP 5: APM TRACE EXPLORER TIME!

Go to APM Trace explorer and run a query

{% imgx assets/ociapmzipkinimage-98.jpg %}


Traces can be observed in the list!

{% imgx assets/ociapmzipkinimage-91.jpg %}


That’s all, hope it helps!! 🙂

If you’re curious about the goings-on of Oracle Developers in their natural habitat, come join us on our [public Slack channel](https://oracledevrel.slack.com/join/shared_invite/zt-uffjmwh3-ksmv2ii9YxSkc6IpbokL1g#/shared-invite/email)!

And don't forget our [free tier](https://signup.cloud.oracle.com/?language=en), where you can try out what we just discussed.
