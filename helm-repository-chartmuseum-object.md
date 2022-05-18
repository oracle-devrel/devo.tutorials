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
---
In another article, we deployed a helm chart (Redis) into Oracle Container Engine (OKE) which we pulled from the stable repository. By default, the stable repo is hosted at [here](https://kubernetes-charts.storage.googleapis.com/). 

We can also manually add the [incubator repository](https://github.com/helm/charts/tree/master/incubator) if we want to:

```console
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
"incubator" has been added to your repositories
```

The container images in those repositories are also publicly available (for example, the default image for redis is bitnami/redis in bitnami’s container redis repository on Dockerhub).

We have already described how to host the container images privately on Oracle Registry Service (OCIR). What if we want to do the same for our helm charts?

Fortunately, there is a solution for that too. 

Let me introduce you to chartmuseum, an open source Helm Chart Repository server with support for various cloud storage backends, including OCI Object Storage.

## Prerequisites

You’re using the [terraform-oci-oke](https://github.com/oracle-terraform-modules/terraform-oci-oke) project to provision your OKE cluster. See [this post](https://medium.com/oracledevs/provisioning-oracle-container-engine-oke-using-terraform-41542fd15d1c?source=friends_link&sk=efe4c6c36c22bc14c7e9bbff6b343ffb) for more details. Below is an architecture of what we’ll build:

{% imgx assets/helm-network-diagram.png  "Deploying chartmuseum on OCI" %}

If you don't yet have an OCI account, you can quickly sign up for one today by registering for an [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/#always-free) account. 

Afterwards, check [developer.oracle.com](https://developer.oracle.com) for more developer content.

## Install nginx-controller

First, follow [this post](https://medium.com/oracledevs/changing-load-balancer-shape-in-oracle-container-engine-oke-and-updating-dns-with-external-dns-7064f15cf600?source=friends_link&sk=3f539e6f43c3e973492ede35877d15d8) to install [ExternalDNS](https://github.com/kubernetes-incubator/external-dns).

Then, let’s install [nginx-controller](https://kubernetes.github.io/ingress-nginx/):

```console
helm install --name nginxcontroller stable/nginx-ingress \
--set controller.name=controller \
--set defaultBackend.enabled=true \
--set defaultBackend.name=defaultbackend \
--set rbac.create=true \
--set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"=chartmuseum.acme.com
```

Replace chartmuseum.acme.com by your preferred hostname. We’ll then use this to access chartmuseum later.

Verify that an OCI Load Balancer has been created and a DNS "A" record has been inserted in the DNS Zone.

## Create OCI Bucket

In the OCI Console, navigate to Object Storage and create a bucket called ‘chartmuseum’:

{% imgx assets/helm-chartmuseum-bucket.png  "chartmuseum bucket window" %}

## Deploy chartmuseum

We want a similar experience to the stable or incubator repos i.e. anonymous `GET` but protected `POST` requests and we will use Basic Auth for authentication purposes.

Let’s first create a secret to hold the Basic Auth username and password:

```console
kubectl create secret generic chartmuseum-auth --from-literal=user=curator --from-literal=pass=password
```

You also need to create a second secret that will allow chartmuseum to communicate with the OCI APIs.

Temporarily, copy your API keys to the bastion. You can also do this locally if you have `kubectl` and access to the kubeconfig locally.

Create a file ‘config’:

```console
[DEFAULT]                                           
user=<USER_OCID>                                                                                    
fingerprint=<API_KEY_FINGERPRINT>
key_file=/home/chartmuseum/.oci/oci.key                         
tenancy=<TENANCY_OCID>
region=<REGION>
```

Enter your user and tenancy OCIDs, api key fingerprint and region value. The key_file value has to be `/home/chartmuseum/.oci/oci.key`.

Next, create the secret:

```console
kubectl create secret generic chartmuseum-secret --from-file=config="/path/to/config" --from-file=key_file="/path/to/apikey.pem"
```

Replace with the appropriate absolute or relative path to the config file and private API key.

Next, download the chartmuseum values file:

```console
curl -o values.yaml https://raw.githubusercontent.com/helm/charts/master/stable/chartmuseum/values.yaml
```

Edit the values.yaml file and replace the parameters as follows:

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

We can now install chartmuseum:

```console
helm install --name=chartmuseum -f values.yaml stable/chartmuseum
```

Wait for the pod to run:

```console
kubectl get pods -wNAME                                                            READY   STATUS    RESTARTS   AGE                                                                      
chartmuseum-chartmuseum-748c8dbbd8-7nctc                        1/1     Running   0          5m20s
```

Verify that the ingress has been created:

```console
kubectl get ingNAME                      HOSTS                       ADDRESS   PORTS   AGE                                                                                           
chartmuseum-chartmuseum   chartmuseum.acme.com             80      7m9s
```

And that it maps to the chartmuseum service:

```console
k describe ing chartmuseum-chartmuseum                                                                                                     
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

Finally, you can verify whether you can [reach chartmuseum publicly](http://chartmuseum.acme.com) with your browser.

{% imgx assets/helm-chartmuseum-welcome-msg.png  "Chartmuseum welcome message" %}

### Pushing a chart to Chartmuseum

Install the helm push plugin:

```console
helm plugin install https://github.com/chartmuseum/helm-push
```

Next, add the repo:

```console
helm repo add --username curator --password password cm http://chartmuseum.acme.com/
```

Let’s first create a basic chart which we can use to test:

```console
helm create mycharthelm package mychart
Successfully packaged chart and saved it to: /home/opc/chart/mychart-0.1.0.tgz
```

Now, we can push the chart:

```console
helm push mychart cmPushing mychart-0.1.0.tgz to cm...                                                                                                                                    
Done.
```

If we search for mychart, we will only find the local copy:

```console
helm search mychart                                                                                                                              
NAME            CHART VERSION   APP VERSION     DESCRIPTION                                                                                                           
local/mychart   0.1.0           1.0             A Helm chart for Kubernetes
```

Let’s do a repo update:

```console
helm repo update cm                                                                                                                              
Hang tight while we grab the latest from your chart repositories...                                                                                                   
...Skip local chart repository                                                                                                                                        
...Successfully got an update from the "cm" chart repository                                                                                                          
...Successfully got an update from the "stable" chart repository                                                                                                      
Update Complete. ⎈ Happy Helming!⎈
```

And a new search:

```console
helm search mychart                                                                                                                              
NAME            CHART VERSION   APP VERSION     DESCRIPTION                                                                                                           
cm/mychart      0.1.0           1.0             A Helm chart for Kubernetes                                                                                           
local/mychart   0.1.0           1.0             A Helm chart for Kubernetes
```

The new chart appears.

## Testing authentication

We could remove the repo and add it again without the username and password to test. However, we will use Postman and chartmuseum’s APIs to test. This is the behaviour we want:

* `GET`: No Auth Required
* `POST`: Auth Required
* `DELETE`: Auth Required

{% imgx assets/helm-get-request-w-chartmuseum.png  "GET (without authentication)" %}

You can see we are able to get a list of charts using `GET` without authentication. 

However, a `DELETE` or `POST` without authentication fails:

{% imgx assets/helm-chartmuseum-unauth-request.png  "Unauthorized chart deletion" %}

Yet another twist: when we enter the credentials, the chart deletion succeeds:

{% imgx assets/helm-chartmuseum-good-request.png  "Successful chart deletion" %}

If we now check OCI Object Storage, we can see our chart there:

{% imgx assets/helm-oci-dash.png  "OCI dashboard displaying Chartmuseum details " %}

## Let’s Encrypt

Now that our chartmuseum is up and running, we want to also secure its usage by encrypting traffic. We will use Let’s Encrypt and cert-manager, “a add-on to automate the management and issuance of TLS certificates from various issuing sources.”

You can follow the guide to install cert-manager or read on.

First, create the CustomResourceDefinitions, a namespace for cert-manager and disable resource validation on the namespace:

```console
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yamlkubectl create namespace cert-managerkubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

Add the Jetpack Helm repo and update:

```console
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
```

Install the cert-manager using its helm chart:

```console
helm install --name cert-manager --namespace cert-manager \
```

Verify the installation:

```console
kubectl get pods --namespace cert-manager                                                                                                                                    
NAME                                       READY   STATUS    RESTARTS   AGE                                                                                                                   
cert-manager-776cd4f499-98vsh              1/1     Running   0          3h14m                                                                                                                 
cert-manager-cainjector-744b987848-pkk5s   1/1     Running   0          3h14m                                                                                                                 
cert-manager-webhook-645c7c4f5f-4mbjd      1/1     Running   0          3h14m
```

Test the webhook works by creating a `test-resources.yaml` file.


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

Let's create the test resources:

```console
kubectl create -f test-resources.yaml
```

Check the status of the newly-created certificate:

```console
kubectl describe certificate -n cert-manager-testName:         selfsigned-cert                                                                                                                                                                 
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

You can delete the test resources after testing:

```console
kubectl delete -f test-resources.yaml
```

### Configuring Let’s Encrypt Issuers

For reference, you can follow [the quick-start guide](https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html) for using cert-manager with Nginx Ingress.

Let’s start with creating a staging issuer by creating a staging-issuer.yaml:

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

Replace your email address above.

Create the staging issuer:

```console
kubectl create -f staging-issuer.yaml                                                                                                                                    
issuer.certmanager.k8s.io/cm-staging created
```

Repeat the above but for production pursposes by creating a `production-issuer.yaml`:

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

As above, ensure you provide your email address and create the issuer:

```console
kubectl create -f production-issuer.yaml
```

Check the status of the staging issuer:

```console
kubectl describe issuer cm-stagingName:         cm-staging                                                                                                                                                                      
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
    Server:  https://acme-staging-v02.api.letsencrypt.org/directory                                                                                                                           
Status:                                                                                                                                                                                       
  Acme:                                                                                                                                                                                       
    Uri:  https://acme-staging-v02.api.letsencrypt.org/acme/acct/9718789                                                                                                                      
  Conditions:                                                                                                                                                                                 
    Last Transition Time:  2019-06-25T03:28:17Z                                                                                                                                               
    Message:               The ACME account was registered with the ACME server                                                                                                               
    Reason:                ACMEAccountRegistered                                                                                                                                              
    Status:                True                                                                                                                                                               
    Type:                  Ready                                                                                                                                                              
Events:
```

## Enable TLS on chartmuseum

**Edit** your values.yaml file for chartmuseum and look for the Ingress section. Pay special attention to the added configuration commands.

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

Upgrade your helm chart:

```console
helm upgrade chartmuseum stable/chartmuseum -f values.yamlRelease "chartmuseum" has been upgraded. Happy Helming!
```

Cert-manager will read the annotations and create a certificate:

```console
kubectl get certificate                                                                                                                                            
NAME        READY   SECRET      AGE                                                                                                                                                           
cm-tls      True    cm-tls      45m
```

Take a quick peak at the certificate:

```console
kubectl describe certificate cm-tlsName:         cm-tls                                                                                                                                                                                               
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

Once complete, cert-manager will have created a secret with the details of the certificate based on the secret used in the ingress resource. You can use the `describe` command as well to see some details:

```console
kubectl describe secret cm-tls                                                                                                                                                                
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

If you access chartmuseum now, you’ll see a warning:

{% imgx assets/helm-warning-msg.png  "Warning message in browser" %}

If you ignore the warning and go ahead anyway, you will be able to access chartmuseum except that now you will be accessing it over https. Your browser will also warn you that it’s added an exception to this site.

Edit the values.yaml for your chartmuseum again and this time change the issuer annotation to cm-prod:

```console
certmanager.k8s.io/issuer: "cm-prod"
```

Run a helm upgrade again:

```console
helm upgrade chartmuseum stable/chartmuseum -f values.yamlRelease "chartmuseum" has been upgraded. Happy Helming!
```

and delete the secret:

```console
kubectl delete secret cm-tls
```

This will cause cert-manager to get a new certificate. You can verify this:

```conosle
kubectl describe certificate cm-tls
.
.
.Normal  Generated           33s (x4 over 61m)  cert-manager  Generated new private key                                                                                                                           
  Normal  GenerateSelfSigned  33s (x4 over 61m)  cert-manager  Generated temporary self signed certificate                                                                                                         
  Normal  OrderCreated        33s (x4 over 58m)  cert-manager  Created Order resource "cm-tls-3433596774"                                                                                                          
  Normal  CertIssued          31s (x5 over 61m)  cert-manager  Certificate issued successfully                                                                                                                     
  Normal  OrderComplete       31s (x3 over 57m)  cert-manager  Order "cm-tls-3433596774" completed successfully
```

If you now access chartmuseum, you will be able to access it with https and will not be prompted with the security warning/exception.

{% imgx assets/helm-chartmuseum-welcome.png  "Chartmuseum welcome message" %}

## Conclusion
[Chartmuseum](https://chartmuseum.com/) enhances your CI/CD capabilities in a number of ways:

* enables you to host your helm charts privately and securely
* integrates with your CI/CD deployment tool chain and pipelines
* supports multiple teams and organizations with multitenant capabilities
* uses a variety of storage capabilities including local file system, Oracle Object Storage, OpenStack Object storage, and others.

If you want to run it outside your Kubernetes cluster (like on a VM), you can follow [this guide](https://medium.com/jsonlovesyaml/setup-instructions-chartmuseum-kubeapps-oracle-object-storage-with-oracle-kubernetes-engine-3306d9c005cc) instead.

I hope you've found this useful!

### References:

* [Chartmuseum docs](https://chartmuseum.com/docs/)
* [Chartmuseum helm package docs](https://github.com/helm/charts/tree/master/stable/chartmuseum)
* [Cert-Manager installation guide](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)
* [Cert-Manager with Nginx Ingress](https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html)
