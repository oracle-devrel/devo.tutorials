---
title: "Creating Oracle Code Repositories using the oci CLI"
description: "Fast track repository creation using the oci command line tool."
date: 2023-01-26 12:00
parent: [tutorials]
---
The first thing you need to do to start using Code Repositories is to create a Project to host your new repository. If you already have a project, you'll just need its OCID and you can skip to the next section.

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

Take note of the OCID of the new project, you'll need it in the next steps. You can just click on "Copy" next to the OCID label to copy the (rather long) string to your clipboard automatically.

### Creating the repository

Once you have a Project created, you can use the `oci` command line tool to generate a repo. You can do this either in the Cloud Shell, or in you local Terminal if you have `oci` installed.

To create a repository, we'll use [`oci create`](https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/devops/repository/create.html).

	oci devops repository create --name "NAME-OF-PROJECT" --project-id "OCID_FOR_PROJECT" --repository-type HOSTED

`--name` is the name of the project for which you're creating the new repo. `--project-id` needs to be the OCID for the project, which you can copy from the project overview in the console. The `--repository-type` should be HOSTED to create a repository you can remotely access with SSH.

You can now retrive the SSH URL for your repository using the `list` command:

	oci devops repository list --project-id "OCID_FOR_PROJECT"

You'll see an entry for `ssh-url` in the response.

### Using the repository

1. First, create a new directory on your local machine where you want to store your code. This can be done by opening the command prompt or terminal and navigating to the desired location, then using the command `mkdir [directory name].`
2. Next, initialize the directory as a Git repository by using the command `git init` within the newly created directory.
3. Connect your local repository to a remote repository by using the command `git remote add origin [ssh URL from above]`. This allows you to push and pull code from the remote repository to your local machine.
4. Create a new file in the directory, for example, `example.sql` and add some sample code to it.
5. Use the command `git add [file name]` to add the new file to the repository.
6. Use the command `git commit -m [commit message]` to commit the changes to the repository.
7. Finally, use the command `git push origin master` to push the changes to the remote repository.

Your Oracle code repository is now set up and ready to use. You can continue to add and commit code changes as needed, and use the `git pull` command to retrieve updates from the remote repository.
