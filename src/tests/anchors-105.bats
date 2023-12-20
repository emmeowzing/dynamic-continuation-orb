#! /usr/bin/env bats
# Compare the results of reduction to the expected outcome.


export ISSUE_NUMBER=105
export SH_CONTINUE_CONFIG=/tmp/continue-config.yml
export SH_MODULES_FILTERED=/tmp/modules-filtered.txt
export SH_ROOT_CONFIG=app
export EXPECTED_CONFIG=src/tests/data/"$ISSUE_NUMBER"/expected-result.yml


##
# Set up test environment.
setup()
{
    printf "example-1\\nexample-2" > /tmp/modules-filtered.txt

    # Copy our test data -> /.circleci/
    cp src/tests/data/"$ISSUE_NUMBER"/example-{1,2}.yml .circleci/
}


##
# Clean up test environment.
clean()
{
    rm /tmp/modules-filtered.txt
    rm .circleci/example-{1,2}.yml
}


@test reduce_yaml_anchors {
    setup

    ./src/scripts/reduce.sh

    diff --recursive -y "$SH_CONTINUE_CONFIG" "$EXPECTED_CONFIG"

    if [ "$(yq -r -M '.' "$SH_CONTINUE_CONFIG")" != "$(yq -r -M '.' "$EXPECTED_CONFIG")" ]; then
        diff -d --recursive -y "$SH_CONTINUE_CONFIG" "$EXPECTED_CONFIG"
        printf "\\n"
        clean
        return 1
    fi

    clean
}