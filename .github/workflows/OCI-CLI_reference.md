# Introduction

The *Command Line Interface (CLI)* is a small-footprint tool that you can use on its own or with the Console to complete Oracle Cloud Infrastructure tasks. The CLI provides the same core functionality as the Console, plus additional commands. Some of these extend Console functionality, such as the ability to run scripts.  

This CLI and sample are dual licensed under the [Universal Permissive License 1.0](https://opensource.org/licenses/UPL) and the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0); third-party content is separately licensed as described in the code.  

The CLI is built on the Oracle Cloud Infrastructure SDK for Python and runs on [Mac, Windows, or Linux](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm#Requirements__SupportedPythonVersionsandOperatingSystems) (for more information about SDKs, see the [Other Resources](#sdks) section below). The Python code makes calls to Oracle Cloud Infrastructure APIs to provide the functionality implemented for the
various services. These are REST APIs that use HTTPS requests and responses. For more information, see [About the API](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/usingapi.htm#REST_APIs).  

## Installation

### Quick start

Select an OS-specific version below to install a local version of the OCI CLI.  

**OCI CLI currently supports:** [Oracle Linux 8](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__oraclelinux8), [Oracle Linux 7](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__oraclelinux7), [Mac
OS](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__macos_homebrew), [Windows](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__windows), and [Linux and Unix](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__linux_and_unix)  

### Special cases

- [WSL (Windows Subsystem for Linux) in Windows 10 or above](https://kqeducationgroup.com/installation-of-oci-cli-on-wsl-windows-subsystem-for-linux-in-windows-10-or-above/)

- [Oracle DBCS instance](https://qiita.com/liu-wei/items/ff455a12a0f2580d48ce)

### OCI CLI container image

OCI also supports running a container image version of the CLI.

- **Requirements:** to see what you need to use the OCI CLI container image, refer to the [CLI requirements page](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clicontainer.htm#clicontainer_requirements)

- **Set up:** for details on how to install and configure OCI CLI by using a container image, see [Working with the OCI CLI container image](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clicontainer.htm).

### Troubleshooting

If you should encounter issues either during installation (Python or CLI) or when using the CLI itself, refer to the page, [Troubleshooting the CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitroubleshooting.htm) for assistance.  

## Authentication

[Token-based authentication](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm) for the CLI allows customers to authenticate their session interactively, then use the CLI for a single session without an API signing key. This enables customers using an identity provider that is not [SCIM](https://docs.oracle.com/en/cloud/paas/identity-cloud/uaids/use-scim-interface-integrate-oracle-identity-cloud-service-custom-applications.html#GUID-B883A440-9726-4219-8C0C-A906B821AB46)-supported to use a [federated user account](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/usingscim.htm#:~:text=A%20federated%20user%20is%20created,to%20Oracle%20Cloud%20Infrastructure%20groups.) with the CLI and SDKs.  

### Requirements

The requirements are the same as those listed for the CLI in [Requirements](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm#Requirements), except that instead of an SSH keypair, you need a web browser for the authentication process.  

>**Note:** There is still a way to start a token-based CLI session even if you [don't have access to a browser](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm#Starting_a_Tokenbased_CLI_Session_without_a_Browser).  
{:.notice}

### Starting a token-based CLI session

To use token-based authentication for the CLI on a computer with a web browser:  

1. In the CLI, run the following command. This will launch a web browser.  

   ```sh
   oci session authenticate
   ```

2. In the browser, enter your user credentials.  

   >**Note:** This authentication information is saved to the **config** file.  
   {:.notice}

### Other actions

- [Refreshing a token](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm#Refreshing_a_Token)

- [Validating a token](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm#Validati)

## Configuration

The CLI supports using a [file](#configuration-file) for CLI-specific configurations. You can use these optional configurations to extend CLI functionality.  

With this configuration file you can:  

- Specify a default profile

- Set default values for command options

- Define aliases for commands

- Define aliases for options

- Define named queries that are passed to the **\--query** option instead of typing a **JMESPath** expression on the command line.

>**Note:** The CLI also supports the use of environment variables to specify defaults for some options. See [CLI Environment Variables](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clienvironmentvariables.htm#CLI_Environment_Variables) for more information.  
{:.notice}

### Configuration file

#### Location

**Default location:** \~/.oci/oci_cli_rc  

You can specify the location via:  

- **Environment variable:** OCI_CLI_RC_FILE

- **Command-line option:** \--cli-rc-file

**Example:**  

\<*CLI command*\> \--cli-rc-file path/to/my/cli/rc/file

#### Setting up the **oci_cli_rc** file

In a new CLI window, run:  

```sh
oci setup oci-cli-rc --file path/to/target/file
```

>**Note:** This command creates the file you specify that includes examples of default command aliases, parameter aliases, and named queries.  
{:.notice}

#### Working with your configuration file

- [Setting up a default profile](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Specifying_a_Default_Profile)  

  **Section:** OCI_CLI_SETTINGS  
  **Format:** default_profile=\<*profile name*\>

- [Specifying default values](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Specifying_Default_Values)

  The **\--cli-RC-file** file can be divided into different sections with one or more keys per section.  

  **Keys** are named after command line options, but do not use a leading double hyphen (\--).  
  For example, the key for **\--image-id** is image-id.  

  You can specify keys for single values, multiple values, and flags.  

- [Specifying command aliases](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Specifying_Command_Aliases)

  There are two types of aliases: *global aliases* and *command sequence aliases*.

- [Specifying option aliases](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Specifying_Option_Aliases)

  **Section:** OCI_CLI_PARAM_ALIASES  
  **Format:** \<*option alias*\> = \<*original option*\>  

  **Example:**  
  \--ad = \--availability-domain

  > **Note:** Option aliases are applied globally.  
  {:.notice}

- [Specifying named queries](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Specifying_Named_Queries)

  If you use the **\--query** parameter to filter or manipulate the output, you can define named queries instead of using a **JMESPath** expression on the command line.  

  **Section:** OCI_CLI_CANNED_QUERIES

- autocomplete

  > **Note:** If you used the **CLI installer**, autocomplete was already installed by default.  
  >
  > However, if you manually installed the CLI or only wish to enable autocomplete on a per-session basis, use one of the commands below.  
  {:.notice}

- **Manual installation -** Run the following command:  

  ```sh
  oci setup autocomplete
  ```

- **Session-by-session basis** -- Run the following command:

  ```sh
  eval "$(_OCI_COMPLETE=source oci)"
  ```

## Using the CLI

[Reference documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)

### Basic command line syntax

Most commands must specify a service, followed by a resource type and then an action.  

The basic command line syntax is:  

**oci \<*service*\> \<*type*\> \<*action*\> \<*options*\>**

**Example:**

The following command shows a typical command line construct:  

```sh
oci compute instance launch --availability-domain "EMIr:PHX-AD-1" -c <compartmentID> --shape "VM.Standard1.1" --display-name "Instance 1 for sandbox" --image-id <imageID> --subnet-id <subnetID>
```

Here, **compute** is the *service*, **instance** is the *type*, **launch** is the *action*, and the balance of the command represents the *options*.  

> **Note:** Throughout this document, we'll be using the term *oci* to refer to commands executed within the CLI environment. This is to be distinguished from *OCI*, which refers to the Oracle Cloud Infrastructure platform.  
{:.notice}

#### Getting help with commands

For help with a specific command, you can enter **help *\<command\>*** on the command line or view the [Command Line Reference](https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/).  

In addition, you can get help for any command by using the **\--help**,
**-h**, or **-?** flag.  

**Examples:**

- oci \--help

- oci os bucket -h

- oci os bucket create -?  
  For a full list of commands, refer to the [OCI CLI help documentation](https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/).  

#### Output formats

- **JSON (\--output JSON)** - (default) The output is formatted as JSON string.  

  For additional information about working with JSON, see the section on **Advanced JSON options** in the [Additional features](#additional-features) section below.  

- **Table (\--output table)** - The output is formatted as a table with headings derived from the query parameters. It typically presents in an easier-to-read, human-friendly format.  

- **\--raw-output** - You can supply this argument to the CLI if you know that the output is a single string value; any surrounding quotes are removed for you in the output.  

### Additional features

- [Interactive mode](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliusing.htm#cliusing_topic_Using_Interactive_Mode)  

  In this mode, the oci helps guide you through command usage with autocomplete.  

- [Advanced JSON options](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliusing.htm#AdvancedJSON)  

  **Correct JSON format:**  

  The OCI CLI provides a built-in method to get the correct JSON format for both command options and commands.  

  - **Command options -** For a command option, use
      **\--generate-param-json-input** and specify the command option that you want to get the JSON for.  

    **Example:** To generate the JSON for creating or updating a security rule, run the following command:  

    ```sh
    oci network security-list create --generate-param-json-input ingress-security-rules
    ```

  - **Entire command -** For an entire command, use
      **\--generate-full-command-json-input**.

    **Example:** To generate the JSON for launching an instance, run the following command:  

    ```sh
    oci compute instance launch --generate-full-command-json-input
    ```

  **JMESPath:**

  *JMESPath* is a query language for JSON that allows you to extract and transform elements from a JSON document.  

  **For additional references, see:**  

  - [JMESPath project page](https://jmespath.org/)

  - [JMESPath tutorial](https://jmespath.org/tutorial.html)

  **jq:**

  *jq* is a command-line JSON processor which can be utilized in conjunction with OCI CLI input and output.  

  > "jq is like sed for JSON data - you can use it to slice, filter, and map and transform structured data."  

  **For additional references, see:**

  - [jq project page](https://stedolan.github.io/jq/)

  - [jq man page](https://docs.oracle.com/cd/E88353_01/html/E37839/jq-1.html)  

  **For some ways to use jq with the OCI CLI, see:**  

  - [Useful examples (advanced)](#general)

  - [OCI jq tricks](https://ruepprich.com/oci-jq-tricks/)

- Search and query functions

  **For helpful insights and use cases, see:**  

  - [Exploring the search and query features of the Oracle Cloud Infrastructure command line interface](https://blogs.oracle.com/cloud-infrastructure/post/exploring-the-search-and-query-features-of-oracle-cloud-infrastructure-command-line-interface)  

  **For some examples of using query to format command output, see:**  

  - the [Query](#queries-formatted-output) section below

- o, the OCI CLI wrapper utility

  *o* is a smart wrapper for the oci command in Oracle Cloud's CLI. o knows all the oci commands, and it learns about your resources. With this knowledge, o helps you use oci to manage your cloud resources.  
  Tasks that used to require scripting can now be performed directly from the command line.  

  To learn more about o, see:  

  - [Introducing o, the easy way to use the CLI](https://blogs.oracle.com/cloud-infrastructure/post/introducing-o-the-easy-way-to-use-the-cli)

  - o project repo
    [README](https://github.com/oracle/oci-cli/blob/master/scripts/examples/project_o/README.md)

### Useful examples (General)

In the sections below, **\$T** is the *tenancy OCID*, **\$C** is the *compartment* *OCID*, and **\$G** is the *group OCID*.  

#### db

**Command reference:** [**db**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db.html)  

| | |
| - | - |
| Service | Command |
| [Create a database](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db/database/create.html) | oci db database create [\--db-system-id](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db/database/create.html#cmdoption-db-system-id) \<dbSystemID\> [\--db-version](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db/database/create.html#cmdoption-db-version) \<dbVersion\> [\--admin-password](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db/database/create.html#cmdoption-admin-password) \<admin_password\> [\--db-name](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db/database/create.html#cmdoption-db-name) \<dbName\> |
| [List databases in a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db/database/list.html) | oci db database list -c \$C |
| | |

#### IAM

**Command reference:** [**IAM**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam.html)

- [Group](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group.html)

  | Action | Command |  
  | - | - |  
  | [Add a user to a group](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/add-user.html) | oci iam group add-user \--user-id \<*userID*\> \--group-id \<*groupID*\> |
  | [Create a group](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/create.html) | oci iam group create \--description \<*group description*\> \--name \<*name_of_the_group*\> |
  | [Delete a group](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/delete.html) | oci iam group delete \--group-id \$G |
  | [Get the information for a group](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/get.html) | oci iam group get \--group-id \$G |
  | | |

  - [**List**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/list.html)

    | Action | Command |
    | - | - |
    |[List all the groups in your tenancy](<https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/list.html>) sorted by name | oci iam group list [\--sort-by](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/list.html#cmdoption-sort-by) NAME |
    | List all the groups in a compartment[\*](#useful-examples-advanced) | oci iam group list[\--compartment-id](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/list.html#cmdoption-compartment-id) \$C |
    | | |

    **Note:** For additional **list** commands with formatted output, see [**Queries**](#queries-formatted-output) below.

  - [**List-users**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/list-users.html)

    | Action | Command |  
    | - | - |  
    | List the users in a specified group | oci iam group list-users \--group-id \$G |
    | List the users in a specified compartment[\*](#useful-examples-advanced) | oci iam group list-users \--group-id \$G [\--compartment-id](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/list-users.html#cmdoption-compartment-id) \$C |
    | | |

  - [**Remove-user**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/remove-user.html)

    | Action | Command |  
    | - | - |  
    | Remove a user from a group | oci iam group remove-user \--group-id \$G \--user-id \<*userID*\> |
    | Remove a user from a group in a particular compartment[\*](#useful-examples-advanced) |oci iam group remove-user \--group-id \$G [\--compartment-id](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/remove-user.html#cmdoption-compartment-id) \$C \--user-id \<*userID*\> |

  - [**Update**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/update.html)  

    | Action | Command |  
    | - | - |  
    | Update the specified group | oci iam group update \--group-id \$G |
    | Update the description of the specified group | oci iam group update \--group-id \$G [\--description](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/group/update.html#cmdoption-description) \<*newDescription*\> |
    | | |

- [**Compartment**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment.html)

    | Action | Command |  
    | - | - |  
    | [Create a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/create.html) | oci iam compartment create \--compartment-id \$C \--description \<*text*\> \--name \<*name_for \_the_compartment*\> |  
    | [Delete a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/delete.html) | oci iam compartment delete \--compartment-id \$C |  
    | [Recover a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/recover.html) (change compartment state from **DELETED** to **ACTIVE**) | oci iam compartment recover \--compartment-id \$C |  
    | [Get a list of all the resources inside the compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/get.html) | oci iam compartment get \--compartment-id \$C |  
    | [List compartments](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/list.html) | oci iam compartment list -c \$T |  
    | [List all availability domains within a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/availability-domain/list.html) | oci iam availability-domain list--c \$C |  
    | | |

  - [**Update**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/update.html)

    | Action | Command |  
    | - | - |  
    | Update the **name** of a compartment<br> **Note:** The name must be unique across all compartments in the parent compartment. | oci iam compartment update \--compartment-id \$C \--name \<*newName\>* |  
    | Update the **description** of a compartment | oci iam compartment update \--compartment-id \$C [\--description](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/compartment/update.html#cmdoption-description) \<*new description*\> |
    | | |  

- [**User**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/user.html)

  | Action | Command |  
  | - | - |  
  | [List](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/user/list-groups.html) all the groups | oci iam user list-groups \--user-id \<*userID*\>
  to which a user belongs |  
  | [List users and output](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/user/list.html) | oci iam user list \--compartment-id \$T \--limit \<*\#*\> |  
  | [Get user details](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/user/get.html) | oci iam user get \--user-id \<*userID*\> |  
  | [Create a new user in a tenancy](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/user/create.html) | oci iam user create -c \<*rootCompartmentID*\> \--name \<*userName*\> \--description \"\<*description*\>\" |  
  | [Delete specific API signing keys](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/iam/user/api-key/delete.html) | oci iam user api-key list \<*userID* \> |  
  | | |  

  > **Note:** The tenancy is always considered to be the root compartment; this means that when the **user-id** flag isn't used the command will default to using the tenancy as the compartment OCID.  
  {:.notice}

#### OS

Command reference: [OS](https://docs.oracle.com/en-us/iaas/tools/oci-cli/2.17.0/oci_cli_docs/cmdref/os.html)

| Action | Command |  
| - | - |  
| [Get a namespace](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/ns/get.html) | oci os ns get |  
| Get a [list of buckets](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/bucket/list.html) | oci os bucket list -ns mynamespace \--compartment-id \$C |
| | |

### Useful examples (advanced)

#### General

- Create a policy at the root level  

  ```sh
  TENANCY=$(oci iam availability-domain list --all | jq -r '.data[0]."compartment-id"')
  oci iam policy create --compartment-id $TENANCY --name <policyName> --statements '["sentence1", "sentence2"]' --description <policyDescription>
  ```

- Get a list of subscribed region names and keys  

  ```sh
  oci iam region-subscription list | jq '.data[]."region-name" | .data[]."region-key"'
  ```

- Get the base URL of an object stored in the home region  

  ```sh
  namespace=$(oci os ns get | jq -r .data)
  home=$(oci iam region-subscription list | jq -r '.data[0]."region-name"')
  echo https://objectstorage.$home.oraclecloud.com/n/$namespace/b/<bucketname>"
  ```

- List container images in a compartment  

  ```sh
  oci artifacts container image list --compartment-id <compartmentID>
  ```

  **Command reference:** [list](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/artifacts/container/image/list.html)

- Locate tenancy OCID  

  ```sh
  oci iam availability-domain list --all | jq -r '.data[0]."compartment-id"'
  ```

- Obtain OCID from compartment name  

  **Note:** Compartment names are case sensitive.  

  ```sh
  compname="<compartmentName>"
  compocid=$(oci iam compartment list --compartment-id-in-subtree true --all | jq --arg compname "$compname\" '.data[] | select(."name"==$compname)' | jq -r ."id")
  echo $compocid
  ```

- Obtain FN-OCID from COMPARTMENT OCID + APP-NAME + FN-NAME  

  ```sh
  compartment**=\"ocid1.compartment.oc1\...\...aea\" 
  appname="<appName>"
  fnname="<functionName>"
  appid=$(oci fn application list -c $compartment --all | jq --arg appname "$appname" '.data[] | select(."display-name"==$appname)' | jq -r ."id")
  fnid=$(oci fn function list --application-id $appid | jq --arg fnname "$fnname" '.data[] | select(."display-name"==$fnname)' | jq -r ."id")
  echo $fnid
  ```

- Retrieve the home region  

  ```sh
  oci iam region-subscription list | jq -r '.data[0]."region-name"'
  ```

#### Functions (fn)

CLI for the [Functions service](https://docs.oracle.com/en-us/iaas/Content/Functions/Concepts/functionsoverview.htm).  

Full set of OCI CLI [fn commands](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn.html).  

- Function

  A function resource defines the code (Docker image) and configuration for a specific function. Functions are defined in applications.  

  **Command reference:** [function](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/function.html)  

  - Create  
  
    ```sh
    oci fn function create --application-id <applicationID> --display-name <displayName> --image <imageName> --memory-in-mbs <integer>
    ```

    **Command references:** [create](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/function/create.html), [\--display-name](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/function/create.html#cmdoption-display-name), [\--image](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/function/create.html#cmdoption-image)

  - Delete  

    ```sh
    oci fn function delete --function-id <functionID>
    ```

    **Command reference:** [delete](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/function/delete.html)

  - List functions  

    List the functions associated with an application.  

    ```sh
    oci fn function list --application-id <applicationID>
    ```

    **Command reference:** [list](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/function/list.html)

- Application  

  An [application](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/application.html) contains functions and defined attributes shared between those functions, such as network configuration and configuration.  

  - List application  

    ```sh
    oci fn application list -c <compartmentID>
    ```

    **Command reference:** [list](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/fn/application/list.html)

#### Images

- Create an image  

  Creates a boot disk image for the specified instance or imports an exported image from the Oracle Cloud Infrastructure [Object Storage](#object-storage) service.  

  ```sh
  oci compute image create --compartment-id <compartmentID>
  ```

  **Command reference:** [create](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/image/create.html)

- Launch an instance from an image  

  *Refer to the related topic in the [Instances](#instances) section below.*

#### Instances

- Actions (stop/start/reset)  

  ```sh
  oci compute instance action --action [action] --instance-id [instanceID]
  ```

  Where the values of the **action** flag are:  

  STOP, START, SOFTRESET, RESET, SOFTSTOP, SENDDIAGNOSTICINTERRUPT,
  DIAGNOSTICREBOOT, REBOOTMIGRATE  

  **Command references:** [actions](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/action.html), [\--action](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/action.html#cmdoption-action)

- Launch

  Creates a new instance in the specified compartment and the specified availability domain.  

  ```sh
  oci compute instance launch --availability-domain <availability_domain> --compartment-id <compartmentID> --shape <shape> --subnet-id [subnetID]
  ```

  Where **shape** refers to the shape of the instance. The shape determines the number of CPUs, amount of memory, and other resources allocated to the instance.  

  You can enumerate all available shapes by calling [ListShapes](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.16.0/oci_cli_docs/cmdref/compute/shape/list.html).  

  **Command reference:** [launch](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/launch.html)  

- Launch an instance (from an image)  

  ```sh
  oci compute instance launch --availability-domain <availability_domain> --compartment-id <compartmentID> --shape <shape> --subnet-id [subnetID] --image-id [imageID]
  ```

  Where *imageID* is the OCID of the image used to boot the instance.  

  **Note:** This is a shortcut for specifying an image source via the
  [\--source-details](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/launch.html#cmdoption-source-details)
  complex JSON parameter.  

  > If the **image-id** parameter is used, you **cannot** provide the
  **\--source-details** or
  [**\--source-boot-volume-id**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/launch.html#cmdoption-source-boot-volume-id)
  parameters.  
  {:.warn}

- Terminate  

  Terminates the specified instance. Any attached VNICs and volumes are automatically detached when the instance terminates.  

  ```sh
  oci compute instance terminate --instance-id <instanceID>
  ```

  **Command reference:** [terminate](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/terminate.html)  

- List instances  

  ```sh
  oci compute instance list --compartment-id <compartmentID>
  ```

  **Command reference:** [list](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/instance/list.html)  

- List shapes that can be used to launch a VM instance  

  **Note:** This applies to a dedicated virtual machine host within the specified compartment.  

  ```sh
  oci compute dedicated-vm-host instance-shape list --compartment-id <compartmentID>
  ```

- Monitor  

  **Reference:** [activate plugin](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/appmgmt-control/monitored-instance/activate-plugin.html)

  - Activate instance monitoring  

    Activates the Resource plugin for the compute instance identified by the instance OCID. Stores the monitored instance's Id and state. Tries to enable the [Resource Monitoring](https://docs.oracle.com/en-us/iaas/os-management/osms/osms-resource-discovery-monitoring.htm) plugin by making remote calls to both the [Oracle Cloud Agent](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/manage-plugins.htm) and the [Management Agent Cloud Service](https://docs.oracle.com/en-us/iaas/management-agents/doc/you-begin.html).  

    ```sh
    oci appmgmt-control monitored-instance activate-plugin --monitored-instance-id <instanceID>
    ```

  - List monitored instances

    ```sh
    oci appmgmt-control monitored-instance-collection list-monitored-instances --compartment-id <compartmentID>
    ```

#### Instance pools

- Creating

  Use instance pools to create and manage multiple compute instances within the same region as a group.  

  ```sh
  oci compute-management instance-pool create --compartment-id <compartmentID> --instance-configuration-id <instanceConfigurationID> --placement-configurations <file://path/to/file.json> --size <number_of_instances>
  ```

  Where *\<file://path/to/file.json\>* is the path to a JSON file that defines the placement configuration. For information about how to generate an example of the JSON file, see [Advanced JSON Options](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliusing.htm#AdvancedJSON).  

  **Commands reference:** [creating](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/creatinginstancepool.htm)  

- Deleting

  Permanently delete instance pools that are no longer needed.  

  > When you delete an instance pool, the *resources that are associated with the pool are **permanently** deleted.*  
  {:.warn}  

  ```sh
  oci compute-management instance-pool terminate --instance-pool-id <instancePoolID>
  ```

  **Command reference:** [deleting](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/deletinginstancepool.htm)  

- Stopping and starting instances in an instance pool  

  You can stop and start individual instances in an instance pool as needed to update software or resolve error conditions (see **Actions (stop/start/reset)** in the [Instances](#instances) section above).  

  > **Note:** To stop all instances in an instance pool, stop the instance pool itself.  
  >
  > However, if you manually stop all instances in an instance pool instead of stopping the instance pool itself, the instance pool will try to relaunch the individual instances.  
  {:.notice}

  **Command reference:** [Stopping and starting instances in an instance pool](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/restartinginstancepool.htm)  

- Start all instances  

  ```sh
  oci compute-management instance-pool start --instance-pool-id <instancePoolID>
  ```

- Stop all instances  

  ```sh
  oci compute-management instance-pool stop --instance-pool-id <instancePoolID>
  ```

- Reset all instances  

  ```sh
  oci compute-management instance-pool reset --instance-pool-id <instancePoolID>
  ```

- Softreset all instances  

  ```sh
  oci compute-management instance-pool softreset --instance-pool-id <instancePoolID>
  ```

- List instances in an instance pool  

  ```sh
  oci compute-management instance-pool list-instances --compartment-id <compartmentID> --instance-pool-id <instancePoolID>
  ```

- List instance pools in a compartment  

  ```sh
  oci compute-management instance-pool list --compartment-id <compartmentID>
  ```

#### Object storage

[Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/home.htm) is a fully programmable, scalable, and durable cloud storage service.  

You can use the CLI for object operations within the Object Storage service.  

**Note:** In the OCI Object Storage service, a [*bucket*](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/managingbuckets.htm) is a container for storing objects in a compartment within an Object Storage namespace.  

For more information, see:  

A complete list of OCI CLI [Object commands](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object.html)

[Working with Oracle Cloud Storage from the Command Line](https://bakingclouds.com/working-with-oracle-cloud-storage-from-the-command-line/)

- Uploading/downloading files

  Objects can be uploaded from a file or the command line (STDIN). Likewise, they can either be downloaded to a file or the command line (STDOUT).  

  - Upload an object (file)  

    ```sh
    oci os object put -ns <myNamespace> -bn <myBucket> --name myfile.txt --file /Users/me/myfile.txt --metadata '{"key1":"value1","key2":"value2"}'
    ```

    **Command references:** [oci os object put](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html), [-bn](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-bn), [\--name](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-name), [\--file](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-file)  

  - Upload object contents (STDIN)  

    ```sh
    oci os object put -ns <myNamespace> -bn <myNucket> --name myfile.txt --file <--'object content'
    ```

    **Command references:** [oci os object put](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html), [-bn](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-bn), [\--name](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-name), [\--file](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-file)  

  - Download an object (file)  

    ```sh
    oci os object get -ns <myNamespace> -bn <myBucket> --name myfile.txt --file /Users/me/myfile.txt
    ```

    **Command references:** [oci os object get](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html), [-ns](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-ns), [-bn](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-bn), [\--name](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-name), [\--file](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-file)  

  - Output object contents (STDOUT)  

    ```sh
    oci os object get -ns <myNamespace> -bn <myBucket> --name myfile.txt --file --
    ```

    **Note:** The "--" parameter tells the **file** flag to output to **STDOUT**.  

    **Command references:** [oci os object get](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html), [-ns](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-ns), [-bn](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-bn), [\--name](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-name), [\--file](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-file)  

  - Misc  

    To get the base URL of object storage in the home region, see the associated section under [Useful examples (advanced)/General](#general).  

- Bulk operations  

  - Uploading files in a directory and all its subdirectories to a bucket  

    ```sh
    oci os object bulk-upload -ns <myNamespace> -bn <myBucket> --src-dir path/to/upload/directory
    ```

    **Command references:** [oci os object bulk-upload](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-upload.html), [\--src-dir](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-upload.html#cmdoption-src-dir)

  - Downloading all objects in a bucket  

    ```sh
    oci os object bulk-download -ns <myNamespace> -bn <myBucket> --download-dir path/to/download/directory
    ```

    **Command references:** [oci os object bulk-download](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-download.html), [\--download-dir](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-download.html#cmdoption-dest-dir)

  - Download all objects that match a specified prefix  

    ```sh
    ci os object bulk-download -ns <myNamespace> -bn <myBucket> --download-dir path/to/download/directory --prefix <myPrefix>
    ```

    **Command referenes:** [oci os object bulk-download](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-download.html), [\--prefix](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-download.html#cmdoption-prefix)

  - Delete all objects in a bucket  

    ```sh
    oci os object bulk-delete -ns <myNamespace> -bn <myBucket>
    ```

    **Command references:** [oci os object bulk-delete](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-delete.html)

  - Delete objects that match the specified prefix  

    ```sh
    oci os object bulk-delete -ns <myNamespace> -bn <myBucket> --prefix <myprefix>
    ```

    **Command references:** [oci os object bulk-delete](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-delete.html), [\--prefix](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/bulk-delete.html#cmdoption-prefix)  

- Multipart operations  

  - Uploads (large files)

    Large files (\>128 MiB) can be uploaded to [Object Storage](#object-storage) in multiple parts to speed up the upload. By default, large files are uploaded using multipart operations. You can override this default by using the **\--no-multipart** option.  

    For more information about uploading large files, see [Using Multipart Uploads](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingmultipartuploads.htm#Using_Multipart_Uploads).  

    Related options for the [**oci os object put**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html) command:  

    - [**\--no-multipart**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-no-multipart) overrides an automatic multipart upload if the object is larger than 128 MiB. The object is uploaded as a single part, regardless of size.

    - [**\--part-size**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-part-size) in MiB, to use in a multipart operation. The default part size is 128 MiB and a part size that you specify must be greater than 10MiB. If the object is larger than the value specified by **\--part-size**, it is uploaded in multiple parts.

    - [**\--parallel-upload-count**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/put.html#cmdoption-parallel-upload-count), to specify the number of parallel operations to perform. You can use this value to balance resources and upload times. A higher value may improve times but consume more system resources and network bandwidth. The default value is 10.  

    > **Note:** The [**oci cs object resume-put**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/resume-put.html) command allows you to resume a large file upload in cases where the upload was interrupted.  
    {:.notice}

  - Downloads (large files)  

    Likewise, large files can be downloaded from Object Storage in multiple parts to accelerate the process.  

    Related options for the [**oci os object get**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html) command:  

    - [**\--multipart-download-threshold**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-multipart-download-threshold) lets you specify the size, in MiB at which an object should be downloaded in multiple parts. This size must be at least 128 MiB.  

    - [**\--part-size**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-part-size), in MiB, to use for a download part. This gives you the flexibility to use more (smaller size) or fewer (larger size) parts as appropriate for your requirements. For example, compute power and network bandwidth. The default minimum part size is 120 MiB.  

    - [**\--parallel-download-count**](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/os/object/get.html#cmdoption-parallel-download-count) lets you specify how many parts are downloaded at the same time. A higher value may improve times but consume more system resources and network bandwidth. The default value is 10.  

#### Queries (formatted output)

**Contributor:** [Stefan Oehrli](https://gist.github.com/oehrlis)
([source](https://gist.github.com/oehrlis/6d85e7f2d1825ab91c29dfed14f21c0e))

- Get Public IP By Instance ID  

  ```sh
  oci compute instance list-vnics --query "data[*]"."{\"public-ip\":\"public-ip\"}" --instance-id <compartmentID>
  ```

- List active compartments  

  ```sh
  oci iam compartment list --all --output table --compartment-id-in-subtree true --query "data [?\"lifecycle-state\" =='ACTIVE'].{Name:name,OCID:id}"
  ```

- List inactive compartments  

  ```sh
  oci iam compartment list --all --output table --compartment-id-in-subtree true --query "data [?\"lifecycle-state\" !='ACTIVE'].{Name:name,OCID:id}"
  ```

- List compute images  

  ```sh
  oci compute image list --output table --query "data[*]".{"ocid:id,name:\"display-name\""} --compartment-id <compartmentID>
  ```

- List running resources across tenant  

  ```sh
  oci search resource free-text-search --text RUNNING --query "data[].{Name:\"display-name\",state:\"lifecycle-state\",id:id}"
  ```

#### OKE (Container Engine for Kubernetes)  

CLI
[reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce.html) for [OKE](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm)  

- Clusters  
  
  **Command reference:** [clusters](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/cluster.html)

- Create a Kubernetes cluster  

  ```sh
  oci ce cluster create --compartment-id <compartmentID> --kubernetes-version <version> --name <clusterName> --vcn-id <VCN_OCID>
  ```

  **Command reference:** [create a Kubernetes cluster](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/cluster/create.html)  

- Delete a Kubernetes cluster  

  ```sh
  oci ce cluster delete --cluster-id <clusterID>
  ```

  **Command reference:** [delete a Kubernetes cluster](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/cluster/delete.html)  

- [Generate token](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/cluster/generate-token.html)

  Generate an ExecCredential based token for Kubernetes SDK/CLI authentication  

  ```sh
  oci ce cluster generate-token --cluster-id <clusterID>
  ```

  **Command reference:** [generate token](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/cluster/generate-token.html)  

- List Kubernetes clusters in a compartment  

  ```sh
  oci ce cluster list --compartment-id <compartmentID>
  ```

  **Command reference:** [list Kubernetes clusters in a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/cluster/list.html)

- Node-pools  

  [Node-pools](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/node-pool.html) reference.

  - Create node pool  

    ```sh
    oci ce node-pool create --cluster-id <clusterOCID> --compartment-id <compartmentID> --name <clusterName> --node-shape <nodeShapeName>
    ```

    **Command reference:** [create node pool](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/node-pool/create.html)

  - Delete node pool  

    ```sh
    oci ce node-pool delete --node-pool-id <nodePoolID>
    ```

    **Command reference:** [delete node pool](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/node-pool/delete.html)  

  - Delete node in a node pool  

    ```sh
    oci ce node-pool delete-node --node-id <computeInstanceID> --node-pool-id <nodePoolID>
    ```

    **Command reference:** [delete node](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/node-pool/delete-node.html)  

  - List all pools in a compartment  

    ```sh
    oci ce node-pool list --compartment-id <compartmentID>
    ```

    **Command reference:** [list all pools in a compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/ce/node-pool/list.html)  

- Automation  

  - [Scheduling OCI CLI commands to run via a Kubernetes CronJob](https://blog.bytequalia.com/scheduling-oci-cli-commands-to-run-via-a-kubernetes-cronjob/)

#### Security - Threat Intelligence

When [Cloud Guard](https://docs.oracle.com/en-us/iaas/cloud-guard/home.htm) is enabled in your tenancy, it provides threat detection using Threat Intelligence data.  

The [Threat Intelligence](https://docs.oracle.com/en-us/iaas/Content/threat-intel/home.htm) service is used to search for information about known threat indicators, including suspicious IP addresses, domain names, and other digital fingerprints.  

**For more information, see:**  

[Overview](https://docs.oracle.com/en-us/iaas/Content/threat-intel/using/overview.htm) of the Threat Intelligence service.  

- List threat indicators  

  ```sh
  oci threat-intelligence indicator-summaries list-indicators --compartment-id <compartmentID>
  ```

  **Command reference:** [list threat indicators](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/threat-intelligence/indicator-summaries/list-indicators.html)  

- List threat indicators for a particular IP address  

  ```sh
  oci threat-intelligence indicator-summaries list-indicators --compartment-id <*root_ compartmentID> --type IP_ADDRESS --value <indicator_IP>
  ```

  **The supported indicator types are:**  
  IP_ADDRESS, DOMAIN_NAME, URL, MD5_HASH, SHA1_HASH, SHA256_HASH, and
  FILE_NAME.  

  **Command reference:** [list threat indicators for a particular IP address](https://docs.oracle.com/en-us/iaas/Content/threat-intel/using/database.htm#use_cli)  

- List threat indicators of a particular thread type and a minimum confidence score  

  ```sh
  oci threat-intelligence indicator-summaries list-indicators --compartment-id <*root_ compartmentID> --threat-type-name phishing --confidence-above 50
  ```

  See [Threat Types](https://docs.oracle.com/en-us/iaas/Content/threat-intel/using/database.htm#threat_types) or use:  

  ```sh
  oci threat-intelligence threat-types-collection list-threat-types --compartment-id <root_compartmentID>
  ```

  **Command reference:** [list threat indicators of a particular thread type and a minimum confidence score](https://docs.oracle.com/en-us/iaas/Content/threat-intel/using/database.htm#use_cli)  

#### Virtual Machine (VM) hosts

- List VMs  

  Returns a list of dedicated virtual machine hosts that match the specified criteria in the specified compartment.  
  
  ```sh
  oci compute dedicated-vm-host list --compartment-id <compartmentID>
  ```

  **Command reference:** [list VMs](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/dedicated-vm-host/list.html)  

- List VM host instances

  ```sh
  oci compute dedicated-vm-host-instance list --compartment-id <compartmentID> --dedicated-vm-host-id <dedicatedVMhost_ID>
  ```

  **Command reference:** [list VM host instances](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/dedicated-vm-host-instance/list.html)  

- Get information about a VM  

  ```sh
  oci compute dedicated-vm-host get --dedicated-vm-host-id <dedicatedVMhost_ID>
  ```

  **Command reference:** [get information about a VM](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/dedicated-vm-host/get.html)  

- Create a VM  

  ```sh
  oci compute dedicated-vm-host create --dedicated-vm-host-shape <shapeName> --wait-for-state ACTIVE --display-name <displayName> --availability-domain <availability_domain> --compartment-id <compartmentID>
  ```

  where *\<shape_name\>* is the [shape](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm#dedicatedvmhost) for the dedicated virtual machine host  

  > **Note:** It can take up to 15 minutes for the dedicated virtual machine host to be fully created. It must be in the **ACTIVE** state before you can launch an instance on it.  
  {:.alert}

  **Command reference:** [create a VM](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/dedicatedvmhosts.htm#create). [create](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.17.0/oci_cli_docs/cmdref/compute/dedicated-vm-host/create.html)  

- Delete a VM  

  ```sh
  oci compute dedicated-vm-host delete --dedicated-vm-host-id <dedicatedVMhost_ID>
  ```

  **Command reference:** [delete a VM](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/dedicatedvmhosts.htm#delete), [delete](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.17.0/oci_cli_docs/cmdref/compute/dedicated-vm-host/delete.html)  

- Move a VM to another compartment  

  ```sh
  oci compute dedicated-vm-host change-compartment --compartment-id <compartmentID> --dedicated-vm-host-id <dedicatedVMhost_ID>
  ```

  **Command reference:** [move a VM to another compartment](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/compute/dedicated-vm-host/change-compartment.html)  

## Other resources  

### DevOps Tools and Plug-Ins  

[Reference](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/devopstools_topic-DevOps_Tools_and_Plugins.htm)  

- [OCI Module for PowerShell](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/powershell.htm)

- [Terraform Provider](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm#Terraform_Provider)

- [Ansible Collection](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/ansible.htm)

- [Ansible OCI Guide](https://docs.ansible.com/ansible/latest/scenario_guides/guide_oracle.html)

### Open source at Oracle  

- [Open Source at Oracle -- Developer Resource Center](https://developer.oracle.com/open-source/)

- [Open Source at Oracle - GitHub resources](https://github.com/oracle)

### Scripts and automation  

> **Disclaimer:** All code in this section should be considered proof-of-concept, used primarily for demonstration purposes, and not supported by Oracle. The code here should not be used in its present form for Production purposes.  
{:.alert}

#### Scripts (general)  

- [OCI Scripts and example code](https://www.oc-blog.com/oci-scripts-and-example-code/) (list of links, various contributors)

- [OCI scripts](https://github.com/cpauliat/my-oci-scripts) (GitHub repo)

  **Contributors:** Christophe Pauliat (**cpauliat**) and Çetin Ardal (**kral2**)

- [OCI scripting with OCI CLI](https://s3.amazonaws.com/bizzabo.file.upload/vWcLJPyQe2escA6r6gPW_MarzOCI%20CLI%20Scritping.pdf) (pdf)

#### Scripts (specific applications)  

- [How to list all Oracle Cloud Infrastructure instances and their IP addresses](https://medium.com/oracledevs/writing-python-scripts-to-run-from-the-oci-console-cloud-shell-a0be1091384c)

  **Contributor:** Stephen Cross (Product Manager, Oracle Cloud Infrastructure)

- [Oracle Cloud Infrastructure CLI Scripting: How to Quickly Override the Default Configuration](https://www.ateam-oracle.com/post/oracle-cloud-infrastructure-cli-scripting-how-to-quickly-override-the-default-configuration)

  **Contributor:** [Olaf Heimburger](https://blogs.oracle.com/authors/olaf-heimburger)

- [Easy Provisioning Of Cloud Instances On Oracle Cloud Infrastructure With The OCI CLI](https://blogs.oracle.com/linux/post/easy-provisioning-of-cloud-instances-on-oracle-cloud-infrastructure-with-the-oci-cli) (Oracle blog)  

  **Contributor:** [Philippe Vanhaesendonck](https://blogs.oracle.com/authors/philippe-vanhaesendonck)

- [Lab 13: Use OCI CLI commands to work with ExaCS](https://www.oracle.com/?bcid=6178484144001) (video)

  [Exadata Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/exadatacloud/index.html) allows you to leverage the combined capabilities of Oracle Exadata and Oracle Cloud Infrastructure.  

  [Oracle Exadata Database Service](https://www.oracle.com/engineered-systems/exadata/database-service/) is an automated Oracle Database service that allows organizations to run databases with the highest performance, availability, security,and cost effectiveness.

- Databases

  - [Automated CLI Scripts to Scale Autonomous Database CPUs](https://www.ateam-oracle.com/post/automated-cli-scripts-to-scale-autonomous-database-cpus)  

    **Contributor:** [Vivek Singh](https://blogs.oracle.com/authors/vivek-singh)

  - [Automate Patching and Upgrade your Cloud Databases using OCI CLI](https://database-heartbeat.com/2021/01/14/automate-patching-and-upgrade-your-cloud-databases-using-oci-cli/)  

    **Contributor:** Sinan Petrus Toma

  - [OCI Database Cloud Service Patching of Database and Grid Infrastructure Using OCI CLI](https://blog.pythian.com/oci-database-cloud-service-patching-of-database-and-grid-infrastructure-using-oci-cli/)  

    **Contributor:** Abhilash Kumar  

- Infrastructure  

  - Bastion Service  

    - [OCI Bastion Service Part II: Create Bastion service using OCI CLI & Terraform](http://www.brokedba.com/2022/03/oci-bastion-service-part-ii-create.html)  

      **Contributor:** Kosseila Hd

  - [OCI Bastion Service: An Alternate way of connecting to your private resources using OCI-CLI](https://medium.com/oracledevs/oci-bastion-service-an-alternate-way-of-connecting-to-your-private-resources-using-oci-cli-d9c829685c77)  

    **Contributor:** Shadab Mohammad (Principal Cloud Solutions Architect)  

  - Terraform  

    - [IaC in the Cloud: Integrating Terraform and Resource Manager into your CI/CD Pipeline - Building with the OCI CLI](https://recursive.codes/blog/post/1788)  

      **Contributor:** Todd Sharp  

- Security  

  - [A simple guide to adding rules to security lists using OCI CLI](https://blogs.oracle.com/cloud-infrastructure/post/a-simple-guide-to-adding-rules-to-security-lists-using-oci-cli)

### SDKs

- [SDKs for the CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdks.htm)

  Oracle Cloud Infrastructure provides several Software Development Kits (SDKs) and a Command Line Interface (CLI) to facilitate the development of custom solutions.  

  **SDKs:** Java, Python, TypeScript and JavaScript, .NET, Go, Ruby, PL/SQL  

  > **Note:** The **PL/SQL SDK** enables you to write code to manage OCI resources. The latest PL/SQL SDK version is pre-installed by Oracle for all Autonomous Databases using shared Exadata infrastructure.  
  {:.notice}

- [Main Oracle Python SDK examples](https://github.com/oracle/oci-python-sdk/tree/master/examples)

- [Automating developer setup in Oracle Cloud Infrastructure](https://blogs.oracle.com/cloud-infrastructure/post/automating-developer-setup-in-oci) (Oracle blog)  

  **Contributor:** Philip Wilkins

### Services  

#### Anomaly Detection Service  

- [Access Anomaly Detection Service with OCI CLI](https://oracle.github.io/learning-library/oci-library/oci-hol/oci-artificial-intelligence/anomaly-detection/workshops/freetier/?lab=anomaly-detection-oci-cli)

- [Anomaly Detection Service](https://www.oracle.com/artificial-intelligence/anomaly-detection/)

#### Databases

- MySQL Database Service

  - [Manage MySQL Database Service (MDS) DB Systems with OCI CLI](https://www.mortensi.com/2020/11/manage-mysql-database-service-mds-db-systems-with-oci-cli/)

  - [How to install OCI-CLI on Oracle DBCS instance](https://qiita.com/liu-wei/items/ff455a12a0f2580d48ce)

- Oracle Database Service  

  - [Oracle Database on OCI](https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/databaseoverview.htm)

  - [OCI CLI db commands](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.15.1/oci_cli_docs/cmdref/db.html)

#### IAM (Identity and Access Management)  

- [Calling OCI CLI Using Instance Principal](https://www.ateam-oracle.com/post/calling-oci-cli-using-instance-principal)

#### Vision

[AI Vision reference page](https://www.oracle.com/artificial-intelligence/vision/)

OCI Vision is a serverless, cloud-native service that provides deep learning-based, prebuilt, and custom computer vision models over REST APIs. OCI Vision helps you identify and locate objects, extract text, and identify tables, document types, and key-value pairs from business documents like receipts. No data science experience is required to use the prebuilt or custom features of OCI Vision.  

You can access the service through the [Oracle Cloud Console](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/console.htm), OCI software developer kits (SDKs) in [Python](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/pythonsdk.htm#SDK_for_Python) and [Java](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/javasdk.htm#SDK_for_Java), or the OCI CLI.  

For more information, see:  

- [Service documentation and Tutorials](https://docs.oracle.com/en-us/iaas/vision/vision/using/home.htm)

- [SDKs and CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdks.htm)

- [Vision OCI CLI commands](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.16.0/oci_cli_docs/cmdref/ai-vision.html)

### Training  

- [Oracle LiveLabs](https://github.com/oracle-livelabs)  

  [LiveLabs](https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/home) is the place to explore Oracle\'s products and services using workshops designed to enhance your experience building and deploying applications on the Cloud and On-Premises. Use your existing [Oracle Cloud account](https://docs.oracle.com/en/cloud/get-started/subscriptions-cloud/csgsg/get-oracle-com-account.html), a [Free Tier account](https://www.oracle.com/cloud/free/), or a LiveLabs Sandbox reservation to build, test and deploy applications on Oracle's Cloud.

- [OCI Workshops and Sprints](https://apexapps.oracle.com/pls/apex/f?p=133:100:29934050917174::::SEARCH:OCI%20cli)

- [**Oracle Quick Start** - Automated deployments of enterprise software on OCI](https://github.com/oracle-quickstart)

- [Oracle Cloud Infrastructure -- build your OCI knowledge with free digital training](https://education.oracle.com/learn/oracle-cloud-infrastructure/pPillar_640)

- [Oracle Help Center **Learn** -- OCI CLI](https://docs.oracle.com/learn/?q=OCI%20CLI&sort=&lang=en)

- [**Oracle Learning** Videos -- OCI CLI](https://www.youtube.com/user/OracleLearning/search?query=oci%20cli)
