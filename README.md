## `dynamic-continuation` Orb for CircleCI

This orb is based on a [published example](https://github.com/circle-makotom/circle-advanced-setup-workflow) of advanced configuration with continuations from CircleCI.

The orb's intended use is to aid in the simplification of the default `.circleci/config.yml` by allowing users to add additional configs under `.circleci` matching top-level directories that run only when the code therein contains actual changes. This approach offers engineers reduced pipeline execution time, and by extension, reduced CI costs.

### How it works

You'll need to add this orb, as well as an `extend` job to your workflow (likely appended to the end), and the `setup` keyword, such as

```
setup: true

orbs:
  dynamic: bjd2385/dynamic-continuation@3.0.0

workflows:
  on-commit:
    jobs:
      - dynamic/extend:
          context: orb-publishing
          modules: |
            ... list of config file names under .circleci/ with corresponding, top-level directories of the same name.
```

from here, move any jobs, workflows, or orbs, to their new configs, again with matching top-level directory names.

> **Aside:** Not all module configs must be valid. Because the additional configs are called in separate workflow(s), only the final, merged image need be valid if checked via `circleci config validate /path/to/generated/config.yml`. This said, it's probably best if you have a valid config in each module, for ease of development.

#### When will the orb run my workflows?

The orb will run a workflow (we'll call it `<module>`) if any of the following conditions are met.

1. If `.circleci/<module>.yml` changes.
2. If there have been no workflows on the repository's default branch in the past 90 days (by default, but [this is configurable](https://circleci.com/docs/api/v2/#operation/getProjectWorkflowMetrics)).
3. If changes have been detected within the `<module>/`'s directory on your branch against the repository's default branch (defaults to `master`). See below on how to filter by or out specific changed files [below](#filtering-or-ignoring-changed-files).
4. If, following merge to the module's default branch, there are changes to `.circleci/<module>.yml` or under `<module>/`, when diffing against the former commit (you must perform a merge commit for this to work properly).

These conditions can be overriden, and all workflows forced to run, if the `force-all` parameter is set to `true` on the `extend` job.

#### Example

If you have a directory layout

```
.circleci/config.yml
terraform/
scripts/
src/
```

with the addition of this orb, a user could define targeted configs

```
.circleci/config.yml
.circleci/terraform.yml  # targets changes under the 'terraform/' directory
.circleci/scripts.yml    # targets changes under the 'scripts/' directory
.circleci/src.yml        # targets changes under the 'src/' directory
terraform/
scripts/
src/
```

that, once again, only execute when any code changes are introduced to the containing "module". If no changes are made in a PR within the `terraform/` directory, none of the jobs or workflows defined therein are executed by the default config.

### Filtering or ignoring changed files

At times, there may be files that change in modules that should _not_ cause workflows to run. These could include, as an example, updated markdown or README-like files.

To solve this problem, the orb has the ability to read an optional `.gitignore`-like filter on each module, named `.circleci/<module>.ignore`, to prevent detected changed files on your PR from enabling workflows.

#### Example

Starting with the same directory layout as above, we could add `.gitignore`-like files

```
.circleci/config.yml
.circleci/terraform.yml
.cirlceci/terraform.ignore  # optionally ignore changes under 'terraform/' directory
.circleci/scripts.yml
.cirlceci/scripts.ignore    # optionally ignore changes under 'scripts/' directory
.circleci/src.yml
.cirlceci/src.ignore        # optionally ignore changes under 'src/' directory
terraform/
scripts/
src/
```

These files are automatically referenced, and do not need to be explicitly specified, with a job as

```
workflows:
  on-commit:
    jobs:
      - dynamic/extend:
          context: orb-publishing
          modules: |
            src
            terraform
            scripts
```

or, exactly the same as above.

### Specifying a different workflow for your repository's root directory

Many times, we'd like to run a specific workflow against the root of a repository's directory structure, offering overlapping workflows and more flexibility on file changes when paired with the above strategies. We can accomplish this by specifying `.` as a module. For example,

```
workflows:
  on-commit:
    jobs:
      - dynamic/extend:
          context: orb-publishing
          root-config: app  # Defaults to 'app.yml' and 'app.ignore' under .circleci/, should the orb detect a '.'- or root-module
          modules: |
            terraform
            .
```

Note that this requires you define an `app.yml`, at a bare minimum, under `.circleci/`, for the orb to process. This is about as complex a CI config can get as well, with the above `extend` job call requiring a directory layout of

```
.circleci/config.yml
.circleci/terraform.yml
.cirlceci/terraform.ignore  # optional
.circleci/app.yml
.cirlceci/app.ignore        # optional
terraform/
```

### Config validation with `pre-commit`

Standard CircleCI config validation pre-commit hooks will only validate the default config at `.circleci/config.yml`. I recommend using [my pre-commit hook](https://github.com/bjd2385/circleci-config-pre-commit-hook) if you're using this orb in your project as it will further validate reduced configs, if they exist. Append the following to your `.pre-commit-config.yaml`:

```
- repo: https://github.com/bjd2385/circleci-config-pre-commit-hook
    rev: v1.0.3
    hooks:
      - id: circleci-config-validate
```

### Live Examples of dynamic-continuation

I use and test this orb in my own projects.

- I have a live example of using this orb with [a root module](#specifying-a-different-workflow-for-your-repositorys-root-directory) in my [astronaut count](https://github.com/bjd2385/astronautcount/) Twitter bot repository.

### Development

This orb has been developed in _unpacked_ form. You may view its packed source with

```shell
$ circleci orb pack src/ > orb.yml
```

and further validate the resulting orb definition with

```shell
$ circleci orb validate orb.yml
```

#### Publishing a production-ready version

To publish your changes to the CircleCI registry, tag this repo, incrementing to the required version.

#### `pre-commit`

This repository uses `pre-commit` to uphold certain code styling and standards. You may install the hooks listed in [`.pre-commit-config.yaml`](.pre-commit-config.yaml) with

```shell
$ yarn install:pre-commit-hooks
```
