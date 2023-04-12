---
title: Using aliases to speed up OCI CLI commands
parent: [tutorials]
date: 2023-04-12 12:00
---
We've been talking a bit about the Oracle Cloud Infrastructure (OCI) Command Line Interface (CLI) lately, and looking at some of the advanced ways it can format output using the `--query` parameter. Those arguments can get a bit long, so I thought it would be a good idea to demonstrate how you can use aliases to make accessing the same query repeatedly easier. We'll also take a look at the other types of aliases you can configure for the CLI.

Aliases are defined in the OCI CLI configuration file. This is usually located at `~/.oci/oci_cli_rc` or just `~/.oci/config`. You can specify alternate config location using the environment variable `OCI_CLI_RC_FILE`, e.g. `export OCI_CLI_RC_FILE=~/.config/oci_cli`. You can also change config files per execution with the `--cli-rc-file` flag, e.g. `<CLI COMMAND> --cli-rc-file ~/.config/oci_cli`, though having to remember multiple config file locations seems inconvenient at best.

In this config file, sections are labeled with square brackets and uppercase letters. For example, default configuration parameters are in the section `[DEFAULT]`:

```
[DEFAULT]
user=ocid1.user.oc1.xxxx
tenancy=ocid1.tenancy.oc1.xxxxx
region=us-phoenix-1
key_file=xxxxx
```

### Query Aliases

For today's look at aliases, we're going to start with query aliases, which go in a section called `[OCI_CLI_CANNED_QUERIES]`. The queries are defined as basic key/value pairs with a title, an equals sign, and the query that should be executed when the title is referenced.

```
[OCI_CLI_CANNED_QUERIES]
#  For list results, this gets the ID and display-name of each item in the list. 
#  Note that when the names of attributes have dashes in them they need to be surrounded 
#  with double quotes. This query knows to look for a list because of the [*] syntax 
	
id_name_from_list=data[*].{id: id, "display-name": "display-name"}
	 
id_name_from_single=data.{id: id, "display-name": "display-name"}
```

Once these are defined, you can easily use them in a CLI command by using the `--query` flag and formatting the query as `query://ALIAS_TITLE`. For example, to use the first query above, you could run `oci compute instance list -c $C --query query://id_name_from_list`. Any time you use a query more than once, or foresee using it again in the future, add an alias for it to your config file. You may have to reference that file to recall the title for infrequently-used queries, but you'll have a reference for anything you've figured out as you use the tool.

### Command Aliases

Command aliases are specified in a section called `[OCI_CLI_COMMAND_ALIASES]`. There are two types of command aliases: global aliases, and command sequence aliases. 

Global aliases allow you to provide abbreviations for given commands. An obvious example is making `list` into `ls` for brevity.

```
[OCI_CLI_COMMAND_ALIASES]

ls = list
```

Now you can use `ls` in place of `list` in any command, e.g. `oci os object ls`.

A command sequence alias, as you might expect, lets you alias a sequence of commands into a single abbreviation. For example, the command to delete an object would be `oci os object delete ...`. You can alias this as `rm` with `rm = os.object.delete`, and then just call `oci rm ...` to perform the operation.

```
[OCI_CLI_COMMAND_ALIASES]

rm = os.object.delete
```

### Options Aliases

You can also alias command options (or parameters) for easy access. These are specified in `[OCI_CLI_PARAM_ALIASES]`. Start an option alias with a double or single hyphen followed by at least one letter, e.g. `--ad = --availability-domain`. Once an option alias such as this is defined, you can just use `--ad` in a command and it will expand to `--availability-domain`.

```
[OCI_CLI_PARAM_ALIASES]

--ad = --availability-domain
```

Bonus: these aliases are available in default value configurations such as the following, where `ad=` will be replaced with `availability-domain=`:

```
[DEFAULT]
compute.instance.list.ad=xyx:PHX-AD-1
```

Hopefully making use of aliases will save you some time as you explore the CLI!