---
title: Call a Function using API Gateway
categories: [clouddev, cloudapps, enterprise]
description: Using Oracle functions to process data via an Oracle API Gateway, and creating a python function to extract HTTP information.
thumbnail: assets/call-a-func-oracle-funcs-api-gtw-diagram.png
sort: desc
tags: [python, apigateway, oci]
parent: tutorials
date: 2021-11-20 12:01
---
{% slides %}
In this tutorial, you will use Oracle Functions to process data passed from an Oracle API Gateway. You will create a Python function that uses the runtime context to extract HTTP information passed in a request.

Key tasks include how to:

* Gather required information.
* Create an application for your function.
* Create a "Hello World!" function.
* Convert your function to process runtime context data.
* Deploy and test your function.
* Create an API Gateway for your function
* Call your function from the internet using your API Gateway.

{% img assets/call-a-func-oracle-funcs-api-gtw-diagram.png 1200 675 "Cloud diagram" "Oracle Cloud Infrastructure Diagram showing a function executing on the service, the API gateway getting the request and returning the function, with registry in tenancy and VCN within the tenancy allowing access to the Internet" %}

For additional information, see:

* [Start for Free]({{ site.urls.always_free }})
* [Command Line Interface (CLI)](https://docs.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm)
* [Oracle Functions](https://docs.oracle.com/iaas/Content/Functions/Concepts/functionsoverview.htm)
* [Oracle API Gateway](https://docs.oracle.com/iaas/Content/APIGateway/Concepts/apigatewayoverview.htm)

## Before You Begin

To successfully perform this tutorial, you must have the following:

### OCI Account Requirements

* A **paid** Oracle Cloud Infrastructure account. See [Signing Up for Oracle Cloud Infrastructure](https://docs.oracle.com/iaas/Content/GSG/Tasks/signingup.htm). 
* Your OCI account configured to support Oracle Functions development. See [Oracle Functions on Cloud Shell Quickstart](https://www.oracle.com/webfolder/technetwork/tutorials/infographics/oci_functions_cloudshell_quickview/functions_quickview_top/functions_quickview/index.html#).
* Completion of one of the two Oracle Functions introduction tutorials. 
    * [Functions: Get Started using Cloud Shell](https://docs.oracle.com/iaas/developer-tutorials/tutorials/functions/func-setup-cs/01-summary.htm#setup-functions-dev-cs)
    * [Functions: Get Started using the CLI](https://docs.oracle.com/iaas/developer-tutorials/tutorials/functions/func-setup-cli/01-summary.htm#setup-functions-dev)
* Completing one of the two tutorials results in: 
    * Oracle Functions is set up and configured to create applications and deploy functions.
    * Oracle Registry is set up to store function images.
    * Docker is logged into the Oracle Registry.
    * The required VCN and required resources needed for Oracle Functions.
    * An API key pair and an auth token.

### Software Requirements

**Oracle CLI**

* Python 3.6+ and pip3.
* Docker Engine: A Linux computer or Linux VM. See [Docker engine requirements](https://docs.docker.com/engine/install/) for versions, and distros supported.
* Docker Desktop: Available for MacOS or Windows 10. 
    * Windows 10: Windows 10 update 2004 with WSL 2 and Ubuntu or other distro installed. (see [Windows Subsystem for Linux Installation Guide for Windows 10](https://docs.microsoft.com/en-us/windows/wsl/install-win10))
        * [Install Docker Desktop for Windows 10.](https://docs.docker.com/docker-for-windows/install/)

        > **Note:** Docker includes special Linux support for WSL 2 on Windows 10 update 2004.
        {:.notice}

    + MacOS: See [Install Docker Desktop for MacOS.](https://docs.docker.com/docker-for-mac/install/)


**Oracle Cloud Shell**

  * If you use Cloud Shell, the preceding list of software is already installed.

## Gather Required Information

Collect all the information you need to complete the tutorial. Copy the following information into your notepad.

### Get Compartment Information

To create a compartment see [Create a compartment](https://docs.oracle.com/iaas/Content/Identity/Tasks/managingcompartments.htm#To). After your compartment is created, save the compartment OCID and name.

To get the compartment OCID from an existing compartment:

1. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Compartments**.
2. Select your compartment.
3. Click the **Copy** link for the OCID field. 

Save the compartment OCID and name.

### Collected Information

Ensure you have the following information written down for the tutorial.

* **Compartment Name: `<your-compartment-name>`**

    Example: `my-compartment`

* **Compartment ID: `<compartment-OCID>`**

    Example: `ocid1.compartment.oc1.aaaaaaa...`

* **VCN Name:** `<your-vcn-name>`

    Example: `my-vcn`

    Open the navigation menu and click **Networking**, and then click **Virtual Cloud Networks**. From the list of networks, select your VCN.

* **VCN Public Subnet Name:** `<Public-Subnet-your-vcn-name>`

    Example: `Public-Subnet-my-vcn`

    Open the navigation menu and click **Networking**, and then click **Virtual Cloud Networks**. From the list of networks, select your VCN.

## Perform Required Configuration

Next you will configure what you need for the tutorial.

### Create Functions Application

To create application, follow these steps.

1. Open the navigation menu and click **Developer Services**. Under **Functions**, click **Applications**.
2. Select your compartment from the **Compartment** drop-down.
3. Click **Create Application**.
4. Fill in the form data.
    * **Name:** `<your-app-name>`
    * **VCN:** `<your-vcn-name>`
    * **Subnets:** `<Public-Subnet-your-vcn-name>`
5. Click Create.

Your app is created.

### Setup Ingress Rule for HTTPS

1. Open the navigation menu and click **Networking**, and then click **Virtual Cloud Networks**.
2. Click the name of the VCN you used to for your Oracle Functions application.
3. With your new VCN displayed, click your **Public** subnet link. 

    The public subnet information is displayed with the Security Lists at the bottom of the page.

4. Click the Default Security List link or appropriate security list link. 

    The default **Ingress Rules** for your VCN are displayed.

5. Click Add Ingress Rules. 

    An **Add Ingress Rules** dialog is displayed.

6. Fill in the ingress rule with the following information. After all the data is entered, click Add Ingress Rules

    Fill in the ingress rule as follows:

    * **Stateless:** Checked
    * **Source Type:** CIDR
    * **Source CIDR:** 0.0.0.0/0
    * **IP Protocol:** TCP
    * **Source port range:** (leave-blank)
    * **Destination Port Range:** 443
    * **Description:** VCN for applications

    After you click Add Ingress Rule, HTTPS connections are allowed to your **public subnet**.

### Setup Policy for API Gateway Access to Functions

Next, set up a policy which allows API Gateway to invoke functions.

First, create a Dynamic Group for API Gateway.

1. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Dynamic Groups**.
2. Click **Create Dynamic Group**.
3. Fill in the following information to define your dynamic group: 
    * **Name:** `<name-for-your-dynamic-group>`
    * Under **Matching Rules** use **Rule 1:** `<the-rule-text>`

    Here is the sample name and the rule you need to fill out.

    * **Name:** `api-gtw-func-dynamic-group`
    * Under **Matching Rules** use **Rule 1:** `ALL {resource.type = 'ApiGateway', resource.compartment.id = 'ocid1.compartment.<your-compartment-OCID>'}`
4. Click **Create**.

Now create the policy for API Gateway.

1. Open the navigation menu and click **Identity & Security**. Under **Identity**, click **Policies**.
2. Click **Create Policy**.
3. To define your policy, fill in the following information.
    * **Name:** `<name-for-your-policy>`
    * **Description:** `<description-for policy>`
    * **Compartment:** `<name-of-functions-compartment>`

    For the Policy Builder Section

    * Click the **Customize(Advanced)** link.
    * Enter your policy in the text box, for example: 

        ```console
        Allow dynamic-group  api-gtw-func-dynamic-group to use functions-family in compartment <your-compartment-name>
        ```

    > **Note:** The last parameter is the compartment **name**, not the compartment OCID.
        {:.notice}

4. Click **Create**.

You have created a policy to allow API Gateway to use Functions.

### Create "Hello World" Python Function

1. Open a terminal.
2. Create a directory to store your functions and change into that directory.

    ```console
    mkdir my-dir-name
    cd my-dir-name
    ```                       

3. Create a Python "Hello World" function with Fn. 

    ```console
    fn init --runtime python my-func-name
    ```

    This command creates a directory named `my-func-name` with the function and configuration files in it.

4. Change into the directory.
5. Deploy the function. 

    ```console
    fn -v deploy --app your-app-name
    ```

    Various messages are displayed as the Docker images are built, pushed to OCIR, and eventually deployed to Oracle Functions.

6. Invoke the function. 

    ```console
    fn invoke your-app-name my-func-name
    ```

    Returns: `{"message": "Hello World"}`

7. Invoke the function with a parameter. 

    ```console
    echo -n '{"name":"Bob"}' | fn invoke your-app-name my-func-name
    ```

    Returns: `{"message": "Hello Bob"}`

## Create an API Gateway

To call your function, create an API Gateway.

### Create the API Gateway

1. Open the navigation menu and click **Developer Services**. Under **API Management**, click **Gateways**.
2. Select your compartment from the **Compartment** drop-down.
3. Click **Create Gateway**
4. Fill in the following information to define your API Gateway. 
    * **Name:** `<your-gateway-name>`
    * **Type:** `<Public>`
    * **Compartment:** `<your-compartment-name>`
    * **Virtual Cloud Network in `<your-vcn-name>:`** `<select-your-vcn>`
    * **Subnet in `<your-compartment-name>:`** `<your-public-subnet-name>`
5. Click **Create**. Wait a few minutes for your API Gateway to be created.

### Create an API Deployment for your Gateway

1. Click **Deployments** in Resources section on the left side of the screen.
2. Click **Create Deployment**.
3. Ensure that **From Scratch** is selected for the deployment type.
4. To define your deployment, fill in the **Basic Information** section.
    * **Name:** `<your-deployment-name>`
    * **Path Prefix (example):** `/v1`
    * **Compartment:** `<your-compartment-name>`
    * **API Request Policies:** Take default values
    * **API Logging Policies:** Take default value of **Information**
5. Click **Next**. The **Routes** dialog appears with **Route 1** selected.
6. To define your route, fill in the **Route 1** section.
    * **Path:** `<your-route-path>` 
        Example: /http-info
    * **Methods:** GET POST
    * **Type:** Oracle Functions
    * **Application in `<your-compartment-name>`:** Select the Functions application you created.
    * **Function Name:** Select the function you created in the configuration section.
7. Click **Next**. The Review dialog is displayed summarizing the choices you have made.
8. Click **Create**. Your deployment is created.
9. Click the Deployments link for your gateway. Copy the base end point for the deployment you created. 

    For example: `https://aaaaa.apigateway.us-ashburn-X.oci.customer-oic.com/v1`

### Test your API Gateway

With your API Gateway and deployment created, you can now test you installation. Create a simple script for the `curl` command. To create the URL for `curl`, add your deployment path to your endpoint.

1. Create the script file: `touch gtw01.sh && chmod 755 gtw01.sh`
2. Add the command curl command to the script file:

    ```bash
    #!/bin/bash
    curl <your-api-gateway-endpoint>/http-info
    ```

3. The command returns: `{"message":"Hello World"}`

You have connected your API Gateway to a boiler plate Python function. Next, you update your Python function to display information passed in an HTTP request.

  
## Update Function to Access HTTP and Function Data

Next, modify the boiler plate Python function to access the runtime context and display HTTP information.

### Review Starting Python Code

If you look at the boiler plate function, your Python function looks something like this.

```python
import io
import json
import logging

from fdk import response


def handler(ctx, data: io.BytesIO = None):
    name = "World"
    try:
        body = json.loads(data.getvalue())
        name = body.get("name")
    except (Exception, ValueError) as ex:
        logging.getLogger().info('error parsing json payload: ' + str(ex))
    
    logging.getLogger().info("Inside Python Hello World function")
    return response.Response(
       ctx, response_data=json.dumps(
           {"message": "Hello {0}".format(name)}),
       headers={"Content-Type": "application/json"}
    )
```

Using this code as a starting point, the sections that follow convert the function into a Python function that returns HTTP and configuration data.

### Update Required Packages

First, update the function for required packages.

1. Update the `requirements.txt` file for the `oci` package.

    ```console
    fdk
    oci 
    ```                   
                    

2. Update the `import` statements in `func.py` for required packages for the HTTP features: 

    ```python
    import io
    import json
    import oci
    import logging
    from urllib.parse import urlparse, parse_qs
    ```                    

    The `oci` package is required for some of the context requests. The `urlparse, parse_qs` packages are used for parsing.

### Add HTTP Request Information

First, remove the main body of the function. The `response` method and related code are added back as we go.

```python
import io
import json
import oci
import logging
from urllib.parse import urlparse, parse_qs  
                
from fdk import response

def handler(ctx, data: io.BytesIO = None): 
```               

Next add code to display HTTP information in the response. Here is the code with comments following.

```python
import io
import json
import oci
import logging
from urllib.parse import urlparse, parse_qs  
                
from fdk import response

def handler(ctx, data: io.BytesIO = None):
    logging.getLogger().info("HTTP function start")
    
    resp = {}
    
    # retrieving the request headers
    headers = ctx.Headers()
    logging.getLogger().info("Headers: " + json.dumps(headers))
    resp["Headers"] = headers
    
    # retrieving the request body, e.g. {"key1":"value"}
    try:
        requestbody_str = data.getvalue().decode('UTF-8')
        if requestbody_str:
            resp["Request body"] = json.loads(requestbody_str)
        else:
            resp["Request body"] = {}
    except Exception as ex:
        print('ERROR: The request body is not JSON', ex, flush=True)
        raise
    
    # retrieving the request URL, e.g. "/v1/http-info"
    requesturl = ctx.RequestURL()
    logging.getLogger().info("Request URL: " + json.dumps(requesturl))
    resp["Request URL"] = requesturl
    
    # retrieving query string from the request URL, e.g. {"param1":["value"]}
    parsed_url = urlparse(requesturl)
    resp["Query String"] = parse_qs(parsed_url.query)
    logging.getLogger().info("Query string: " + json.dumps(resp["Query String"]))
    
    # retrieving the request method, e.g. "POST", "GET"...
    method = ctx.Method()
    if method:
        logging.getLogger().info("Request Method: " + method)
    resp["Request Method"] = method
    else:
        logging.getLogger().info("No Request Method")
        resp["Request Method"] = None
```

* The `handler` function receives system information about the current request through the `ctx` and `data` parameters.
* All the data is added to the `resp` dictionary which is eventually returned in the response.
* Notice the function runtime context (`ctx`) contains much of the HTTP data passed from a request including: headers, request URL, and method.
* The `data` parameter returns the body of the request.

### Add the Function-related Data to the Response

Next, retrieve Oracle Functions related data from the context and then return a response. Comments follow.

```python
# retrieving the function configuration
resp["Configuration"] = dict(ctx.Config())
logging.getLogger().info("Configuration: " + json.dumps(resp["Configuration"]))

# retrieving the Application ID, e.g. "ocid1.fnapp.oc1.phx.aaaaxxxx"
appid = ctx.AppID()
logging.getLogger().info("AppID: " + appid)
resp["AppID"] = appid

# retrieving the Function ID, e.g. "ocid1.fnfunc.oc1.phx.aaaaxxxxx"
fnid = ctx.FnID()
logging.getLogger().info("FnID: " + fnid)
resp["FnID"] = fnid

# retrieving the Function call ID, e.g. "01E9FE6JBW1BT0C68ZJ003KR1Q"
callid = ctx.CallID()
logging.getLogger().info("CallID: " + callid)
resp["CallID"] = callid

# retrieving the Function format, e.g. "http-stream"
fnformat = ctx.Format()
logging.getLogger().info("Format: " + fnformat)
resp["Format"] = fnformat

# retrieving the Function deadline, e.g. "2020-05-29T05:24:46Z"
deadline = ctx.Deadline()
logging.getLogger().info("Deadline: " + deadline)
resp["Deadline"] = deadline

logging.getLogger().info("function handler end")
return response.Response(
    ctx, 
    response_data=json.dumps(resp),
    headers={"Content-Type": "application/json"}
)
```

Notice all the Functions-related data is retrieved from the `ctx` object including: `AppID`, `FnID`, and`Format`.

### Review Final Function

Here is the final function code.

```python
import io
import json
import oci
import logging
from urllib.parse import urlparse, parse_qs

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    logging.getLogger().info("HTTP function start")
    
    resp = {}
    
    # retrieving the request headers
    headers = ctx.Headers()
    logging.getLogger().info("Headers: " + json.dumps(headers))
    resp["Headers"] = headers
    
    # retrieving the request body, e.g. {"key1":"value"}
    try:
        requestbody_str = data.getvalue().decode('UTF-8')
        if requestbody_str:
            resp["Request body"] = json.loads(requestbody_str)
        else:
            resp["Request body"] = {}
    except Exception as ex:
        print('ERROR: The request body is not JSON', ex, flush=True)
        raise
    
    # retrieving the request URL, e.g. "/v1/http-info"
    requesturl = ctx.RequestURL()
    logging.getLogger().info("Request URL: " + json.dumps(requesturl))
    resp["Request URL"] = requesturl
    
    # retrieving query string from the request URL, e.g. {"param1":["value"]}
    parsed_url = urlparse(requesturl)
    resp["Query String"] = parse_qs(parsed_url.query)
    logging.getLogger().info("Query string: " + json.dumps(resp["Query String"]))
    
    # retrieving the request method, e.g. "POST", "GET"...
    method = ctx.Method()
    if method:
        logging.getLogger().info("Request Method: " + method)
        resp["Request Method"] = method
    else:
        logging.getLogger().info("No Request Method")
        resp["Request Method"] = None
    
    # retrieving the function configuration
    resp["Configuration"] = dict(ctx.Config())
    logging.getLogger().info("Configuration: " + json.dumps(resp["Configuration"]))
    
    # retrieving the Application ID, e.g. "ocid1.fnapp.oc1.phx.aaaaxxxx"
    appid = ctx.AppID()
    logging.getLogger().info("AppID: " + appid)
    resp["AppID"] = appid
    
    # retrieving the Function ID, e.g. "ocid1.fnfunc.oc1.phx.aaaaxxxxx"
    fnid = ctx.FnID()
    logging.getLogger().info("FnID: " + fnid)
    resp["FnID"] = fnid
    
    # retrieving the Function call ID, e.g. "01E9FE6JBW1BT0C68ZJ003KR1Q"
    callid = ctx.CallID()
    logging.getLogger().info("CallID: " + callid)
    resp["CallID"] = callid
    
    # retrieving the Function format, e.g. "http-stream"
    fnformat = ctx.Format()
    logging.getLogger().info("Format: " + fnformat)
    resp["Format"] = fnformat
    
    # retrieving the Function deadline, e.g. "2020-05-29T05:24:46Z"
    deadline = ctx.Deadline()
    logging.getLogger().info("Deadline: " + deadline)
    resp["Deadline"] = deadline
    
    logging.getLogger().info("function handler end")
    return response.Response(
        ctx, 
        response_data=json.dumps(resp),
        headers={"Content-Type": "application/json"}
    )
```       

You are now ready to retest you function and see the results.

### Create Functions Configuration Variables

Oracle Functions allows you to store configuration data in your context that is available in your request. Configuration data can be stored in an application or a function. The following commands store database information in the application context.

* `fn config app <your-app-name> DB-NAME your-db-name`
* `fn config app <your-app-name> DB-USER your-user-name`

For more information, see [Fn Project's tutorial on runtime context](https://fnproject.io/tutorials/basics/UsingRuntimeContext/).

### Test your Function

1. Redeploy the updated function.
2. Invoke the function to ensure that the function is working.
3. Run your script again. To get formatted JSON output, use the `jq` utility which is included with the cloud shell. If you are using the CLI, install `jq` on your local machine. 

    `gtw01.sh | jq`

    The data returned is similar to:

    ```json
    {
        "Headers": {
        "host": [
        "localhost",
        "ctr6kqbjpza5tjnzafaqpqif5i.apigateway.us-phoenix-1.oci.customer-oci.com"
        ],
        "user-agent": [
        "lua-resty-http/0.14 (Lua) ngx_lua/10015",
        "curl/7.64.1"
        ],
        "transfer-encoding": "chunked",
        "content-type": [
        "application/octet-stream",
        "application/octet-stream"
        ],
        "date": "Thu, 10 Dec 2020 01:35:43 GMT",
        "fn-call-id": "01ES54MAKK1BT0H50ZJ00NGX00",
        "fn-deadline": "2020-12-10T01:36:13Z",
        "accept": "*/*",
        "cdn-loop": "iQPgvPk4HZ74L-PRJqYw7A",
        "forwarded": "for=73.34.74.159",
        "x-forwarded-for": "73.34.74.159",
        "x-real-ip": "73.34.74.159",
        "fn-http-method": "GET",
        "fn-http-request-url": "/v1/http-info",
        "fn-intent": "httprequest",
        "fn-invoke-type": "sync",
        "oci-subject-id": "ocid1.apigateway.oc1.phx.0000000000000000000000000000000000000000000000000000",
        "oci-subject-tenancy-id": "ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "oci-subject-type": "resource",
        "opc-request-id": "/A79EAB4A240E93EB226366B190A494BC/01ES54MAK21BT0H50ZJ00NGWZZ",
        "x-content-sha256": "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=",
        "accept-encoding": "gzip"
        },
        "Configuration": {
        "PATH": "/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "HOSTNAME": "7747cc436a14",
        "FN_LISTENER": "unix:/tmp/iofs/lsnr.sock",
        "FN_CPUS": "125m",
        "FN_LOGFRAME_NAME": "01ES54E5RN00000000000001JF",
        "FN_LOGFRAME_HDR": "Opc-Request-Id",
        "FN_FORMAT": "http-stream",
        "DB-NAME": "your-db-name",
        "DB-USER": "your-user-name",
        "FN_APP_ID": "ocid1.fnapp.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "FN_FN_ID": "ocid1.fnfunc.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "FN_MEMORY": "256",
        "FN_TYPE": "sync",
        "OCI_RESOURCE_PRINCIPAL_RPST": "/.oci-credentials/rpst",
        "OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM": "/.oci-credentials/private.pem",
        "OCI_RESOURCE_PRINCIPAL_VERSION": "2.2",
        "OCI_RESOURCE_PRINCIPAL_REGION": "us-phoenix-1",
        "OCI_REGION_METADATA": "{\"realmDomainComponent\":\"oraclecloud.com\",\"realmKey\":\"oc1\",\"regionIdentifier\":\"us-phoenix-1\",\"regionKey\":\"PHX\"}",
        "LANG": "C.UTF-8",
        "GPG_KEY": "E3FF2839C048B25C084DEBE9B26995E310250568",
        "PYTHON_VERSION": "3.8.5",
        "PYTHON_PIP_VERSION": "20.2.2",
        "PYTHON_GET_PIP_URL": "https://github.com/pypa/get-pip/raw/5578af97f8b2b466f4cdbebe18a3ba2d48ad1434/get-pip.py",
        "PYTHON_GET_PIP_SHA256": "d4d62a0850fe0c2e6325b2cc20d818c580563de5a2038f917e3cb0e25280b4d1",
        "PYTHONPATH": "/function:/python",
        "HOME": "/home/fn"
        },
        "Request body": {},
        "Request URL": "/v1/http-info",
        "Query String": {},
        "Request Method": "GET",
        "AppID": "ocid1.fnapp.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "FnID": "ocid1.fnfunc.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "CallID": "01ES54MAKK1BT0H50ZJ00NGX00",
        "Format": "http-stream",
        "Deadline": "2020-12-10T01:36:13Z"
        }
    ```

    Notice all the Functions data returned in the second half of the response including: `AppID`, `FnID`, and `Format`. In addition, in the `Configuration` section you see the Functions-generated environment variables like `FN_FORMAT` and the configuration variables: `DB-NAME` and `DB-USER`.

4. Update your script to pass headers and `POST` data to the script. 

    ```bash
    /bin/bash
    curl -X POST --header "X-MyHeader1: headerValue" -d '{"key1":"value"}' https://aaaaa.apigateway.us-ashburn-X.oci.customer-oic.com/v1/http-info
    ```

    The output from the script looks similar to:

    ```json
    {
        "Headers": {
        "host": [
        "localhost",
        "ctr6kqbjpza5tjnzafaqpqif5i.apigateway.us-phoenix-1.oci.customer-oci.com"
        ],
        "user-agent": [
        "lua-resty-http/0.14 (Lua) ngx_lua/10015",
        "curl/7.64.1"
        ],
        "transfer-encoding": "chunked",
        "content-type": [
        "application/x-www-form-urlencoded",
        "application/x-www-form-urlencoded"
        ],
        "date": "Thu, 10 Dec 2020 17:05:14 GMT",
        "fn-call-id": "000000000000000000000000000",
        "fn-deadline": "2020-12-10T17:05:44Z",
        "accept": "*/*",
        "cdn-loop": "iQPgvPk4HZ74L-PRJqYw7A",
        "content-length": "16",
        "forwarded": "for=73.34.74.159",
        "x-forwarded-for": "73.34.74.159",
        "x-myheader1": "headerValue",
        "x-real-ip": "73.34.74.159",
        "fn-http-method": "POST",
        "fn-http-request-url": "/v1/http-info",
        "fn-intent": "httprequest",
        "fn-invoke-type": "sync",
        "oci-subject-id": "ocid1.apigateway.oc1.phx.0000000000000000000000000000000000000000000000000000",
        "oci-subject-tenancy-id": "ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "oci-subject-type": "resource",
        "opc-request-id": "/32DE93ED4A72B932E62460362A24DA40/01ES6STAH91BT0G48ZJ00J07ZT",
        "x-content-sha256": "xMAO2Qww/EVSr1CsSxtHsZu9VicSjb2EMvMmDMjZcVA=",
        "accept-encoding": "gzip"
        },
        "Configuration": {
        "PATH": "/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "HOSTNAME": "1afb03686740",
        "FN_LISTENER": "unix:/tmp/iofs/lsnr.sock",
        "FN_CPUS": "125m",
        "FN_APP_ID": "ocid1.fnapp.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "FN_FN_ID": "ocid1.fnfunc.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "FN_MEMORY": "256",
        "FN_TYPE": "sync",
        "FN_FORMAT": "http-stream",
        "DB-NAME": "your-db-name",
        "DB-USER": "your-user-name",
        "FN_LOGFRAME_NAME": "01ES6SSJY600000000000000BF",
        "FN_LOGFRAME_HDR": "Opc-Request-Id",
        "OCI_RESOURCE_PRINCIPAL_RPST": "/.oci-credentials/rpst",
        "OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM": "/.oci-credentials/private.pem",
        "OCI_RESOURCE_PRINCIPAL_VERSION": "2.2",
        "OCI_RESOURCE_PRINCIPAL_REGION": "us-phoenix-1",
        "OCI_REGION_METADATA": "{\"realmDomainComponent\":\"oraclecloud.com\",\"realmKey\":\"oc1\",\"regionIdentifier\":\"us-phoenix-1\",\"regionKey\":\"PHX\"}",
        "LANG": "C.UTF-8",
        "GPG_KEY": "E3FF2839C048B25C084DEBE9B26995E310250568",
        "PYTHON_VERSION": "3.8.5",
        "PYTHON_PIP_VERSION": "20.2.2",
        "PYTHON_GET_PIP_URL": "https://github.com/pypa/get-pip/raw/5578af97f8b2b466f4cdbebe18a3ba2d48ad1434/get-pip.py",
        "PYTHON_GET_PIP_SHA256": "d4d62a0850fe0c2e6325b2cc20d818c580563de5a2038f917e3cb0e25280b4d1",
        "PYTHONPATH": "/function:/python",
        "HOME": "/home/fn"
        },
        "Request body": {
        "key1": "value"
        },
        "Request URL": "/v1/http-info",
        "Query String": {},
        "Request Method": "POST",
        "AppID": "ocid1.fnapp.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "FnID": "ocid1.fnfunc.oc1.phx.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "CallID": "000000000000000000000000000",
        "Format": "http-stream",
        "Deadline": "2020-12-10T17:05:44Z"
        }
    ```

    Note the header data and the request body data. The key/value JSON data is listed under the "Request Body" section. You can download the complete source code for the function from the [Oracle Function Samples site here](https://github.com/oracle/oracle-functions-samples/tree/master/samples/oci-apigw-display-httprequest-info-python).

Congratulations! You have converted the boiler plate Python function into a new function that returns HTTP and Oracle Function data. The function demonstrates how data can be passed to API Gateway and processed in a function.

## What's Next

You have successfully created an API Gateway and called a function from it. You updated the function to display HTTP and Oracle Function data.

To explore more information about development with Oracle products, check out these sites:

* [Oracle Developers Portal](https://developer.oracle.com/)
* [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
* [Oracle Functions](https://docs.oracle.com/iaas/Content/Functions/Concepts/functionsoverview.htm)
* [Oracle API Gateway](https://docs.oracle.com/iaas/Content/APIGateway/Concepts/apigatewayoverview.htm)
 {% endslides %}
