# shellcheck disable=SC2288,SC2001,SC2148,SC2002,SC2016,SC2046


info()
{
    if [ $# -ne 1 ]; then
        printf "Function \"info\" expected at least 1 argument: info message.\\n" >&2
        exit 1
    fi

    local msg
    msg="$1"

    printf "INFO: %s\\n" "$msg"
}


# If `modules` is unavailable, stop this job without continuation
if [ ! -f "$SH_MODULES_FILTERED" ] || [ ! -s "$SH_MODULES_FILTERED" ]; then
    printf "Nothing to merge. Halting the job.\\n"
    circleci-agent step halt
    exit 0
fi


# Convert a list of dirs to a list of config files under .circleci/.
awk "{
    if (\$0 ~ /^\\.\$/) {
        printf \".circleci/${SH_ROOT_CONFIG}.yml\\n\"
    } else {
        printf(\".circleci/%s.yml\n\", \$0)
    }
}" "$SH_MODULES_FILTERED" > /tmp/"$CIRCLE_WORKFLOW_ID.txt"
mv /tmp/"$CIRCLE_WORKFLOW_ID.txt" "$SH_MODULES_FILTERED"

# Append the library config, if it is specified and exists, to the reduction.
if [ "$SH_LIBRARY_CONFIG" != "" ] && [ -f .circleci/"$SH_LIBRARY_CONFIG".yml ]; then
    info "Merging user-specified library config \"%s\" (.circleci/%s.yml) with final config.\\n" "$SH_LIBRARY_CONFIG"
    printf ".circleci/%s.yml" "$SH_LIBRARY_CONFIG" >> "$SH_MODULES_FILTERED"
fi

yq -Mr eval-all 'explode(.) as $item ireduce ( {}; . * $item )' $(cat "$SH_MODULES_FILTERED" | xargs) | tee "$SH_CONTINUE_CONFIG"