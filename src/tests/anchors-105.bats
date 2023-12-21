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
    printf "example-1\\nexample-2" > "$SH_MODULES_FILTERED"

    # Copy our test data -> /.circleci/
    cp src/tests/data/"$ISSUE_NUMBER"/example-{1,2}.yml .circleci/
}


##
# Clean up test environment.
clean()
{
    rm "${SH_MODULES_FILTERED:?}"
    rm .circleci/example-{1,2}.yml
}


##
# Show diff output.
_diff()
{
    diff -d -r -y <(yq -rM "$SH_CONTINUE_CONFIG") <(yq -rM "$EXPECTED_CONFIG")
}


@test reduce_exploded_yaml_anchors {
    setup

    ./src/scripts/reduce.sh

    if [ "$(yq -rM '.' "$SH_CONTINUE_CONFIG")" != "$(yq -rM '.' "$EXPECTED_CONFIG")" ]; then
        _diff
        printf "\\n"
        clean
        return 1
    fi

    clean
}


# TODO: write another test that checks that it purposely fails w/o the explode?