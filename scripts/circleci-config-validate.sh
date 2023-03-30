#! /usr/bin/env bash

set -e

if [[ -n $CIRCLECI ]]; then
    echo "Circleci environment detected, skipping validation."
    exit 0
fi

if ! command -v circleci &>/dev/null; then
    echo "Circleci CLI could not be found. Install the latest CLI version https://circleci.com/docs/2.0/local-cli/#installation"
    exit 1
fi

for config in "$@"; do
    if ! reMSG=$(circleci config validate --skip-update-check -c "$config"); then
        printf "CircleCI config file \"%s\" failed validation.\\n" "$config"
        echo "${reMSG}"
        exit 1
    fi
done
