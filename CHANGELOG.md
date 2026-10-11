# Changelog

## 4.0.0

- Carry forward the CircleCI CLI compatibility and installation repair from
  3.9.2, with usage examples and release references aligned to 4.0.0.
- This version introduces no additional breaking API changes. Both CLI 0.1.x
  and 1.x remain supported.

### Compatibility pins and release bootstrap

The default CLI stays at v0.1.26837 for backward compatibility; CLI v1.0.46955
is tested as the first stable 1.x release. The obsolete circleci-cli orb
installer dependency has been removed. orb-tools 11.6.1 and continuation 1.0.0
retain their existing major versions. Release jobs use CLI 0.1.26837 because
those orb-tools commands require legacy flags. Unrelated dependency majors
are unchanged.

The 4.0.0 release tag bootstrapped with the already published 3.9.2 orb. CI now
uses 4.0.0 following registry publication, avoiding an unpublished
self-dependency.

## 3.9.2

- Restore `continue` validation with CircleCI CLI 1.x while retaining 0.1.x
  support. Thanks to Hadi (@ADLTU) for the original fix in #162.
- Honor the requested `circleci-cli-version` when installing or replacing the
  CLI, using a pinned upstream installer that verifies release checksums.
- Quote validation arguments, resolve environment references without evaluating
  shell code, and preserve validation failures.
- Add regression tests and a real CLI compatibility matrix in maintainer CI.
- Repair the repository's CI bootstrap and yq test installation, and pin legacy
  orb-tools packing/publishing jobs to CLI 0.1.26837.
