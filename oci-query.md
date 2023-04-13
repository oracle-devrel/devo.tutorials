---
title: Working with OCI CLI responses using the query flag
date: 2023-02-21 12:00
parent: [tutorials]
---

[cli]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm
[cloud shell]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/devcloudshellgettingstarted.htm#Getting_Started_with_Cloud_Shell
[install]: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#Quickstart
[JMSEPath]: https://jmespath.org/
[tutorial]: https://jmespath.org/tutorial.html
[jq]: https://stedolan.github.io/jq/

The [OCI Command Line Interface][cli] tool, or `oci`, is a way to perform almost any OCI operation from the command line. It's included and configured in [Cloud Shell] instances automatically, and can be [installed on most platforms][install] for local usage. The OCI CLI is a great tool for automating repetitive processes.

However, when automating operations with `oci`, working with response data can be tricky. The tool returns very verbose information for every operation, which is great, but hard to sift through if you want to pass a specific value on to another operation.

`oci` returns its response in JSON format. This is easy enough to work with if you're automating within a language that has JSON parsing and querying, but if you're working without a JSON library, in a Bash script for example, the responses need some additional decoding.

That's where the `--query` flag comes in. This flag allows you to perform a [JMSEPath] query on the return data. JMSEPath can handle some complex operations, but most of the response data from `oci` is a simple hash, so all you need is a path to get a specific value.

> Strings returned by the `--query` flag are double quoted. To return them without double quotes, add `--raw-output`.

For example, if we're using the `oci devops repository get` command with the goal of retrieving the SSH URL for a given Code Repository, we can use a command such as:

	oci devops repository get --repository-id REPOSITORY_OCID --query 'data."ssh-url"' --raw-output

This will locate the key `ssh-url` in the `data` object, which `oci` responses are contained in. This value can be stored in a variable for use in whatever the next step of your script is:

	SSH_URL=$(oci devops repository get --repository-id REPOSITORY_OCID --query 'data."ssh-url"' --raw-output)

	# Step that uses $SSH_URL

> Note that to reference a key containing a hyphen, you need to surround the entire expression with single quotes, then surround the hyphenated key with double quotes, e.g. `'data."ssh-url"'`.

The basic [JMSEPath tutorial][tutorial] provides the tools you'll need to work with `oci`'s JSON responses. However, the `--query` flag doesn't provide perfect parity with the JMSEPath spec. The next article in this series will detail some of the differences you'll run into with more complex queries, and also how to use an alternative, [jq], to parse as part of a piped command.
