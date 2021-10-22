# How to contribute

We've strived to make the contribution process super simple!  Here it is the process you should follow to contribute to this project.

## Setup your working repo

1. Fork original repo on your GH account
2. Clone forked version and move into its directory
3. Run `git remote add upstream https://github.com/oracle-devrel/devo.tutorials.git`

### Add/modify your content in a branch

1. Run `git checkout main`  to make sure the new branch comes from master
2. Create the new branch and switch to it: `git checkout -b <BRANCH_NAME>`
3. Do your implementation, then _stage_ and _commit_ it
   * `git add .`
   * `git commit -am "insert your comments here"`

### Submit a Pull Request (PR)

1. Before submit a PR, check if any commits have been made to the upstream main by running:
    * `git fetch upstream`
    * `git checkout main`
    * `git merge upstream/main`
2. If any new commits, rebase your branch
    * `git checkout <BRANCH_NAME>`
    * `git rebase main`
3. Commit and Push changes
    * `git add .`
    * `git commit -m "insert here your comments"`
    * `git push origin <BRANCH_NAME>`
4. Create a Pull Request for your branch on GitHub by visiting your forked repo page.
>When you create the PR, make sure to check the <ins>"***Allow edits by maintainers***"</ins> option in the PR. This allows for easy, rapid modifications that our tech editors might provide.
5. After you submit the Pull Request, sit tight and look for any comments, edits, approvals or rejections!

### Cleanup / Align to the source repo

1. Once your PR has been approved and merged, it's time to do some cleanup.
2. Run `git pull upstream main`
3. Remove merged branch
    1. Run `git checkout main`  
    2. Run `git branch -d <BRANCH_NAME>`
4. Commit
5. Update the master branch in your forked repo
    1. Run `git push origin main`
6. Remove the branch from your forked repo
    1. Run `git push --delete origin <BRANCH_NAME>`

## How to test your edits

We don't have a staging environment right now. However if you want to see how things will render while you're working on them you can take a look [here](https://github.com/oracle-devrel/cool.devo.build/blob/main/test/README.md)

---

## What our tech editors do

When a PR is received, our tech editors will usually refactor the content a bit, with the goal to make conveying your message as clearly as possible.  Here's the process they go through to do this:

* `git remote add pr<PR #> git@github.com/<your GH username>/devo.tutorials.git`
* `git fetch pr<PR #> <your BRANCH_NAME>`
* `git checkout -b pr<PR #> pr<PR #>/<your BRANCH_NAME>`
* Changes/edits are made
* `git add .`
* `git commit -m "Suggested edits for PR<PR #>"`
* `git push -f pr<PR #> HEAD`

After the above is completed, the edited version will be included in the PR, at which point it can be merged (while still retaining the history and flow of the content).
