# Changelog

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

### Version policy for this patch

The orb, CI bootstrap, usage examples and pre-commit example use 3.9.2. The
release tag bootstrapped with 3.9.1; CI advanced to 3.9.2 after registry
publication to avoid referencing an unpublished orb during its own release.

The default CLI stays at v0.1.26837 for backward compatibility; CLI v1.0.46955 is
tested as the first stable 1.x release. The obsolete circleci-cli orb dependency
is removed. orb-tools 11.6.1 and continuation 1.0.0 retain their existing major
versions; the release jobs explicitly use CLI 0.1.26837 because those orb-tools
commands require legacy flags. Unrelated runtime and dependency majors are
unchanged.
