# shellcheck disable=SC2288,SC2001,SC2148,SC2002,SC2016,SC2046


shopt -s nullglob


# If `modules` is unavailable, stop this job without continuation
if [ ! -f "$SH_MODULES_FILTERED" ] || [ ! -s "$SH_MODULES_FILTERED" ]; then
    printf "Nothing to merge. Halting the job.\\n"
    circleci-agent step halt
    exit 0
fi

# Convert a list of dirs to a list of config files under .circleci/.
awk "{
    if (\$0 ~ /^\\.$/) {
        printf \".circleci/${SH_ROOT_CONFIG}.yml\\n\"
    } else {
        printf(\".circleci/%s.yml\n\", \$0)
    }
}" "$SH_MODULES_FILTERED" > /tmp/"$CIRCLE_WORKFLOW_ID.txt"
mv /tmp/"$CIRCLE_WORKFLOW_ID.txt" "$SH_MODULES_FILTERED"

# Move yaml files -> yml so we can handle both extensions for YAML configs. Not that we want both, but we should handle both cases.
for f in .circleci/*.yaml; do
    printf "Migrating pipeline \"%s\" -> \"%s\"\\n" "$f" "${f%.*}.yml" >&2
    if [ -f "${f%.*}.yml" ]; then
        printf "ERROR: Could not migrate \"%s\", \"%s\" already exists.\\n" "$f" "${f%.*}.yml" >&2
        exit 1
    fi
    mv "$f" "${f%.*}.yml"
done

yq eval-all '. as $item ireduce ( {}; . * $item )' $(cat "$SH_MODULES_FILTERED" | xargs) | tee "$SH_CONTINUE_CONFIG"