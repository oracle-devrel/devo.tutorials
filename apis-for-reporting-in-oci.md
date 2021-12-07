---
title: APIs for Reporting in OCI
parent: tutorials
tags: [oci, backend]
date: 2020-12-16 14:32
description: Access more even more insight into your environment using these advanced tools for reporting–OCI console, OCI command line tool, and Python APIs.
thumbnail: assets/reporting-welcome-fish.png
author: 
    name: Paul Guerin
    bio: Paul Guerin is a consultant of Oracle Technology.
---
{% imgx assets/reporting-gradient-w-pattern.png "Red and blue gradient with pattern" %}

Let's just say it up front: Oracle Cloud is comprehensively setup for engagement using APIs.

The simplest case is perhaps determining client clock skew:

```bash
$ curl -s --head https://iaas.ap-sydney-1.oraclecloud.com | grep Date
```
{% imgx assets/reporting-welcome-fish.png "Terminal including a welcome message to fish, in the prompt" %}

But in this article, we’ll examine the more advanced methods for reporting.

Specifically, let's checkout three cost analysis methods for reporting, all available in the Oracle Free Tier: 

* OCI console
* OCI command line tool
* Python APIs

## Report from the OCI console

To get an overview of cost analysis from the console, select the **Cost** option from the **Show** dropdown menu:

{% imgx assets/reporting-cost-analysis-dash.png "OCI's Cost Analysis dashboard" %}

The report is spit into two components — graph and table:

{% imgx assets/reporting-graph-and-table.png "Cost analysis showin using a graph" %}

The computed amount details are itemised in a table.

The computed amount is also specified in the local currency. For example, Singapore dollars.

{% imgx assets/reporting-cost-table.png "Cost analysis showin using a table" %}

For the computed quantity, select the **Usage** option from the **Show** dropdown menu.

{% imgx assets/reporting-computed-quality-table.png "OCI Cost Analysis dashboard with 'Usage' selected in the 'Show' field" %}

You’ll get a table similar to the following:

{% imgx assets/reporting-cost-details-table.png "Table displaying usage measurement of calculated costs" %}

So it’s nice to get this information from the console.

However, it can be more convenient to gather this information from OCI command line.

## Report from the command line

For a Linux workstation (like Fedora), install the OCI command line tool as follows:

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

You’ll receive a number of prompts for options, but you can just `enter` through them.

After the installation is finished, you can activate the Python virtual environment in your working directory:

```bash
$ source activate
```

Then test with the following command:

```bash
oci iam compartment list -c ocid1.tenancy.oc1..<tenantID>
```

If your workstation time differs, then you may get the following warning.

> WARNING: Your computer time: 2021–06–11T08:37:19.308803+00:00 differs from the server time: 2021–06–11T08:54:45+00:00 by more than 5 minutes. This can cause authentication errors connecting to services.

Otherwise, you'll receive the following output which also proves the OCI command line tool is working.

{% imgx assets/reporting-success-objects.png "Objects in a code editor displaying successful output" %}

To stop using the CLI, run the following command in a terminal.

```bash
$ deactivate
```

## Cost Analysis from the OCI command line

Let's start with the filter, which needs to be in JSON format:

```
{
  "tenantId": "ocid1.tenancy.oc1..<tenantID>",
  "timeUsageStarted": "2020-12-01T17:00:00.000000-07:00",
  "timeUsageEnded": "2020-12-29T00:00:00Z",
  "granularity": "DAILY",
  "groupBy": [],
  "compartmentDepth": null,
  "filter": null,
  "nextPageToken": "string"
}
```

Put the JSON inside a file named `SimpleRequestSummarizedUsagesDetails.json`

Then use OCI to query as follows:

```bash
oci raw-request --http-method POST --target-uri https://usageapi.ap-sydney-1.oci.oraclecloud.com/20200107/usage 
--request-body file://~/oci-python-sdk/examples/SimpleRequestSummarizedUsagesDetails.json 
--config-file ~/.oci/config
```

You’ll get a long output that looks like this:

{% assets/reporting-json-output.png imgx "Example JSON output" %}

However, it can be more convenient to get the same information from Python.

## Report from Python

Official Python installation docs [are here:](https://docs.oracle.com/en-us/iaas/tools/python/2.38.3/installation.html)

Firstly, clone the OCI Python SDK from Github like this:

```bash
$ git clone git@github.com:oracle/oci-python-sdk.git
```

{% imgx assets/reporting-clone-python-sdk.png "Terminal window with commands to clone OCI's Python SDK" %}

Then activate the Python virtual environment:

```bash
$ cd oci-python-sdk
$ python3 -m venv .
$ source ./bin/activate
```

Afterwards, install the OCI package.

```bash
$ pip install oci
```

{% imgx assets/reporting-pip-install.png "Terminal using a pip command to install OCI Python" %}

For authentication, you’ll also need to setup the .oci directory, and ensure the private key is in the `~/.oci/config` file.

Now that everything is installed, do a quick test in python3:

```bash
$ python3
```

Input the following commands:

```console
>>> import oci
>>> config = oci.config.from_file("~/.oci/config", "DEFAULT")
>>> identity = oci.identity.IdentityClient(config)
>>> user = identity.get_user(config["user"]).data
>>> print(user)
```

You should receive an output similar to the following:

{% imgx assets/reporting-terminal-objects.png "Terminal with objects" %}

### Cost Analysis using Python

You can find a basic script to download usage reports in [Oracle's Docs](https://docs.oracle.com/en-us/iaas/Content/Billing/Tasks/accessingusagereports.htm):

The script is also listed below:

```console
import oci
import os
				
# This script downloads all of the cost, usage, (or both) reports for a tenancy (specified in the config file).
#
# Pre-requisites: Create an IAM policy to endorse users in your tenancy to read cost reports from the OCI tenancy.
#
# Example policy:
# define tenancy reporting as ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq
# endorse group group_name to read objects in tenancy reporting
#
# Note - The only value you need to change is the group name. Do not change the OCID in the first statement.
				
reporting_namespace = 'bling'
				
# Download all usage and cost files. You can comment out based on the specific need:
prefix_file = ""                     #  For cost and usage files
# prefix_file = "reports/cost-csv"   #  For cost
# prefix_file = "reports/usage-csv"  #  For usage
				
# Update these values
destintation_path = 'downloaded_reports'
				
# Make a directory to receive reports
if not os.path.exists(destintation_path):
    os.mkdir(destintation_path)
				
# Get the list of reports
config = oci.config.from_file(oci.config.DEFAULT_LOCATION, oci.config.DEFAULT_PROFILE)
reporting_bucket = config['tenancy']
object_storage = oci.object_storage.ObjectStorageClient(config)
report_bucket_objects = object_storage.list_objects(reporting_namespace, reporting_bucket, prefix=prefix_file)
				
for o in report_bucket_objects.data.objects:
    print('Found file ' + o.name)
    object_details = object_storage.get_object(reporting_namespace, reporting_bucket, o.name)
    filename = o.name.rsplit('/', 1)[-1]
				
    with open(destintation_path + '/' + filename, 'wb') as f:
        for chunk in object_details.data.raw.stream(1024 * 1024, decode_content=False):
            f.write(chunk)
				
    print('----> File ' + o.name + ' Downloaded')
```

Save the script in `~/oci-python-sdk/examples/`.

After running the script, all reports will be saved to the `~/oci-python-sdk/examples/downloaded_reports` directory.

Then unzip and inspect any report with:

```console
$ gunzip 0001000000428365.csv.gz
$ less 0001000000428365.csv.gz
```

### Cost Analysis using Python and Requests

With Python, it's possible to use the native urllib.request module as an HTTP client to query the APIs.

https://docs.python.org/3/library/urllib.request.html#module-urllib.request

However, the Requests package is recommended for a higher-level HTTP client interface.

https://docs.python-requests.org/en/master/

The Requests library is also used in the official examples for the OCI Python SDK in Github:

https://github.com/oracle/oci-python-sdk/blob/master/examples/

Run as a script or interactively.

```python
import requests
from oci.config import from_file
from oci.signer import Signer

config = from_file()
auth = Signer(
tenancy=config['tenancy'],
user=config['user'],
fingerprint=config['fingerprint'],
private_key_file_location=config['key_file'],
pass_phrase=config['pass_phrase']
)

endpoint = 'https://usageapi.ap-sydney-1.oci.oraclecloud.com/20200107/usage'body = {
  'tenantId': 'ocid1.tenancy.oc1..aaaaaaaayjcxmo3mjpcu37iecerrlm5fdnreegpa3awvzvursmeyabyawvwq',
  'timeUsageStarted': '2020-12-01T00:00:00Z',
  'timeUsageEnded': '2020-12-29T00:00:00Z',
  'granularity': 'DAILY'
}

response = requests.post(endpoint, json=body, auth=auth)
response.raise_for_status()
```

Add a timeout to the Post request as a best practice to prevent your client from hanging indefinitely.

```console
response = requests.post(endpoint, json=body, auth=auth, timeout=5)
```

Then show the output in JSON without text formating:

```console
print(response.json())
```

{% imgx assets/reporting-json-response.png "Terminal with JSON without text formating" %}

You may want to display the output in JSON with easy-to-read text formating:

```console
print(response.text)
```

{% imgx assets/reporting-json-response-print.png "Terminal with JSON response with formatting" %}