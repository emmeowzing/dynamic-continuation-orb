`example` orb for CircleCI
--------------------------

This orb provides a set of commands and jobs for [`example`](https://example.com) in CircleCI workflows. Commands include 

### Development

This orb has been developed in *unpacked* form. You may view its packed source with
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
