---
title: Using Git in Oracle Code Editor
parent: tutorials
tags:
- cloudeditor
- oci
- git
categories:
- oci
date: 2023-05-10 12:00
description: Learn how to set up and work with a Git repository inside of Oracle Code Editor, included in your Oracle Cloud account
author: brett-terpstra
---
Code Editor is a fantastic tool provided as part of your Oracle Cloud interface, and available in [OCI Free Tier]({{site.urls.always_free}}). It's a slimmed down version of VS Code, right in your browser, directly connected to Oracle Resource Manager and all of the files and projects in your cloud account.

Code Editor is available from the Developer Tools menu on the right side of the menu bar.

{% imgx assets/code-editor-oci-menu-code-editor-1024.jpg "Opening Code Editor" %}

Once the Code Editor is initialized for your tenancy, you'll be presented with the main interface:

{% imgx assets/code-editor-code-editor-1024.jpg "Code Editor" %}

One of the easiest ways to get files into Code Editor and work with them is using Git, which is built into Code Editor.

The first thing you should do is set up your Git user email and user name. To do so, open a terminal inside of Code Editor by selecting **Terminal->New Terminal** in the Code Editor menu bar. 

{% imgx assets/code-editor-new-terminal-1024.jpg "Opening a Terminal" %}

Once that's open, you can just run the following commands at the prompt, inserting your own user details:

```console
git config --global user.email "your.email@address.com"
git config --global user.name "Your Name"
```

{% imgx assets/code-editor-git-config-terminal-1024.jpg "Configuring Git" %}

Now when you create commits from inside of Code Editor, they'll be properly attributed. It actually won't let you commit without either entering these details or disabling the user info requirement in preferences. If you're working on your own repository and want to bypass the requirement, open **File->Preferences**, type in `git config` in the search field, and uncheck the option titled **Require Git User Config**.

{% imgx assets/code-editor-require-git-config-1024.jpg "Disabling Git config requirement" %}

Next, clone a repository. This can be any web-accessible git repository, such as a GitHub repository you want to work with, or a Code Repository you've set up in an Oracle Project. To clone a new repository, first open the SCM (Source Code Management) panel in Code Editor.

{% imgx assets/code-editor-scm-panel-1024.jpg "SCM panel" %}

From the `...` menu, select Clone.

{% imgx assets/code-editor-scm-clone-1024.jpg "Clone" %}

In the field that appears at the top of the editor, paste in the URL for the repository you want to work with. Repository addresses using ssh or git protocols would require extra setup, so using an `https` url is preferred. Click the checkmark to clone the repo. Any errors encountered will be presented in a dialog box, and you can see the actual Git output by clicking the info button in the dialog.

{% imgx assets/code-editor-clone-from-url-1024.jpg "Clone from URL" %}

Once the repo is cloned, Code Editor will ask you if you want to open it in its own workspace, or add it to the current workspace. This is entirely your choice, depending on the type of repo you're working with and how you want to interface with any other files you may have open.

{% imgx assets/code-editor-open-or-workspace-1024.jpg "Open or Open in Workspace" %}

Switch back to the Explorer view in the Workspace and click any file to edit it. As you make changes, you can make regular commits by going back to the SCM panel, selecting which files to stage (hover and click the plus button to stage), enter a brief commit message, and click the checkmark at the top to add the commit. If you don't stage any files, Code Editor will offer to stage all changes at the time of the commit.

{% imgx assets/code-editor-stage-changes-1024.jpg "Stage Changes" %}

You can also use the `...` menu to stage or commit all changes.

Once you're ready to push your commits, use the `...` menu to select **Push/Pull->Push**. If authentication is required, it will be requested in a field at the top of the editor.

That's just an overview. Code Editor provides very complete Git capabilities, including branching, multiple remotes, stashes, and tags. See the `...` menu of the SCM panel for more options.

{% imgx assets/code-editor-more-actions-1024.jpg "More actions" %}

One side note: if you leave a tab with code editor open long enough to time out, "continuing the session" will leave your SCM repositories in limbo. The best solution is to close Code Editor and log back into Oracle Cloud, then launch Code Editor again.
