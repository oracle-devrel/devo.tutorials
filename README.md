# How to contribute

Oracle welcomes contributions to this repository from anyone.

If you want to submit a pull request to fix a bug or enhance an existing feature, please first open an issue and link to that issue when you submit your pull request.

If you have any questions about a possible submission, feel free to open an issue too. The contribution process is super simple. Below is what you have to do.

## Set up your working repo

1. Fork the original repo on your GitHub account
2. Clone forked version and move into its directory

```git clone https://github.com/<myprofile>/devo.tutorials.git```

3. Add the remote upstream:

```git remote add upstream https://github.com/oracle-devrel/devo.tutorials.git```

### Add/modify your content in a branch

1. Run `git checkout main`  to make sure the new branch comes from the main branch

2. Create the new branch and switch to it: 

```git checkout -b issue-<number>```

3. Write your content, then _stage_ and _commit_ it
   * ```git add .```
   * ```git commit -s```

4. Add your comments and use [keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword) to link to your issue.

5. Push your changes to your fork:

```git push origin issue-<number>``

### Submit a Pull Request (PR)

1. Create a Pull Request for your branch on GitHub by visiting your forked repo page.

> When you create the PR, make sure to check the <ins>"***Allow edits by maintainers***"</ins> option in the PR. This allows for easy, rapid modifications that our tech editors might provide.

2. After you submit the Pull Request, sit tight and look for any comments, edits, approvals or rejections!

### Cleanup / Align to the source repo

1. Once your PR has been approved and merged, it's time to do update your local repo.

2. Ensure you are on main:
   ```git checkout main```

3. Update your local ```main``` branch:
  `git pull upstream main`

4. Remove merged branch
    - Run `git branch -D issue-<number>`
5. Update your ```main``` on your GitHub:

   ```git push origin main```
6. Remove the branch from your forked repo:
    - `git push --delete origin issue-<number>`

## How to test your edits

We don't have a staging environment right now. However if you want to see how things will render while you're working on them you can take a look [here](https://github.com/oracle-devrel/cool.devo.build/blob/main/test/README.md)

---

## What our tech editors do

When a PR is received, our tech editors will usually refactor the content a bit, with the goal to make conveying your message as clearly as possible.  Below is the process they go through:

* `git remote add pr<PR #> git@github.com/<your GH username>/devo.tutorials.git`
* `git fetch pr<PR #> issue-<number>`
* `git checkout -b pr<PR #> pr<PR #>/issue-<number>`
* Changes/edits are made
* `git add .`
* `git commit -m "Suggested edits for PR<PR #>"`
* `git push -f pr<PR #> HEAD`

After the above is completed, the edited version will be included in the PR, at which point it can be merged (while still retaining the history and flow of the content).
