#!/usr/bin/env bats
# Each Bats test receives its own environment.
# shellcheck disable=SC2030,SC2031

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export PATH="$TEST_DIR:$PATH"
    export INSTALL_LOG="$TEST_DIR/install-log"
    export SH_CIRCLECI_CLI_VERSION=v0.1.26837 INSTALLED_VERSION='circleci 1.0.46955 (test)'
    export SCRIPT="$BATS_TEST_DIRNAME/../scripts/install-circleci.sh"
    cat > "$TEST_DIR/circleci" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$INSTALLED_VERSION"
MOCK
    cat > "$TEST_DIR/curl" <<'MOCK'
#!/usr/bin/env bash
if [[ "${DOWNLOAD_FAILURE:-0}" != 0 ]]; then exit "$DOWNLOAD_FAILURE"; fi
cat > "$4" <<'INSTALLER'
printf '%s\n' "$VERSION" "$DESTDIR" > "$INSTALL_LOG"
exit "${INSTALL_FAILURE:-0}"
INSTALLER
MOCK
    chmod +x "$TEST_DIR/circleci" "$TEST_DIR/curl"
}

teardown() {
    rm -rf "${TEST_DIR:?}"
}

@test 'requested legacy version is forwarded to installer' {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(cat "$INSTALL_LOG")" = "$(printf '%s\n' 0.1.26837 /usr/local/bin)" ]
}

@test 'requested modern version is forwarded to installer' {
    export SH_CIRCLECI_CLI_VERSION=v1.0.46955 INSTALLED_VERSION=0.1.26837
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(head -1 "$INSTALL_LOG")" = 1.0.46955 ]
}

@test 'matching installed version is retained' {
    export INSTALLED_VERSION=0.1.26837+b104265
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [ ! -e "$INSTALL_LOG" ]
}

@test 'latest delegates version selection to the installer' {
    export SH_CIRCLECI_CLI_VERSION=latest
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [ -z "$(head -1 "$INSTALL_LOG")" ]
}

@test 'failed download stops installation' {
    export DOWNLOAD_FAILURE=22
    run bash "$SCRIPT"
    [ "$status" -eq 22 ]
    [ ! -e "$INSTALL_LOG" ]
}

@test 'failed installation propagates its status' {
    export INSTALL_FAILURE=9
    run bash "$SCRIPT"
    [ "$status" -eq 9 ]
}
