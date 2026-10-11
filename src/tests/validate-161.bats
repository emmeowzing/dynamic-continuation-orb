#!/usr/bin/env bats
# Tests intentionally isolate environment changes and pass literal references.
# shellcheck disable=SC2016,SC2030,SC2031

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export PATH="$TEST_DIR:$PATH"
    export CLI_LOG="$TEST_DIR/arguments" TOKEN_LOG="$TEST_DIR/token"
    export SH_CONTINUE_CONFIG='config with spaces.yml'
    export SH_PROJECT_TYPE=github SH_CIRCLE_ORGANIZATION=example
    export SH_CIRCLE_TOKEN='test token' CLI_STYLE=legacy
    export SCRIPT="$BATS_TEST_DIRNAME/../scripts/validate.sh"
    cat > "$TEST_DIR/circleci" <<'MOCK'
#!/usr/bin/env bash
if [[ "$*" == 'config validate --help' ]]; then
    if [[ "${HELP_FAILURE:-0}" != 0 ]]; then exit "$HELP_FAILURE"; fi
    if [[ "$CLI_STYLE" == legacy ]]; then
        echo '--org-slug string --token string' >&2
    else
        echo '--org string'
    fi
    # Enough output to expose early grep termination under pipefail.
    for ((i=0; i<1000; i++)); do echo 'additional help text'; done
    exit 0
fi
printf '%s\n' "$@" > "$CLI_LOG"
printf '%s' "${CIRCLE_TOKEN:-}" > "$TOKEN_LOG"
exit "${VALIDATE_FAILURE:-0}"
MOCK
    chmod +x "$TEST_DIR/circleci"
}

teardown() {
    rm -rf "${TEST_DIR:?}"
}

@test 'legacy CLI receives org-slug and token with quoted config path' {
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(cat "$CLI_LOG")" = "$(printf '%s\n' config validate "$SH_CONTINUE_CONFIG" --org-slug github/example --token 'test token')" ]
}

@test 'CLI 1.0 receives org and token only through environment' {
    export CLI_STYLE=modern
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(cat "$CLI_LOG")" = "$(printf '%s\n' config validate "$SH_CONTINUE_CONFIG" --org github/example)" ]
    [ "$(cat "$TOKEN_LOG")" = 'test token' ]
}

@test 'default environment references are resolved' {
    export CLI_STYLE=modern CIRCLE_TOKEN='environment token' CIRCLE_ORGANIZATION=environment-org
    export SH_CIRCLE_TOKEN='$CIRCLE_TOKEN' SH_CIRCLE_ORGANIZATION='$CIRCLE_ORGANIZATION'
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(cat "$TOKEN_LOG")" = 'environment token' ]
    [ "$(tail -1 "$CLI_LOG")" = github/environment-org ]
}

@test 'braced custom environment references are resolved' {
    export CLI_STYLE=modern CUSTOM_TOKEN='custom token' CUSTOM_ORG=custom-org
    export SH_CIRCLE_TOKEN='${CUSTOM_TOKEN}' SH_CIRCLE_ORGANIZATION='${CUSTOM_ORG}'
    export SH_PROJECT_TYPE=bitbucket
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(cat "$TOKEN_LOG")" = 'custom token' ]
    [ "$(tail -1 "$CLI_LOG")" = bitbucket/custom-org ]
}

@test 'parameter text is never executed' {
    export CLI_STYLE=modern
    export SH_CIRCLE_TOKEN='$(touch "$TEST_DIR/executed")'
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 0 ]
    [ ! -e "$TEST_DIR/executed" ]
    [ "$(cat "$TOKEN_LOG")" = "$SH_CIRCLE_TOKEN" ]
}

@test 'legacy validation failure is preserved' {
    export VALIDATE_FAILURE=14
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 14 ]
}

@test 'modern validation failure is preserved' {
    export CLI_STYLE=modern VALIDATE_FAILURE=14
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -eq 14 ]
}

@test 'help failure stops validation' {
    export HELP_FAILURE=7
    run bash -eo pipefail "$SCRIPT"
    [ "$status" -ne 0 ]
    [ ! -e "$CLI_LOG" ]
}
