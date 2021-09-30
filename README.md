# How to contribute

We've strived to make the contribution process super simple!  Simply fork this project, add/modify your content and submit a Pull Request.  When you create the Pull Request, make sure to check the "Allow edits by maintainers" option in the Pull Request.  This allows for easy, rapid modifications that our tech editors might provide.  After you submit the Pull Request, sit tight and look for any comments, edits, approvals or rejections!

# What our tech editors do

When a PR is received, our tech editors will usually refactor the content a bit, with the goal to make conveying your message as clearly as possible.  Here's the process they go through to do this:

* `git remote add pr<PR #> git@github.com/<your GH username>/cool.devo.build.git`
* `git fetch pr<PR #> main`
* `git checkout -b pr<PR #> pr<PR #>/main`
* Changes/edits are made
* `git add *`
* `git commit -m "Suggested edits for PR<PR #>"`
* `git push -f pr<PR #> HEAD:main`

After the above is completed, the edited version will be included in the PR, at which point it can be merged (while still retaining the history and flow of the content).
