---
title: Using Oracle's Machine Translation Services for NLP Analysis
parent:
- tutorials
tags:
- python
- oci
date: 2021-12-10 13:04
description: Ignacio walks you through Oracle MTS, a translation service, using Python
  and even provides a benchmarking function to test its speed.
MRM: WWMK211210P00028
author: ignacio-martinez
xredirect: https://developer.oracle.com/tutorials/oracle-translation-nlp-analysis/
slug: oracle-translation-nlp-analysis
---

## Introduction
Welcome! This article is an overview of Oracle's Machine Translation Services (MTS) and how they complement the standard open-source NLP libraries out there today. Currently, this service is focused/created with the intention of helping Oracle internal teams translate texts in a secure way (see below), so this is not a readily available product. However, there are plans for the future to make it available for OCI users.

Oracle Translate is an MTS made available by Oracle’s International Product Solutions. It's beneficial to use Oracle's service over others, especially for sensitive information, because other services, such as Google Translate, are known to harvest and collect requesting data which could infringe on company confidentiality and chain of custody of protected documents. Oracle's service does not store this information, and all transactions happen in a secure Oracle network environment.

Let’s explore some examples of how Oracle's MT services are different from other translation services like Google's.

If you don't yet have an OCI account, you can quickly sign up for one today by registering for an [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/#always-free) account. 

Afterwards, check [developer.oracle.com/linux](https://developer.oracle.com/python/) for even more Python content.

## Authentication

Authentication is performed against Oracle Cloud resources and handled by Oracle's Identity Cloud Service (IDCS), using Base64 encoding.

The two main components of Oracle Translate are a client ID and a client secret. Using these components, we can perform authentication following this flow:

```python
# Defining variables
IDCSSERVER = '<url_provided_by_oracle_mts_team.com>'
SCOPE = 'urn:opc:idm:__myscopes__'
# Production endpoint
BASEURL = '<url_provided_by_oracle_mts_team.com>'
ENDPOINT = '{}/translation/api'.format(BASEURL)
REALTIME_ENDPOINT = '<url_provided_by_oracle_mts_team.com>'
NLP_ENDPOINT = '<url_provided_by_oracle_mts_team.com>'
data = load_config_file()
basic_authorization = '{}:{}'.format(
data['mt_translation']['MT_CLIENT_ID'], data['mt_translation']['MT_CLIENT_SECRET']
)
basic_authorization = base64.b64encode(basic_authorization.encode('ascii')).decode('ascii')
request_url = '{}/oauth2/v1/token/'.format(IDCSSERVER)
request_headers = {
'Authorization': 'Basic {}'.format(basic_authorization),
'content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
'x-resource-identity-domain-name':'idcs-oracle'
}
request_data = 'grant_type=client_credentials&scope={}'.format(SCOPE)
response = requests.post(request_url, data=request_data, headers=request_headers)
api_token = response.json().get('access_token')
```

Our primary objective is to obtain the necessary API token to perform operations. Note that the config.yaml file mentioned to obtain the client ID and secret should follow this hierarchical structure:

```yaml
mt_translation:
  MT_CLIENT_ID: XXXX
  MT_CLIENT_SECRET: XXXX
```

Once we have the API token, we can perform authenticated requests against Oracle's MT Translation service.

## Batch Translation
In this case, we will translate a document in Markdown format [this one as an example.](http://jasperan.com/files/jasperan.md)

The batch translation endpoint supports translating whole documents instead of making several requests. Also, requests can be submitted for multiple target languages at a time, making it possible that one request is translatable to every available language supported by the API with just one call.

```python
def batch_translation(api_token, file_path, file_name):
	request_url = '{}/files?service={}&sourceLang={}&scope={}'.format(ENDPOINT, 'mt', args.source_language_code, args.target_language_code)
	request_headers = {
		'Authorization': 'Bearer {}'.format(api_token)
	}
	#print(request_url, request_headers)
	files = {
		'file': (file_name, open(file_path, 'rb'))
	}

	print('Request URL: {}'.format(request_url))
	print('Request headers: {}'.format(request_headers))
	print('Request file: {}'.format(dict(file=files['file'])))

	response = requests.post(request_url, headers=request_headers, files=dict(file=files['file']))
	response_json = response.json()
	print(response.status_code, response.json())

	drop = None
	while drop is None:
		print('Waiting for translated file to be ready...')
		try:
			response = requests.get(response_json.get('pipeline').get('status'))
		except Exception as e:
			print(e)
	
		try:
			print(response.json())
			drop = response.json().get('map').get('en_drop') # varies with language. I used 'en' as English in this example.
			if drop is not None:
				print('File result in {}'.format(drop))
		except KeyError:
			print('Could not find the drop.')
		
		time.sleep(10)
```

After executing and periodically waiting for the resulting file to be ready, we get our processed data in about 40 seconds:

```console
Request URL: <url_provided_by_oracle_mts_team.com>
Request file: {'file': ('intro.md', <_io.BufferedReader name='../data/intro.md'>)}
202 {'id': 115162, 'status': 'CREATED', 'service': 'mt', 'source': {'originalPath': 'intro.md', 'language': 'en'}, 'scope': ['fr'], 'otp_instance_id': 343337, '_links': {'self': '<url_provided_by_oracle_mts_team.com>', 'otp_status': '<url_provided_by_oracle_mts_team.com>', 'otp_wordcount': '<url_provided_by_oracle_mts_team.com>'}, 'pipeline': {'id': 343337, 'status': '<url_provided_by_oracle_mts_team.com>', 'wordcount': '<url_provided_by_oracle_mts_team.com>'}}
Waiting for translated file to be ready...
{'id': 343337, 'state': 'RUNNING', 'pipeline_id': 1, 'start': '2021-11-17T00:24:57Z', 'update_time': '2021-11-17T00:24:57Z', 'end': '', 'running_time_str': '1s', 'updated_ago_in_str': '1s', 'progress': {'preprocessing': 0, 'translation': 0, 'merge_and_delivery': 0}, 'map': {'translated_langs': [], 'deferred_langs': [], 'originalFileName': 'intro.md'}, 'messages': []}
Waiting for translated file to be ready...
{'id': 343337, 'state': 'RUNNING', 'pipeline_id': 1, 'start': '2021-11-17T00:24:57Z', 'update_time': '2021-11-17T00:24:57Z', 'end': '', 'running_time_str': '12s', 'updated_ago_in_str': '12s', 'progress': {'preprocessing': 0, 'translation': 0, 'merge_and_delivery': 0}, 'map': {'translated_langs': [], 'deferred_langs': [], 'originalFileName': 'intro.md'}, 'messages': []}
Waiting for translated file to be ready...
{'id': 343337, 'state': 'RUNNING', 'pipeline_id': 1, 'start': '2021-11-17T00:24:57Z', 'update_time': '2021-11-17T00:24:57Z', 'end': '', 'running_time_str': '23s', 'updated_ago_in_str': '23s', 'progress': {'preprocessing': 0, 'translation': 0, 'merge_and_delivery': 0}, 'map': {'translated_langs': [], 'deferred_langs': [], 'originalFileName': 'intro.md'}, 'messages': []}
Waiting for translated file to be ready...
{'id': 343337, 'state': 'RUNNING', 'pipeline_id': 1, 'start': '2021-11-17T00:24:57Z', 'update_time': '2021-11-17T00:25:21Z', 'end': '', 'running_time_str': '34s', 'updated_ago_in_str': '10s', 'progress': {'preprocessing': 100, 'translation': 1, 'merge_and_delivery': 0}, 'map': {'languages': 1, 'translated_langs': [], 'deferred_langs': [], 'en_drop': '<url_provided_by_oracle_mts_team.com>/s115162.zip', 'originalFileName': 'intro.md'}, 'messages': []}
File result in <url_provided_by_oracle_mts_team.com>/s115162.zip
```

And with the final result we can download the .zip file with our translated file inside the folder. 

## Real-Time Translation
In this case, we're going to test with a few examples on the real-time translation endpoint. The list of available languages is defined as:

```python
# CURRENTLY SUPPORTED LANGUAGE CODES
LANGUAGES = [
	'en', 'fr-CA', 'pl', 'sv', 'ar', 'de', 'ro', 'zh-TW', 'pt-BR', 'it', 'ru', 'nl', 'ja', 'zh-CN', 'fr', 'ko', 'es-ww'
]
# Coming in FY22Q3: Norwegian, Danish, Czech, Finish, Turkish & in FY22Q4: Greek, Hebrew, Thai, Ukrainian, Croatian 
```

We predefine our languages in a list and only allow these language codes as input:

```python
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-s', '--source-language-code', choices=LANGUAGES, required=True)
parser.add_argument('-t', '--target-language-code', choices=LANGUAGES, required=True)
args = parser.parse_args() 
```

Let’s define our real-time endpoint as follows:

```python
def real_time_translation(api_token, data):
	assert type(data) == type(str())
	request_url = '{}/translate/{}/{}?s={}'.format(REALTIME_ENDPOINT, args.source_language_code, args.target_language_code, urllib.parse.quote(data))
	request_headers = {
		'Authorization': 'Bearer {}'.format(api_token)
	}
	print(request_url)

		
	response = requests.get(request_url, headers=request_headers)
	print(response.status_code, response.content)
```

Note that we quote our string to avoid inconsistencies with path parameters in the request URL. After executing this code in this fashion:

```bash
python mt_translation.py --source-language-code "en" --target-language-code "fr"
```

We see this result:

```bash
<url_provided_by_oracle_mts_team.com>/translate/en/fr?s=This%20is%20an%20example
200 b"C'est un exemple"
```

We were able to translate a request in about 1.5 seconds. I created a benchmark function to measure the average request/response time:

```python
import time
def benchmark():
	api_token = get_access_token
	for x in range(500):
		t1 = time.time()
		real_time_translation(api_token, text)
		print('[BENCHMARK] +{}'.format(time.time() - t1))
```

Which produced these results:

```bash
[BENCHMARK] +1.5139455795288086
[BENCHMARK] +1.480928897857666 
[BENCHMARK] +1.4764995574951172
[BENCHMARK] +1.5293617248535156
...
...
[BENCHMARK] +1.4901740550994873
[BENCHMARK] +1.5180373191833496
[BENCHMARK] +1.489206314086914 
[BENCHMARK] +1.4964230060577393
```

Each request takes about an average of 1.5 seconds to finish.

## Docker setup

I've included a Docker file that only requires a config.yaml file to run. To download the Docker file, find it in [this GitHub](https://github.com/oracle-devrel/nlp-oracle-translation/tree/main/oracle) directory.

The contents of `config.yaml` should be like this:

```yaml
mt_translation:
  MT_CLIENT_ID: XXXXXXXXXXXXXXXXXXXXXXXXXXX
  MT_CLIENT_SECRET: XXXXXXXXXXXXXXXXXXXXXXXXXXX
  MT_SERVICE: mt
```

Build the image:

```bash
docker build --pull --rm -f "nlp-oracle-translation\oracle\Dockerfile" -t oracle_translate "nlp-oracle-translation\oracle"
```

And run it:

```bash
docker run -it -p 443:443 oracle_translate  -s en -t fr -x "This is an example"
```

Example run:

```bash
λ docker run -it -p 443:443 oracle_translate  -s en -t fr -x "I love you"
200 Je vous aime !
```

## How can I get started on OCI?

Remember that you can always sign up for free with OCI! Your Oracle Cloud account provides a number of Always Free services and a Free Trial with US$300 of free credit to use on all eligible OCI services for up to 30 days. These Always Free services are available for an **unlimited** period of time. The Free Trial services may be used until your US$300 of free credits are consumed or the 30 days has expired, whichever comes first. You can [sign up here for free](https://signup.cloud.oracle.com/).


## License

Copyright (c) 2021 Oracle and/or its affiliates.

Licensed under the Universal Permissive License (UPL), Version 1.0.

See [LICENSE](../LICENSE) for more details.

Written by [Ignacio Guillermo Martínez](https://www.linkedin.com/in/ignacio-g-martinez/) [@jasperan](https://github.com/jasperan), edited by [GreatGhostsss](https://github.com/GreatGhostsss)
