## `dynamic-continuation` Orb for CircleCI

This orb is based on a [published example](https://github.com/circle-makotom/circle-advanced-setup-workflow) of advanced configuration with continuations from CircleCI.

The orb's intended use is toward the simplification of the default `.circleci/config.yml` by allowing users to add additional configs in other directories in a repo that run only when the code therein contains actual changes. This approach offers engineers reduced pipeline execution time, and by extension, reduced CI costs.

### Example

For example, if you have a directory layout such as

```
.circleci/config.yml
terraform/
scripts/
src/
```

with the addition of this orb, a user could define targeted configs

```
.circleci/config.yml
terraform/.circleci/config.yml
scripts/.circleci/config.yml
src/
```

that, once again, only execute when any code changes are introduced to the containing "module". If no changes are made in a PR within the `terraform/` directory, none of the jobs or workflows defined therein are executed by the default config.

### How it works

You'll need to add this orb, as well as an `extend` job to your workflow (likely appended to the end), such as

```
orbs:
  dynamic: hqo/dynamic-continuation:1.0.0

workflows:
  on-commit:
    jobs:
      - dynamic/extend:
          executor: dynamic/default
          modules: |
            ... list of directories, separated by newlines, that contain their own .circleci/config.yml
```

from here, move any jobs, workflows, or orbs, to their new configs in containing directories.

### Development

This orb has been developed in _unpacked_ form. You may view its packed source with

```shell
$ circleci orb pack src/ > orb.yml
```

and further validate the resulting orb definition with

```shell
$ circleci orb validate orb.yml
```

#### `pre-commit`

This repository uses `pre-commit` to uphold certain code styling and standards. You may install the hooks listed in [`.pre-commit-config.yaml`](.pre-commit-config.yaml) with

```shell
$ yarn install:pre-commit-hooks
```
