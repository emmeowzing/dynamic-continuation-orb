# shellcheck disable=SC2288,SC2001,SC2148,SC2002,SC2016,SC2046


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

yq eval-all '. as $item ireduce ( {}; . * $item )' $(cat "$SH_MODULES_FILTERED") | tee "$SH_CONTINUE_CONFIG"