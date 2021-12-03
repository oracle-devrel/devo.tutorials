---
title: Deploying A Multi-Cluster Verrazzano On Oracle Container Engine for Kubernetes (OKE) Part 2
parent: [tutorials, multi-cluster-verrazzano-oke]
tags: [open-source, oke, kubernetes, verrazzano, terraform, devops]
categories: [cloudapps, opensource]
thumbnail: assets/verrazzano-logo.png
date: 2021-12-3 09:11
description: How to deploy Verrazzano an OKE cluster.
color: purple
mrm: WWMK211123P00031
author: ali-mukadam
---
{% imgx alignright assets/verrazzano-logo.png 400 400 "Verrazzano Logo" %}

In [Part 1](2-deploy-multi-cluster-verrazzano-oke), we discussed setting up the network infrastructure for a multi-cluster [Verrazzano](https://verrazzano.io/) deployment. Earlier, we focused on deploying Verrazzano on [Oracle Container Engine (OKE)](1-deploying-verrazzano-on-oke). In this article, we will configure the clusters so they behave as a kind of global cluster. Below is the multi-clustering process depicted graphically:

{% imgx aligncenter assets/vNjGKLaGatczobm2O5Ycdw.png 1076 630 "Verrazzano multi-cluster deployment and registration process" "Verrazzano multi-cluster deployment and registration process" %}

Recall that a Verrazzano multi-cluster has 1 Admin cluster and 1 or more managed clusters and that each Verrazzano cluster is a Kubernetes cluster:

{% imgx aligncenter assets/5i_215fK15AiaYSz.png 535 413 "Verrazzano multi-cluster architecture" "Verrazzano multi-cluster architecture" %}

Also, remember we have the following setup:

{% imgx aligncenter assets/695/bF77x66gHN42zsW_2_9Dxw.png 695 554 "Remote peering with different regions" "Remote peering with different regions using star architecture for managed clusters" %}

Plus, we chose the Admin server to be in the Singapore OCI region.

We will install Verrazzano with dev/prod profile on the Admin cluster and with managed-cluster profile on the managed clusters.

### Note on using kubectx

In the commands below, I use kubectx to set the Kubernetes context where a context is equivalent to a Kubernetes cluster. Strictly speaking that’s not true but it serves our purpose here. Since we have 1 Admin servers and 3 managed servers in 4 different regions, we have 4 different contexts:

{% imgx aligncenter assets/8IaaB1P-hc9P6vjffKZaDA.png 700 121 "Verifying your Kubernetes context" "Verifying your Kubernetes context" %}

To ensure we are always using the correct context, I execute the `kubectx <context-name>` before every command.

## Installing Verrazzano as Admin

Installing Verrazzano as the Admin cluster is straightforward. You follow the [quickstart guide](https://verrazzano.io/docs/quickstart/) and you can choose between the dev/prod profile. On the operator host, ensure your context is pointing to “admin”:

{% imgx aligncenter assets/700/8IaaB1P-hc9P6vjffKZaDA.png 700 121 "Verifying your Kubernetes context" "Verifying your Kubernetes context" %}


If it’s pointing to one of the other clusters, change it as follows:

```console
kubectx admin
```

We can now begin the installation:

```console
kubectl apply -f https://github.com/verrazzano/verrazzano/releases/download/v1.0.3/operator.yaml
```

Wait for the deployment to finish:

```console
kubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
```

And confirm the operator pods are working correctly:

```console  
[opc@v8o-operator ~]$  kubectl -n verrazzano-install get pods
NAME                                            READY   STATUS    RESTARTS   AGE
verrazzano-platform-operator-54cf56884f-46zzk   1/1     Running   0          91s
```

Next, install Verrazzano:
 
```console   
kubectl apply -f - <<EOF  
apiVersion: install.verrazzano.io/v1alpha1  
kind: Verrazzano  
metadata:  
    name: admin  
spec:  
    profile: dev  
EOF
```

Now we need to wait until the installation is complete:
    
```console
kubectl wait \  
    --timeout=20m \  
    --for=condition=InstallComplete \  
    verrazzano/admin
```

This will take a while. In the meantime, let’s install Verrazzano on the managed clusters.

## Installing Verrazzano on managed clusters

Change the context to 1 of the managed clusters and install the operator again e.g.
 
```console
kubectx sydneykubectl apply -f https://github.com/verrazzano/verrazzano/releases/download/v1.0.3/operator.yamlkubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
```

Repeat the above for all the managed clusters. Before running in each managed cluster, ensure you have changed your context with kubectx `<contextname>` as above.

Using the same procedure as for the Admin region, verify that the Verrazzano operator has been successfully installed.

Now, install Verrazzano for each using the managed profile by changing the context and name accordingly:

```console   
apiVersion: install.verrazzano.io/v1alpha1  
kind: Verrazzano  
metadata:  
    name: sydney  
spec:  
    profile: managed-cluster
```

## Verifying the Admin cluster and managed clusters

While the managed clusters are being installed, let’s see if we can [access the various consoles](https://verrazzano.io/docs/operations/). Ensure you can login into the Verrazzano and Rancher consoles.

Change the context again and verify:

```console
kubectx sydneykubectl wait \  
    --timeout=20m \  
    --for=condition=InstallComplete \  
    verrazzano/sydney
```

Repeat the verification for each managed cluster.

## Registering the managed clusters

Verify the the CA certificate type for each managed cluster:
    
```console
kubectx sydneykubectl -n verrazzano-system get secret system-tls -o jsonpath='{.data.ca\.crt}'
```

If this value is empty, then your managed cluster is using certificates signed by a well-known certificate authority and you can generate a secret containing the CA certificate in YAML format. If it’s not empty, then the certificate is self-signed and needs to be extracted. Refer to the workflow at the beginning of this article.

```console
kubectx $sydneyCA_CERT=$(kubectl \  
    get secret system-tls \  
    -n verrazzano-system \  
    -o jsonpath="{.data.ca\.crt}" | base64 --decode)kubectl create secret generic "ca-secret-sydney" \  
  -n verrazzano-mc \  
  --from-literal=cacrt="$CA_CERT" \  
  --dry-run=client -o yaml > managedsydney.yaml
```

Repeat the above for the 2 other regions replacing the region/context and filenames accordingly.

Create 3 secrets on the Admin cluster that contains the CA certificate for each managed cluster:

```console
kubectx adminkubectl apply -f managedsydney.yaml  
kubectl apply -f managedmumbai.yaml  
kubectl apply -f managedtokyo.yaml
```

Get the cluster name for the Admin Cluster:
    
```console
kubectl config get contexts
```

{% imgx aligncenter assets/AHjsVsuj0gcjB0RNKCNVIQ.png 700 132 "Cluster names" "Cluster names" %}

Get the API Server address for the Admin server:
 
```console   
kubectx adminexport CLUSTER_NAME="cluster-cillzxw34tq"API_SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
```

Create a ConfigMap that contains the Admin cluster’s API server address:

```console
kubectx adminkubectl apply -f <<EOF -  
apiVersion: v1  
kind: ConfigMap  
metadata:  
  name: verrazzano-admin-cluster  
  namespace: verrazzano-mc  
data:  
  server: "${API_SERVER}"  
EOF
```

Create the VerrazzanoManagedCluster object for each managed cluster:

```console  
kubectx admin  
kubectl apply -f <<EOF -  
apiVersion: clusters.verrazzano.io/v1alpha1  
kind: VerrazzanoManagedCluster  
metadata:  
  name: sydney  
  namespace: verrazzano-mc  
spec:  
  description: "Sydney VerrazzanoManagedCluster object"  
  caSecret: ca-secret-sydney  
EOFkubectl apply -f <<EOF -  
apiVersion: clusters.verrazzano.io/v1alpha1  
kind: VerrazzanoManagedCluster  
metadata:  
  name: mumbai  
  namespace: verrazzano-mc  
spec:  
  description: "Mumbai VerrazzanoManagedCluster object"  
  caSecret: ca-secret-mumbai  
EOFkubectl apply -f <<EOF -  
apiVersion: clusters.verrazzano.io/v1alpha1  
kind: VerrazzanoManagedCluster  
metadata:  
  name: tokyo  
  namespace: verrazzano-mc  
spec:  
  description: "Tokyo VerrazzanoManagedCluster object"  
  caSecret: ca-secret-tokyo  
EOF
```

Wait for the VerrazzanoManagedCluster resource to reach the Ready status:
   
```console 
kubectx adminkubectl wait --for=condition=Ready \  
    vmc sydney -n verrazzano-mckubectl wait --for=condition=Ready \  
    vmc sydney -n verrazzano-mckubectl wait --for=condition=Ready \  
    vmc sydney -n verrazzano-mc
```

Export a YAML file created to register the managed cluster:
    
```console
kubectx adminkubectl get secret verrazzano-cluster-sydney-manifest \  
    -n verrazzano-mc \  
    -o jsonpath={.data.yaml} | base64 --decode > registersydney.yamlkubectl get secret verrazzano-cluster-mumbai-manifest \  
    -n verrazzano-mc \  
    -o jsonpath={.data.yaml} | base64 --decode > registermumbai.yamlkubectl get secret verrazzano-cluster-tokyo-manifest \  
    -n verrazzano-mc \  
    -o jsonpath={.data.yaml} | base64 --decode > registertokyo.yaml
```

On each managed cluster, apply the registration file:

```console
kubectx sydney  
kubectl apply -f registersydney.yamlkubectx mumbai  
kubectl apply -f registermumbai.yamlkubectx tokyo  
kubectl apply -f registertokyo.yaml
```

Now verify whether the registration completed successfully:

```console    
kubectx admin  
kubectl get vmc sydney -n verrazzano-mc -o yaml  
kubectl get vmc mumbai -n verrazzano-mc -o yaml  
kubectl get vmc tokyo -n verrazzano-mc -o yaml
```

## Additional verifications

Navigate to the Verrazzano console, login and you should be able to see all 3 clusters:

{% imgx aligncenter assets/oMn_S0wntkkEmuuPf-3JBw.png 700 403 "Managed clusters in Verrazzano" "Managed clusters in Verrazzano" %}

Similarly, on the Rancher console, you should be able to see all 4 clusters:
{% imgx aligncenter assets/v3E0CZxe1nF3Ni80qCB7tg.png 700 173 "Admin and managed clusters in Rancher" "Admin and managed clusters in Rancher" %}

"local" is the Admin cluster whereas the others are the managed clusters.

## Conclusion

This concludes the exercise of connecting the OKE clusters deployed in different regions into a multi-cluster Verrazzano deployment. Note that in this post, we did not configure things like DNS, Certificates, Ingress Controller etc. Our aim is to get the multi-cluster configuration going. In a future post, we will look at those other things as well.
