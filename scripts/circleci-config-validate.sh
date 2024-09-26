#! /usr/bin/env bash

set -e

if [[ -n $CIRCLECI ]]; then
    echo "Circleci environment detected, skipping validation."
    exit 0
fi

if ! command -v circleci &>/dev/null; then
    echo "Circleci CLI could not be found. Install the latest CLI version: https://circleci.com/docs/2.0/local-cli/#installation"
    exit 1
fi

if ! command -v yq &>/dev/null; then
    echo "yq could not be found. Install the latest yq version: https://github.com/mikefarah/yq/releases"
    exit 1
fi


lib="$(grep -oP "(?<=library-config: ).*" .circleci/config.yml)"

for config in "$@"; do
    if ! reMSG=$( circleci config validate --skip-update-check -c <(yq -Mr eval-all "explode(.) as \$item ireduce ( {}; . * \$item )" <(printf "%s\\n%s" "$config" "$lib" ) ) ); then
        printf "CircleCI config file \"%s\" failed validation.\\n" "$config"
        echo "${reMSG}"
        exit 1
    fi
done
