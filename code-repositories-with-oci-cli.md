The first thing you need to do to start using Code Repositories is to create a Project to host your new repository.

1. Navigate to [cloud.oracle.com][1]
2. Click the "hamburger" icon in the upper left.
3. Type "projects" in the search field, then click "Projects DevOps" on the right.

	![Screenshot of: Type "projects" in the search field, then click "Projects DevOps" on the right.][3]
4. Click the "Choose a compartment" field and select your compartment.

	![Screenshot of: Click the "Choose a compartment" field and select your compartment.][4]

5. Click "Create devops project"

	![Screenshot of: Click "Create devops project"][5]
6. Type a name for your project, in this case I'm using RepositoryDemo

7. Click "Select topic"

8. You need to assign a topic to the project. If you don't have any topics available, you'll need to add at least one to your instance.
	
	![Screenshot of: Click "Select topic"][6]

	![Select topic][7]
9. Click "Create devops project"

	![Screenshot of: Click "Create devops project"][8]  


	[1]: https://cloud.oracle.com/
	[2]: assets/code-repo-step1.jpg
	[3]: assets/code-repo-step2.jpg
	[4]: assets/code-repo-step3.jpg
	[5]: assets/code-repo-step4.jpg
	[6]: assets/code-repo-step5.jpg
	[7]: assets/code-repo-step6.jpg
	[8]: assets/code-repo-step7.jpg

### Creating the repository

Once you have a Project created, you can use the `oci` command line tool to generate a repo. You can do this either in the Cloud Shell, or in you local Terminal if you have `oci` installed.

To create a repository, we'll use [`oci create`](https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/devops/repository/create.html).

	oci devops repository create --name "NAME-OF-PROJECT" --project-id "OCID_FOR_PROJECT" --repository-type HOSTED

`--name` is the name of the project for which you're creating the new repo. `--project-id` needs to be the OCID for the project, which you can copy from the project overview in the console. The `--repository-type` should be HOSTED to create a repository you can remotely access with SSH.

<!-- TODO: How to set up an SSH key and configure git to use the remote repository. -->
