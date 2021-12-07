---
title: APIs for User Management in OCI
parent: [tutorials]
date: 2021-12-06 12:00
description: Find out how easy using Python with OCI is super easy is, even on Oracle's Always-Free Tier account.
thumbnail: assets/api-management-gh-python.png
author: 
    name: Paul Guerin 
    bio: Paul Guerin is a consultant of Oracle Technology.
published: false
---
APIs are not just for receiving information about an end-point.

APIs can do other tasks too, like use Python.

Because we'll be using Python, let's start with the [Github OCI Python SDK page](https://github.com/oracle/oci-python-sdk/tree/master/examples). There are a number of Python example scripts here.

{% imgx assets/api-management-gh-python.png "Github page of the Python SDK" %}

Through trial and error, some of the examples there have been found to work with the Oracle Free Tier.

For example, it’s easy enough to display some basic information about IP addresses and DNS using the `get_all_instance_ip_addresses_and_dns_info.py` script.

```console
$ cd ~/oci-python-sdk/examples$ python3 get_all_instance_ip_addresses_and_dns_info.py <OCID of instance>
```

{% imgx assets/api-management-ip-and-dns.png "Terminal displaying IP and DNS info with some information obscured" %}

This is great and all, but with APIs you can also do some real work!

## Create a user in the Oracle Free Tier

All the Python scripts for the Python SDK are here:

```console
$ cd ~/oci-python-sdk/examples
```

For example, check out the `raw_request.py` script:

```python
import requests
from oci.config import from_file
from oci.signer import Signerconfig = from_file()
auth = Signer(
tenancy=config['tenancy'],
user=config['user'],
fingerprint=config['fingerprint'],
private_key_file_location=config['key_file'],
pass_phrase=config['pass_phrase']
)endpoint = 'https://identity.ap-sydney-1.oraclecloud.com/20160918/users/'body = {
'compartmentId': config['tenancy'],  # root compartment
'name': 'TestUser',
'description': 'Created with a raw request'
}response = requests.post(endpoint, json=body, auth=auth)
response.raise_for_status()print(response.json()['id'])
```

Run the script as follows:

```console
$ python3 raw_request.py
```

That command will create a user named `TestUser` and return the OCID.

This user can be verified to exist in the console.

{% imgx assets/api-management-testuser-in-dashboard.png "OCI dashboard displaying OCID" %}

### Create a group and a user in the Oracle Free Tier

You can also run  `script user_crud.py` to create a user and group in Oracle Cloud.

```python
import oci
from oci.identity.models import AddUserToGroupDetails, CreateGroupDetails, CreateUserDetails# Default config file and profile
config = oci.config.from_file()
compartment_id = config["tenancy"]
# Service client
identity = oci.identity.IdentityClient(config)# Get and set the home region for the compartment. User crud operations need
# to be performed in the home region.
response = identity.list_region_subscriptions(compartment_id)
for region in response.data:
    if region.is_home_region:
        identity.base_client.set_region(region.region_name)
        breakuser_name = "python-sdk-example-user"
group_name = "python-sdk-example-group"print("Creating a new user {!r} in compartment {!r}".format(
    user_name, compartment_id))request = CreateUserDetails()
request.compartment_id = compartment_id
request.name = user_name
request.description = "Created by a Python SDK example"
user = identity.create_user(request)
print(user.data)print("Creating a new group {!r} in compartment {!r}".format(
    group_name, compartment_id))request = CreateGroupDetails()
request.compartment_id = compartment_id
request.name = group_name
request.description = "Created by a Python SDK example"
group = identity.create_group(request)
print(group.data)print("Adding new user to the new group")
request = AddUserToGroupDetails()
request.user_id = user.data.id
request.group_id = group.data.id
membership = identity.add_user_to_group(request)
print(membership.data)
```

Run that script with:

```console
$ python3 user_crud.py
```

As a result, a group is created named `python-sdk-example-group`:

{% imgx assets/api-management-python-create-group.png "OCI dashboard displaying group information" %}

A user will also be created in the group called `python-sdk-example-user`:

{% imgx assets/api-management-user-information.png "OCI panel displaying user information" %}

User management in Oracle Free Tier could hardly be easier!
