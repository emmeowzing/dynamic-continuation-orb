#! /usr/bin/env bash
# Filter modules.

# shellcheck disable=SC2288,SC2001


# If `modules` is unavailable, stop this job without continuation
if [ ! -f "$SH_MODULES" ] || [ ! -s "$SH_MODULES" ]
then
    printf "Nothing to merge. Halting the job.\\n"
    circleci-agent step halt
    exit 0
fi

# Convert a list of dirs to a list of config files under .circleci/.
awk '{
    if ($0 ~ /^\.$/) {
        printf ".circleci/${SH_ROOT_CONFIG}.yml\n"
    } else {
        printf(".circleci/%s.yml\n", $0)
    }
}' "$SH_MODULES" > /tmp/"$CIRCLE_WORKFLOW_ID.txt"
mv /tmp/"$CIRCLE_WORKFLOW_ID.txt" "$SH_MODULES"

xargs -a "$SH_MODULES" yq -y -s "reduce .[] as \$item ({}; . * \$item)" | tee "$SH_CONTINUE_CONFIG"