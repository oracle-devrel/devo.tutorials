---
title: Hosting a private Helm Repository on OCI (Oracle Cloud Infrastructure) with
  ChartMuseum and OCI Object Storage
parent:
- tutorials
thumbnail: assets/helm-network-diagram.png
tags:
- back-end
- oci
date: 2021-12-15 12:21
description: This guide walks you through how to host Helm Chart privately with ChartMuseum,  an
  open source Helm Chart Repository server with support for various cloud storage
  backends, including OCI Object Storage.
MRM: WWMK211213P00054
ali-mukadam:
  name: Ali Mukadam
  home: https://lmukadam.medium.com
  bio: |-
    Technical Director, Asia Pacific Center of Excellence.
    For the past 16 years, Ali has held technical presales, architect and industry consulting roles in BEA Systems and Oracle across Asia Pacific, focusing on middleware and application development. Although he pretends to be Thor, his real areas of expertise are Application Development, Integration, SOA (Service Oriented Architecture) and BPM (Business Process Management). An early and worthy Docker and Kubernetes adopter, Ali also leads a few open source projects (namely [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke)) aimed at facilitating the adoption of Kubernetes and other cloud native technologies on Oracle Cloud Infrastructure.
  linkedin: alimukadam
xredirect: https://developer.oracle.com/tutorials/helm-repository-chartmuseum-object/
slug: helm-repository-chartmuseum-object
---
In [another article](extending-terraform-oke-helm-chart.md), we deployed a helm chart (Redis) into Oracle Container Engine (OKE) which we pulled from the stable repository.  

We've [already described](oci-iac-framework/getting-started-with-oci-step-4-app-infrastructure.md) how to host the container images privately on Oracle Registry Service (OCIR). What if we want to do the same for our helm charts?

Fortunately, there is a solution for that too.

In this article we'll introduce you to chartmuseum, an open source Helm Chart Repository server with support for various cloud storage backends, including OCI Object Storage.

## Additional information

By default, the stable repo is hosted at [here](https://kubernetes-charts.storage.googleapis.com/).

We can also manually add the [incubator repository](https://github.com/helm/charts/tree/master/incubator) if we want to:

```console
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
```

This should respond with something similar to:  

```console
"incubator" has been added to your repositories
```

The container images in those repositories are also publicly available (for example, the default image for redis is `bitnami/redis` in bitnami’s container redis repository on Dockerhub).

## Prerequisites

* An Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).
* A MacOS, Linux, or Windows computer with `ssh` support installed.
* [OCI Cloud Shell] - It provides a great platform for quickly working with Terraform as well as a host of other OCI interfaces and tools.

## Getting started

In this tutorial, we'll be using the [terraform-oci-oke] project to provision the OKE cluster. For more details, see [this post] on provisioning OKE using Terraform.  

Below is an architecture of what we’ll build:  

{% imgx assets/helm-network-diagram.png  "Deploying chartmuseum on OCI" %}

## Install nginx-controller

1. **Install DNS -** Follow [this post] to install [ExternalDNS].

2. **nginx -** Install [nginx-controller].  
   We’ll use this to access chartmuseum later.  

   In the command below, replace `chartmuseum.acme.com` by your preferred hostname:  

      ```console
      helm install --name nginxcontroller stable/nginx-ingress \
      --set controller.name=controller \
      --set defaultBackend.enabled=true \
      --set defaultBackend.name=defaultbackend \
      --set rbac.create=true \
      --set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"=chartmuseum.acme.com
      ```

3. Verify that an OCI Load Balancer has been created and a DNS `A` record has been inserted in the DNS Zone.

## Create OCI Bucket

In the OCI Console, navigate to **Object Storage** and create a bucket called *chartmuseum*:

{% imgx assets/helm-chartmuseum-bucket.png  "chartmuseum bucket window" %}

## Deploy *chartmuseum*

We want a similar experience to the stable or incubator repos:  

* anonymous `GET` but protected `POST` requests
* Basic Auth for authentication purposes

### Create secrets

We'll need to create 2 secrets to accomplish this.

1. **secret 1 -** Let’s start by creating a secret to hold the Basic Auth *username* and *password*:  

      ```console
      kubectl create secret generic chartmuseum-auth --from-literal=user=curator --from-literal=pass=password
      ```

1. **secret 2 -** You'll also need to create a secret that will allow chartmuseum to communicate with the OCI APIs.

   1. Temporarily, copy your API keys to the bastion. You can also do this locally if you have `kubectl` and local access to the kubeconfig.  

   1. Create a file `config` and enter your user and tenancy OCIDs, api key fingerprint, and region value. The `key_file` value has to be `/home/chartmuseum/.oci/oci.key`.

      ```console
      [DEFAULT]                                           
      user=<USER_OCID>                                                                                    
      fingerprint=<API_KEY_FINGERPRINT>
      key_file=/home/chartmuseum/.oci/oci.key                         
      tenancy=<TENANCY_OCID>
      region=<REGION>
      ```

   1. Create the secret using appropriate absolute or relative path to the config file and private API key.

         ```console
         kubectl create secret generic chartmuseum-secret --from-file=config="/path/to/config" --from-file=key_file="/path/to/apikey.pem"
         ```

### Install *chartmuseum*

With the secrets created, we're ready to start deploying chartmuseum.

1. Download the chartmuseum values file:

      ```console
      curl -o values.yaml https://raw.githubusercontent.com/helm/charts/master/stable/chartmuseum/values.yaml
      ```

1. Edit the `values.yaml` file and replace the parameters as follows:  

      ```console
      env:
        open:
          STORAGE: oracle
          STORAGE_ORACLE_COMPARTMENTID:<COMPARTMENT_OCID>
          STORAGE_ORACLE_BUCKET: chartmuseum
          STORAGE_ORACLE_PREFIX: chartmuseum
          DISABLE_API: false
          AUTH_ANONYMOUS_GET: true
          AUTH_REALM: chartmuseumexistingSecret: chartmuseum-auth
      existingSecretMappings:
        BASIC_AUTH_USER: user
        BASIC_AUTH_PASS: passingress:
        enabled: true
        labels:
          dns: "ocidns"annotations:
          kubernetes.io/ingress.class: nginxhosts:
         - name: chartmuseum.acme.com
           path: /
           tls: falseoracle:
        secret:
          enabled: true
          name: chartmuseum-secret
          config: config
          key_file: key_file
      ```

1. Install chartmuseum:  

      ```console
      helm install --name=chartmuseum -f values.yaml stable/chartmuseum
      ```

1. Wait for the pod to run:

      ```console
      kubectl get pods -w
      ```

   This should give output similar to:  

      ```console
      NAME                                                            READY   STATUS    RESTARTS   AGE                                                                      
      chartmuseum-chartmuseum-748c8dbbd8-7nctc                        1/1     Running   0          5m20s
      ```

### Verify installation

1. Verify that the ingress has been created:

      ```console
      kubectl get ing
      ```

   This should give output similar to:  

      ```console
      NAME                      HOSTS                       ADDRESS   PORTS   AGE                                                                                           
      chartmuseum-chartmuseum   chartmuseum.acme.com             80      7m9s
      ```

1. And that it also maps to the *chartmuseum* service:

   ```console
   k describe ing 
   ```

   This should give output similar to:  

      ```console
      chartmuseum-chartmuseum                                                                                                     
      Name:             chartmuseum-chartmuseum                                                                                                                             
      Namespace:        default                                                                                                                                             
      Address:                                                                                                                                                              
      Default backend:  default-http-backend:80 ()                                                                                                                    
      Rules:                                                                                                                                                                
        Host                       Path  Backends                                                                                                                           
        ----                       ----  --------                                                                                                                           
        chartmuseum.acme.com                                                                                                                                           
                                   /   chartmuseum-chartmuseum:8080 ()                                                                                                
      Annotations:                                                                                                                                                          
        kubernetes.io/ingress.class:  nginx                                                                                                                                 
      Events:                                                                                                                                                               
        Type    Reason  Age    From                      Message                                                                                                            
        ----    ------  ----   ----                      -------                                                                                                            
        Normal  CREATE  6m20s  nginx-ingress-controller  Ingress default/chartmuseum-chartmuseum                                                                            
        Normal  UPDATE  5m31s  nginx-ingress-controller  Ingress default/chartmuseum-chartmuseum
      ```

1. Verify whether you can [reach *chartmuseum* publicly](http://chartmuseum.acme.com) with your browser.  

   {% imgx assets/helm-chartmuseum-welcome-msg.png  "Chartmuseum welcome message" %}

### Pushing a chart to chartmuseum

1. Install the helm `push` plugin:  

      ```console
      helm plugin install https://github.com/chartmuseum/helm-push
      ```

1. Add the repo:  

      ```console
      helm repo add --username curator --password password cm http://chartmuseum.acme.com/
      ```

1. Create a basic test chart, `mychart`  

      ```console
      helm create mycharthelm package mychart
      ```

   This should respond with something similar to:  

      ```console
      Successfully packaged chart and saved it to: /home/opc/chart/mychart-0.1.0.tgz
      ```

1. Push the chart:

      ```console
      helm push mychart cm
      ```

   This should respond with something similar to:  

      ```console
      Pushing mychart-0.1.0.tgz to cm...                                                                                                                                    
      Done.
      ```

   If we search for `mychart` at this point, we'll only find the local copy:

      ```console
      helm search mychart
      ```

   This will respond with something similar to:  

      ```console
      NAME            CHART VERSION   APP VERSION     DESCRIPTION                                                                                                           
      local/mychart   0.1.0           1.0             A Helm chart for Kubernetes
      ```

1. We'll need to do a few things to get `mypart` to appear.
   1. First, do a `repo update`:  

         ```console
         helm repo update cm
         ```

      This should respond with something similar to:  

         ```console
         Hang tight while we grab the latest from your chart repositories...                                                                                                   
         ...Skip local chart repository                                                                                                                                        
         ...Successfully got an update from the "cm" chart repository                                                                                                          
         ...Successfully got an update from the "stable" chart repository                                                                                                      
         Update Complete. ⎈ Happy Helming!⎈
      ```

   2. And then, conduct a new search:  

         ```console
         helm search mychart     
         ```

      This should respond with something similar to:  

         ```console
         NAME            CHART VERSION   APP VERSION     DESCRIPTION                                                                                                           
         cm/mychart      0.1.0           1.0             A Helm chart for Kubernetes                                                                                           
         local/mychart   0.1.0           1.0             A Helm chart for Kubernetes
         ```

      Our test chart (`mychart`) appears!

## Testing authentication

At this point, we *could* test authentication by removing the repo and adding it again without the username and password. Instead, we'll try something a little more elegant and use a combination of Postman and chartmuseum’s APIs to test.  

These are the behaviors we're looking for:

* `GET`: No Auth Required
* `POST`: Auth Required
* `DELETE`: Auth Required

{% imgx assets/helm-get-request-w-chartmuseum.png  "GET (without authentication)" %}

From this, you can see we're able to get a list of charts using `GET` without authentication.

However, a `DELETE` or `POST` without authentication fails:

{% imgx assets/helm-chartmuseum-unauth-request.png  "Unauthorized chart deletion" %}

Yet another twist: when we enter the credentials, the chart deletion succeeds:

{% imgx assets/helm-chartmuseum-good-request.png  "Successful chart deletion" %}

If we now check OCI Object Storage, we can see our chart there:

{% imgx assets/helm-oci-dash.png  "OCI dashboard displaying Chartmuseum details " %}

## Let’s Encrypt

Now that chartmuseum is up and running, we'll also want to secure its usage by encrypting traffic. To do this, we'll use Let’s Encrypt and cert-manager. *cert-manager* is an “add-on to automate the management and issuance of TLS certificates from various issuing sources.”

At this point, you can follow along with the [cert-manager installation guide] or read on.

1. Create the `CustomResourceDefinitions` namespace for cert-manager and disable resource validation on the namespace:  

      ```console
      kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yamlkubectl create namespace cert-managerkubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
      ```

1. Add the Jetpack Helm repo and update:  

      ```console
      helm repo add jetstack https://charts.jetstack.io
      helm repo update jetstack
      ```

1. Install cert-manager using its helm chart:  

      ```console
      helm install --name cert-manager --namespace cert-manager \
      ```

1. Verify the installation:  

      ```console
      kubectl get pods --namespace cert-manager
      ```

   This should respond with something similar to:

      ```console
      NAME                                       READY   STATUS    RESTARTS   AGE                                                                                                                   
      cert-manager-776cd4f499-98vsh              1/1     Running   0          3h14m                                                                                                                 
      cert-manager-cainjector-744b987848-pkk5s   1/1     Running   0          3h14m                                                                                                                 
      cert-manager-webhook-645c7c4f5f-4mbjd      1/1     Running   0          3h14m
      ```

1. Test that the webhook works by creating a `test-resources.yaml` file:  

      ```console
      apiVersion: v1
      kind: Namespace
      metadata:
        name: cert-manager-test
      ---
      apiVersion: certmanager.k8s.io/v1alpha1
      kind: Issuer
      metadata:
        name: test-selfsigned
        namespace: cert-manager-test
      spec:
        selfSigned: {}
      ---
      apiVersion: certmanager.k8s.io/v1alpha1
      kind: Certificate
      metadata:
        name: selfsigned-cert
        namespace: cert-manager-test
      spec:
        commonName: example.com
        secretName: selfsigned-cert-tls
        issuerRef:
          name: test-selfsigned
      ```

1. Create the test resources:  

      ```console
      kubectl create -f test-resources.yaml
      ```

1. Check the status of the newly-created certificate:  

      ```console
      kubectl describe certificate -n cert-manager-testName:         selfsigned-cert
      ```

   It should respond with something similar to:  

      ```console
      Namespace:    cert-manager-test                                                                                                                                                               
      Labels:                                                                                                                                                                                 
      Annotations:                                                                                                                                                                            
      API Version:  certmanager.k8s.io/v1alpha1                                                                                                                                                     
      Kind:         Certificate                                                                                                                                                                     
      Metadata:                                                                                                                                                                                     
        Creation Timestamp:  2019-06-25T00:45:25Z                                                                                                                                                   
        Generation:          1                                                                                                                                                                      
        Resource Version:    116448                                                                                                                                                                 
        Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/cert-manager-test/certificates/selfsigned-cert                                                                            
        UID:                 8576413b-96e2-11e9-b5fc-0a580aed39b8                                                                                                                                   
      Spec:                                                                                                                                                                                         
        Common Name:  example.com                                                                                                                                                                   
        Issuer Ref:                                                                                                                                                                                 
          Name:       test-selfsigned                                                                                                                                                               
        Secret Name:  selfsigned-cert-tls                                                                                                                                                           
      Status:                                                                                                                                                                                       
        Conditions:                                                                                                                                                                                 
          Last Transition Time:  2019-06-25T00:45:26Z                                                                                                                                               
          Message:               Certificate is up to date and has not expired                                                                                                                      
          Reason:                Ready                                                                                                                                                              
          Status:                True                                                                                                                                                               
          Type:                  Ready                                                                                                                                                              
        Not After:               2019-09-23T00:45:26Z                                                                                                                                               
      Events:
      ```

>**Note:** You can delete the test resources after testing:
>
>```console
>kubectl delete -f test-resources.yaml
>```
>
{:notice}

### Configuring *Let’s Encrypt* issuers

For reference, you can follow [the quick-start guide] for using cert-manager with Nginx Ingress.

1. Let’s start with creating a `staging issuer` by creating a `staging-issuer.yaml` and using your email address:  

      ```console
      apiVersion: certmanager.k8s.io/v1alpha1                                                                                                                                                       
      kind: Issuer                                                                                                                                                                                  
      metadata:                                                                                                                                                                                     
        name: cm-staging                                                                                                                                                                            
      spec:                                                                                                                                                                                         
        acme:                                                                                                                                                                                       
        # The ACME server URL                                                                                                                                                                       
          server: https://acme-staging-v02.api.letsencrypt.org/directory                                                                                                                            
          # Email address used for ACME registration                                                                                                                                                
          email: your_email_address                                                                                                                                                             
          # Name of a secret used to store the ACME account private key                                                                                                                             
          privateKeySecretRef:                                                                                                                                                                      
            name: cm-staging                                                                                                                                                                        
          # Enable the HTTP-01 challenge provider                                                                                                                                                   
          http01: {}
      ```

1. Create the `staging issuer`:

      ```console
      kubectl create -f staging-issuer.yaml
      ```

   This will respond with something similar to:  

      ```console
      issuer.certmanager.k8s.io/cm-staging created
      ```

1. Repeat the above for a production environment by creating a `production-issuer.yaml`, once again using your email address:  

      ```console
      apiVersion: certmanager.k8s.io/v1alpha1                                                                                                                                                       
      kind: Issuer                                                                                                                                                                                  
      metadata:                                                                                                                                                                                     
        name: cm-prod                                                                                                                                                                               
      spec:                                                                                                                                                                                         
        acme:                                                                                                                                                                                       
        # The ACME server URL                                                                                                                                                                       
          server: https://acme-v02.api.letsencrypt.org/directory                                                                                                                                    
          # Email address used for ACME registration                                                                                                                                                
          email: your_email_address                                                                                                                                                             
          # Name of a secret used to store the ACME account private key                                                                                                                             
          privateKeySecretRef:                                                                                                                                                                      
            name: cm-prod                                                                                                                                                                           
          # Enable the HTTP-01 challenge provider                                                                                                                                                   
          http01: {}
      ```

1. Create the issuer:  

      ```console
      kubectl create -f production-issuer.yaml
      ```

   Check the status of the staging issuer:

      ```console
      kubectl describe issuer cm-stagingName:         cm-staging
      ```

   This should respond with something similar to:  

      ```console
      Namespace:    default
      Labels:
      Annotations:
      API Version:  certmanager.k8s.io/v1alpha1
      Kind:         Issuer
      Metadata:
        Creation Timestamp:  2019-06-25T03:28:16Z
        Generation:          1
        Resource Version:    143856
        Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/default/issuers/cm-staging
        UID:                 452908da-96f9-11e9-b5fc-0a580aed39b8
      Spec:
        Acme:
          Email:  your_email_address
          Http 01:
          Private Key Secret Ref:
            Name:  cm-staging
          Server:  <https://acme-staging-v02.api.letsencrypt.org/directory>
      Status:
        Acme:
          Uri:  <https://acme-staging-v02.api.letsencrypt.org/acme/acct/9718789>
        Conditions:
          Last Transition Time:  2019-06-25T03:28:17Z
          Message:               The ACME account was registered with the ACME server
          Reason:                ACMEAccountRegistered
          Status:                True
          Type:                  Ready
      Events:

      ```

## Enable TLS on chartmuseum

Edit your `values.yaml` file for chartmuseum and look for the Ingress section. Pay special attention to the added configuration commands.

```console
annotations:                                                                                                                                                                                
    kubernetes.io/ingress.class: nginx                                                                                                                                                        
    kubernetes.io/tls-acme: "true"                                                                                                                                                            
    certmanager.k8s.io/issuer: "cm-staging"                                                                                                                                                      
    certmanager.k8s.io/acme-challenge-type: http01                                                                                                                                            
                                                                                                                                                                                              
## Chartmuseum Ingress hostnames                                                                                                                                                              
## Must be provided if Ingress is enabled                                                                                                                                                     
##                                                                                                                                                                                            
  hosts:                                                                                                                                                                                      
    - name: chartmuseum.acme.com                                                                                                                                                         
      path: /                                                                                                                                                                                 
      tls: true                                                                                                                                                                               
      tlsSecret: cm-tls
```

1. Upgrade your helm chart:

      ```console
      helm upgrade chartmuseum stable/chartmuseum -f values.yaml
      ```

   This will respond with something similar to:  

      ```console
      Release "chartmuseum" has been upgraded. Happy Helming!
      ```

1. cert-manager will read the annotations and create a certificate:  

      ```console
      kubectl get certificate
      ```

   This will respond with something similar to:  

      ```console
      NAME        READY   SECRET      AGE                                                                                                                                                           
      cm-tls      True    cm-tls      45m
      ```

1. Take a quick peek at the certificate:  

      ```console
      kubectl describe certificate cm-tlsName: cm-tls
      ```

   This will respond with something similar to:  

      ```console
      Namespace:    default                                                                                                                                                                                              
      Labels:       app=chartmuseum                                                                                                                                                                                      
                    chart=chartmuseum-2.3.1                                                                                                                                                                              
                    dns=ocidns                                                                                                                                                                                           
                    heritage=Tiller                                                                                                                                                                                      
                    release=chartmuseum                                                                                                                                                                                  
      Annotations:                                                                                                                                                                                                 
      API Version:  certmanager.k8s.io/v1alpha1                                                                                                                                                                          
      Kind:         Certificate                                                                                                                                                                                          
      Metadata:                                                                                                                                                                                                          
        Creation Timestamp:  2019-06-25T03:33:47Z                                                                                                                                                                        
        Generation:          1                                                                                                                                                                                           
        Owner References:                                                                                                                                                                                                
          API Version:           extensions/v1beta1                                                                                                                                                                      
          Block Owner Deletion:  true                                                                                                                                                                                    
          Controller:            true                                                                                                                                                                                    
          Kind:                  Ingress                                                                                                                                                                                 
          Name:                  chartmuseum-chartmuseum                                                                                                                                                                 
          UID:                   d5a9cee1-9673-11e9-a790-0a580aed1020                                                                                                                                                    
        Resource Version:        152567                                                                                                                                                                                  
        Self Link:               /apis/certmanager.k8s.io/v1alpha1/namespaces/default/certificates/cm-tls                                                                                                                
        UID:                     0ac806f6-96fa-11e9-8836-0a580aed4b3e                                                                                                                                                    
      Spec:                                                                                                                                                                                                              
        Acme:                                                                                                                                                                                                            
          Config:                                                                                                                                                                                                        
            Domains:                                                                                                                                                                                                     
              chartmuseum.acme.com                                                                                                                                                                                  
            Http 01:                                                                                                                                                                                                     
              Ingress Class:  nginx                                                                                                                                                                                      
        Dns Names:                                                                                                                                                                                                       
          chartmuseum.acme.com                                                                                                                                                                                      
        Issuer Ref:                                                                                                                                                                                                      
          Kind:       Issuer                                                                                                                                                                                             
          Name:       cm-staging                                                                                                                                                                                         
        Secret Name:  cm-tls                                                                                                                                                                                             
      Status:                                                                                                                                                                                                            
        Conditions:                                                                                                                                                                                                      
          Last Transition Time:  2019-06-25T04:19:27Z                                                                                                                                                                    
          Message:               Certificate is up to date and has not expired                                                                                                                                           
          Reason:                Ready                                                                                                                                                                                   
          Status:                True                                                                                                                                                                                    
          Type:                  Ready                                                                                                                                                                                   
        Not After:               2019-09-23T03:19:27Z                                                                                                                                                                    
      Events:                                                                                                                                                                                                            
        Type    Reason              Age                  From          Message                                                                                                                                           
        ----    ------              ----                 ----          -------                                                                                                                                           
        Normal  Cleanup             44m                  cert-manager  Deleting old Order resource "cm-tls-3817114402"                                                                                                   
        Normal  OrderCreated        43m (x2 over 44m)    cert-manager  Created Order resource "cm-tls-3433596774"                                                                                                        
        Normal  OrderComplete       43m                  cert-manager  Order "cm-tls-3433596774" completed successfully                                                                                                  
        Normal  Cleanup             2m21s                cert-manager  Deleting old Order resource "cm-tls-3433596774"                                                                                                   
        Normal  Generated           2m14s (x3 over 47m)  cert-manager  Generated new private key                                                                                                                         
        Normal  GenerateSelfSigned  2m14s (x3 over 47m)  cert-manager  Generated temporary self signed certificate                                                                                                       
        Normal  OrderCreated        2m14s (x3 over 47m)  cert-manager  Created Order resource "cm-tls-3817114402"                                                                                                        
        Normal  OrderComplete       2m13s (x2 over 47m)  cert-manager  Order "cm-tls-3817114402" completed successfully                                                                                                  
        Normal  CertIssued          2m13s (x3 over 47m)  cert-manager  Certificate issued successfully
      ```

### View additional certificate details

Once complete, cert-manager will have created a secret with the details of the certificate based on the secret used in the ingress resource. You can use the `describe` command as well to see some details:

```console
kubectl describe secret cm-tls
```

This should respond with something similar to:  

```console
Name:         cm-tls                                                                                                                                                                                               
Namespace:    default                                                                                                                                                                                              
Labels:       certmanager.k8s.io/certificate-name=cm-tls                                                                                                                                                           
Annotations:  certmanager.k8s.io/alt-names: chartmuseum.acme.com                                                                                                                                              
              certmanager.k8s.io/common-name: chartmuseum.acme.com                                                                                                                                            
              certmanager.k8s.io/ip-sans:                                                                                                                                                                          
              certmanager.k8s.io/issuer-kind: Issuer                                                                                                                                                               
              certmanager.k8s.io/issuer-name: cm-staging                                                                                                                                                           
                                                                                                                                                                                                                   
Type:  kubernetes.io/tls                                                                                                                                                                                           
                                                                                                                                                                                                                   
Data                                                                                                                                                                                                               
====                                                                                                                                                                                                               
ca.crt:   0 bytes                                                                                                                                                                                                  
tls.crt:  3578 bytes                                                                                                                                                                                               
tls.key:  1679 bytes
```

### Accessing chartmuseum

If you access chartmuseum now, you’ll see a warning:

{% imgx assets/helm-warning-msg.png  "Warning message in browser" %}

If you ignore the warning and go ahead anyway, you'll be able to access chartmuseum except that now you'll be accessing it over HTTPS. Your browser will also warn you that it’s added an exception to this site.

Let's take a look at how to correct this:

1. Edit the `values.yaml` for your chartmuseum again and this time change the `issuer annotation` to *cm-prod*:  

      ```console
      certmanager.k8s.io/issuer: "cm-prod"
      ```

1. Run a helm upgrade again:  

      ```console
      helm upgrade chartmuseum stable/chartmuseum -f values.yaml
      ```

   This should respond with something similar to:  

      ```console
      Release "chartmuseum" has been upgraded. Happy Helming!
      ```

1. Delete the secret:  

      ```console
      kubectl delete secret cm-tls
      ```

   This will cause cert-manager to get a new certificate. You can verify this:  

      ```conosle
      kubectl describe certificate cm-tls
      ```

   This will respond with something similar to:  

      ```console
      .
      .
      .Normal  Generated           33s (x4 over 61m)  cert-manager  Generated new private key                                                                                                                           
        Normal  GenerateSelfSigned  33s (x4 over 61m)  cert-manager  Generated temporary self signed certificate                                                                                                         
        Normal  OrderCreated        33s (x4 over 58m)  cert-manager  Created Order resource "cm-tls-3433596774"                                                                                                          
        Normal  CertIssued          31s (x5 over 61m)  cert-manager  Certificate issued successfully                                                                                                                     
        Normal  OrderComplete       31s (x3 over 57m)  cert-manager  Order "cm-tls-3433596774" completed successfully
      ```

If you now access chartmuseum, you will be able to access it with HTTPS and will not be prompted with the security warning/exception.  

{% imgx assets/helm-chartmuseum-welcome.png  "Chartmuseum welcome message" %}

## What's next

We've covered a lot of ground in this article. Hopefully, you've found this useful!  

At this point, you should be ready to explore all of the features that chartmuseum has to offer. [Chartmuseum](https://chartmuseum.com/) enhances your CI/CD capabilities by:  

* enabling you to host your helm charts privately and securely
* integrating with your CI/CD deployment tool chain and pipelines
* supporting multiple teams and organizations with multitenant capabilities
* using a variety of storage capabilities including local file system, Oracle Object Storage, OpenStack Object storage, and others.

**Running chartmuseum outside of your Kubernetes cluster:**  

If you'd like to run it outside your Kubernetes cluster (like on a VM), you can follow [this guide](https://medium.com/jsonlovesyaml/setup-instructions-chartmuseum-kubeapps-oracle-object-storage-with-oracle-kubernetes-engine-3306d9c005cc) instead.

**Additional information:**

To explore more information about development with Oracle products:  

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)

### References

* [Chartmuseum docs](https://chartmuseum.com/docs/)
* [Chartmuseum helm package docs](https://github.com/helm/charts/tree/master/stable/chartmuseum)
* [cert-manager installation guide]
* [cert-manager with Nginx Ingress](https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html)

<!--- links -->

[OCI Cloud Shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm

[terraform-oci-oke]: https://github.com/oracle-terraform-modules/terraform-oci-oke
[this post]: https://medium.com/oracledevs/provisioning-oracle-container-engine-oke-using-terraform-41542fd15d1c?source=friends_link&sk=efe4c6c36c22bc14c7e9bbff6b343ffb

[this post]: https://medium.com/oracledevs/changing-load-balancer-shape-in-oracle-container-engine-oke-and-updating-dns-with-external-dns-7064f15cf600?source=friends_link&sk=3f539e6f43c3e973492ede35877d15d8

[ExternalDNS]: https://github.com/kubernetes-incubator/external-dns
[nginx-controller]: https://kubernetes.github.io/ingress-nginx/

[the quick-start guide]: https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html

[Cert-Manager installation guide]: https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html
