#! /usr/bin/env bash
# Filter modules.

# shellcheck disable=SC2288,SC2001


# If `modules` is unavailable, stop this job without continuation
if [ ! -f "<< parameters.modules >>" ] || [ ! -s "<< parameters.modules >>" ]
then
    printf "Nothing to merge. Halting the job.\\n"
    circleci-agent step halt
    exit 0
fi

# Convert a list of dirs to a list of config files under .circleci/.
awk '{
    if ($0 ~ /^\.$/) {
        printf ".circleci/<< parameters.root-config >>.yml\n"
    } else {
        printf(".circleci/%s.yml\n", $0)
    }
}' "<< parameters.modules >>" > /tmp/"$CIRCLE_WORKFLOW_ID.txt"
mv /tmp/"$CIRCLE_WORKFLOW_ID.txt" "<< parameters.modules >>"

xargs -a "<< parameters.modules >>" yq -y -s "reduce .[] as \$item ({}; . * \$item)" | tee "<< parameters.continue-config >>"