# shellcheck disable=SC2148,SC2153

set -euo pipefail

CLI_VERSION="${SH_CIRCLECI_CLI_VERSION#v}"
if command -v circleci >/dev/null 2>&1; then
    INSTALLED_VERSION="$(circleci version)"
    INSTALLED_VERSION="${INSTALLED_VERSION#circleci }"
    INSTALLED_VERSION="${INSTALLED_VERSION%%[ +]*}"
    if [[ "$CLI_VERSION" != latest && "$INSTALLED_VERSION" == "$CLI_VERSION" ]]; then
        printf 'CircleCI CLI %s is already installed.\n' "$CLI_VERSION"
        exit 0
    fi
fi

# Pin the installer implementation, and explicitly forward the selected version.
# It verifies release checksums and uses sudo only for the final installation.
INSTALLER="$(mktemp)"
trap 'rm -f "$INSTALLER"' EXIT
curl -fsSL https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/b60dc4c63b65fe080d3664ed993765dfc201bb11/install.sh -o "$INSTALLER"
if [[ "$CLI_VERSION" == latest ]]; then
    CLI_VERSION=''
fi
VERSION="$CLI_VERSION" DESTDIR=/usr/local/bin bash "$INSTALLER"
circleci version
