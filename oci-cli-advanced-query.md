---
title: Advanced queries for OCI CLI output
parent: [tutorials]
date: 2023-03-14 12:00
---
In previous tutorials we've taken a brief look at the Oracle Cloud Infrastructure (OCI) command line interface (CLI). You can explore all of the options available [in the docs](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.23.3/oci_cli_docs/oci.html), but today we're going to look at the `--query` flag and how to use it for more advanced filtering of response data.

The default JSON-formatted response from the CLI can be very verbose, containing a lot of info you don't need, and making the info you _do_ need that much harder to extract. The `--query` flag takes an argument in the form of a [JMESPath](https://jmespath.org/) string, allowing you to query and filter the response, outputting just what you need. This can be a simple query like `[?name=='blocktest']` as we covered in the last article, but it can also be a more advanced query that both filters the input and shapes the output.

For example, let's write a query that searches not for an exact title match, but for titles that simply contains our search text. To do this, we use the `contains` function: 

	data[?contains("display-name", 'your_text_here')]

The key for the base array returned from the CLI is always called `data`. Within that array, the above example searches for a key in each element called 'display-name', and then tests to see whether it contains the text 'your_text_here'.

The  `--query` flag always assumes a string value. To do numeric comparisons, be sure to cast the value to a number using `.to_number(@)`. For example:

	oci compute image list -c $compOcid --query 'data[?"operating-system-version".to_number(@) > `8`]'

There are several functions available in JMESPath, including `max_by` to return the result with the highest value for a given key, or `min_by` to return the lowest result. See the [JMESPath documentation](https://jmespath.org/specification.html) for more details.

### Piping and Negating

You can combine multiple criteria using pipes (`|`), and you can invert a function by using `?!FUNCTION`. For example, if you wanted to search first for a container name, and then remove a set of matches, you could use:

	oci compute image list --compartment-id ocid1.tenancy.xxx --query 'data[?contains("display-name",'Oracle-Linux')] | [?!contains("display-name",'arch64')]|[0:1].["display-name",id]' --all

Note the pipe in the middle of the query, which causes the results of the first `?contains` search to be "piped" into a negative `?!contains` search to remove all images with `arch64` in the display name.

### Shaping

You can control what information is output as well. To output a specific key path, you can separate each element in the path with a dot, being sure to quote any keys that have a dash in them. For example, to output all of the CreatedBy tags for an OCI compartment listing, you could use:

	oci iam compartment list --all --query 'data[*]."defined-tags"."Oracle-Tags".CreatedBy'

This will iterate through the array, and within each hash in the array, locate the "defined-tags" key, find "Oracle-Tags" inside of it, then find the "CreatedBy" key and output its value.

You can also create a custom hash with the output using a syntax like:

	--query 'data[*].{id: id, timeCreated: "time-created"}'

The left half of each key/value pair defines the key that will be output, the right half defines what value will be attributed to it. So you're defining custom keys for existing values in the output.

Now that you see some of the possibilities for these queries, you're probably wondering how to make them easier to access and more reusable. The CLI has the solution, in the form of aliases you can define in your configuration. Stay tuned for the next article for a look at the three types of aliases you can create and how to use them.
