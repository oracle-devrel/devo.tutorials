---
title: Deploying a Custom Nodejs Web Application Integrated with Identity Cloud Service for Unique Single Sign On UX 
parent: [tutorials]
toc: false
tags: [open-source, oci, always-free, nodejs, javascript]
languages: [nodejs]
categories: [frameworks, cloudapps]
thumbnail: assets/ociemailimage-10.jpg
description: How to configure custom Node.js web application to have a unique Single Sign On user experience.
date: 2022-03-12 18:42
mrm: WWMK210625P00048 
author:
    name: Javier Mugueta
    home: https://javiermugueta.blog/author/javiermugueta/ 
---

In this post we are deploying a custom Node.js web application in Oracle Kubernetes Engine (OKE).

We want to show how to configure the custom web application so we have a unique Single Sign On user experience.

## First part

Follow this tutorial [here ](https://www.oracle.com/webfolder/technetwork/tutorials/obe/cloud/idcs/idcs_nodejs_sdk_obe/idcs-nodejs-sdk.html)explaining how to enable SSO to the web app running locally

## Second part

Now we are making small changes to deploy on kubernetes

Create a Dockerfile in the nodejs folder of the cloned project with the following:

```console
FROM oraclelinux:7-slim
WORKDIR /app
ADD . /app
RUN curl --silent --location https://rpm.nodesource.com/setup_11.x | bash -
RUN yum -y install nodejs npm --skip-broken
EXPOSE 3000
CMD ["npm","start"]
```

Create K8s deployment file as follows:

```console 
apiVersion: v1
kind: Service
metadata:
name: idcsnodeapp
spec:
type: LoadBalancer
selector:
app: idcsnodeapp
ports:
- name: client
protocol: TCP
port: 3000
```

Deploy to k8s:

```console
kubectl apply -f service.yaml
```

Grab the url of the new external load-balancer service created in k8s and modify the file auth.js with the appropriate values in your cloud environment

```console 
var ids = {
oracle: {
"ClientId": "**client id of the IdCS app**",
"ClientSecret": "**client secret of the IdCS app**",
"ClientTenant": "**tenant id (idcs-xxxxxxxxxxxx)**",
"IDCSHost": "https://**tenantid**.identity.oraclecloud.com",
"AudienceServiceUrl" : "https://**tenantid**.identity.oraclecloud.com",
"TokenIssuer": "https://identity.oraclecloud.com/",
"scope": "urn:opc:idm:t.user.me openid",
"logoutSufix": "/oauth2/v1/userlogout",
"redirectURL": "http://**k8sloadbalancerip**:3000/callback",
"LogLevel":"warn",
"ConsoleLog":"True"
}
};
```

Build the container and push to a repo you have write access to, such as:

```console
docker build -t javiermugueta/idcsnodeapp .
docker push javiermugueta/idcsnodeapp
```

Modify the IdCS application with the public IP of the k8s load-balancer service

{% imgx assets/okenodejavierimagaidcssso.png %}

Create a k8s deployment file as follows:

```console
apiVersion: apps/v1
kind: Deployment
metadata:
name: idcsnodeapp
labels:
app: idcsnodeapp
spec:
replicas: 1
selector:
matchLabels:
app: idcsnodeapp
strategy:
type: Recreate
template:
metadata:
labels:
app: idcsnodeapp
spec:
containers:
- image: javiermugueta/idcsnodeapp
name: idcsnodeapp
ports:
- containerPort: 3000
name: idcsnodeapp
``` 
    
    

Deploy to k8s

```console
    kubectl apply -f  deployment.yaml
```

Test the app and verify SSO is working:
{% imgx assets/okejavierslideshowpartidcssso1.png %}



Hope it helps! 🙂

