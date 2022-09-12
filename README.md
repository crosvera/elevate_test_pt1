# Elevate DevOps test pt1
## The problem
Every 3 weeks, as part of our release process, we create a release branch in our git repositories from the commit we would like to release. Branch names follow the “release/[version convention, where the version is a semantic version, e.g. 1.66.0. For each release branch, we increment the version. Creating the branches manually has the potential for error, and we would also like to increase the frequency at which we release, so we would like to automate this process.
Please implement an automatic way to create these release branches in our git repositories. Your solution should also automatically increment the version from the previous release, and should run on a regular schedule.

## Solution
For this solution I use a node-base tool that handles semantic versioning. The tool called [semantic-release](https://github.com/semantic-release/semantic-release) automatically creates new versions based on new commits and it can be integrated with common CI solutions like GitHub Actions as in this implementation.

First, in order to create a new branch per each new version, we need to create a configuration file for `semantic-release` called `.releaserc.yaml` at the root path of the repository:

```yaml
branches:
  - main
debug: true
ci: true
dryRun: false
tagFormat: v${version}
plugins:
  - "@semantic-release/commit-analyzer"
  - "@semantic-release/release-notes-generator"
  - "@semantic-release/github"
  - path: "@semantic-release/exec"
    successCmd: bash branch.sh "${nextRelease.version}"

```

`semantic-release` by default, creates a new tag with the new version and it uses to create the next ones. The format of the tags is configured in the `tagFormat` section.
In order to create a new branch from the new version, we need to use a plugin called `semantic-release/exec` which allows the execution of custom code at the moment of a new version is created. We set the command to run with the `successCmd` option, which only run if a new version is created. The command running here: `bash branch.sh "${nextRelease.version}"` is a simple bash script called `branch.sh` which accepts as a paremeter the new version that was created.

```bash
#!/usr/bin/bash

NEXTVER=$1
git config user.name "GitHub Actions"
git config user.email noreply@github.com
git checkout -b release/$NEXTVER
git push origin release/$NEXTVER

```

In this bash script we accept the new version as parameter in order to create a new branch and push it to the repository. If you want another branch name format, you should edit the last two lines where says `realease/$NEXTVER`.


In order to run all of these, a github action called `release.yaml` was created:

``` yaml
name: Release
on:
  schedule:
    - cron: '0 4 * * 1'

jobs:
  date:
    name: Date
    runs-on: ubuntu-latest
    steps:
      - name: Get current week number
        run: echo "MODWEEK=$(( `date +%V` % 3 ))" >> $GITHUB_ENV
    outputs:
      modweek: ${{ env.MODWEEK }}

  release:
    name: Release
    needs: date
    if: needs.date.outputs.modweek == '0'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: 'lts/*'
      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: |
          npm install @semantic-release/exec -D
          npx semantic-release

```

We configure this action to run every Monday at 4am. To ensure that the new release is created every 3 weeks, we create a first job in this Action, which gets the current week of the year and then we apply the modulo 3, and finally a second job checks if the previous modulo result is equal to 0 before executing `semantic-release`.