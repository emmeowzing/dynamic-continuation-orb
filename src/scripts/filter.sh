# shellcheck disable=SC2288,SC2001,SC2148


if [ -z "$SH_CIRCLE_TOKEN" ]; then
    printf "Must set CircleCI token for successful authentication.\\n" >&2
    exit 1
fi

# Add each module to `modules-filtered` if 1) `force-all` is set to `true`, or 2) there is a diff against master at HEAD, or 3) no workflow runs have occurred on the default branch for this project in the past $SH_REPORTING_WINDOW days.
if [ "$SH_FORCE_ALL" ] || { [ "$SH_REPORTING_WINDOW" != "" ] && [ "$(curl -s -X GET --url "https://circleci.com/api/v2/insights/${SH_PROJECT_TYPE}/${SH_CIRCLE_ORGANIZATION}/${CIRCLE_PROJECT_REPONAME}/workflows?reporting-window=${SH_REPORTING_WINDOW}" --header "Circle-Token: ${SH_CIRCLE_TOKEN}" | jq -r "[ .items[].name ] | length")" -eq "0" ]; }; then
    printf "Running all workflows.\\n"
    echo "$SH_MODULES" | awk NF | while read -r module; do
        module_dots="$(sed 's@\/@\.@g' <<< "$module")"
        if [ "${#module_dots}" -gt 1 ] && [ "${module_dots::1}" = "." ]; then
            module_dots="${module_dots:1}"
        fi
        if [ "${#module_dots}" -gt 1 ] && [ "${module_dots: -1}" = "." ]; then
            module_dots="${module_dots::-1}"
        fi

        echo "$module_dots" >> "$SH_MODULES_FILTERED"
    done
else
    pip install wildmatch=="$SH_WILDMATCH_VERSION"
    echo "$SH_MODULES" | awk NF | while read -r module; do
        module_dots="$(sed 's@\/@\.@g' <<< "$module")"
        if [ "${#module_dots}" -gt 1 ] && [ "${module_dots::1}" = "." ]; then
            module_dots="${module_dots:1}"
        fi
        if [ "${#module_dots}" -gt 1 ] && [ "${module_dots: -1}" = "." ]; then
            module_dots="${module_dots::-1}"
        fi

        module_slashes="$(sed 's@\.@\/@g' <<< "$module")"
        if [ "${#module_slashes}" -gt 1 ] && [ "${module_slashes::1}" = "/" ]; then
            module_slashes="${module_slashes:1}"
        fi
        if [ "${#module_slashes}" -gt 1 ] && [ "${module_slashes: -1}" = "/" ]; then
            module_slashes="${module_slashes::-1}"
        fi

        # Handle root module "."
        if [ "${module_dots}" = "." ]; then
            if [ ! -f .circleci/"$SH_ROOT_CONFIG.ignore" ]; then
                touch .circleci/"$SH_ROOT_CONFIG.ignore"
            fi

            if [ "$CIRCLE_BRANCH" = "$SH_DEFAULT_BRANCH" ]; then
                if "$SH_FORCE_ALL" || [ "$(git diff-tree --no-commit-id --name-only -r HEAD~"$SH_SQUASH_MERGE_LOOKBEHIND >>" "$SH_DEFAULT_BRANCH" "$module_dots" | awk NF | wildmatch -c ".circleci/$SH_ROOT_CONFIG.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD~"$SH_SQUASH_MERGE_LOOKBEHIND >>" "$SH_DEFAULT_BRANCH" ".circleci/$SH_ROOT_CONFIG.yml" | awk NF)" != "" ] && "$SH_INCLUDE_CONFIG_CHANGES"); then
                    echo "$module_dots" >> "$SH_MODULES_FILTERED"
                    printf "%s\\n" "$module_slashes"
                fi
            else
                if "$SH_FORCE_ALL" || [ "$(git diff-tree --no-commit-id --name-only -r HEAD "$SH_DEFAULT_BRANCH" "$module_dots" | awk NF | wildmatch -c ".circleci/$SH_ROOT_CONFIG.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD "$SH_DEFAULT_BRANCH" ".circleci/$SH_ROOT_CONFIG.yml" | awk NF)" != "" ] && "$SH_INCLUDE_CONFIG_CHANGES"); then
                    echo "$module_dots" >> "$SH_MODULES_FILTERED"
                    printf "%s\\n" "$module_slashes"
                fi
            fi

            continue
        fi

        # Handle non-root modules
        if [ ! -f ".circleci/${module_dots}.ignore" ]; then
            touch ".circleci/${module_dots}.ignore"
        fi

        if [ "$CIRCLE_BRANCH" = "$SH_DEFAULT_BRANCH" ]; then
            if [ "$SH_FORCE_ALL" ] || [ "$(git diff-tree --no-commit-id --name-only -r HEAD~"$SH_SQUASH_MERGE_LOOKBEHIND >>" "$SH_DEFAULT_BRANCH" "$module_slashes" | awk NF | wildmatch -c ".circleci/${module_dots}.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD~"$SH_SQUASH_MERGE_LOOKBEHIND >>" "$SH_DEFAULT_BRANCH" .circleci/"$module_dots".yml | awk NF)" != "" ] && "$SH_INCLUDE_CONFIG_CHANGES"); then
                echo "$module_dots" >> "$SH_MODULES_FILTERED"
                printf "%s\\n" "$module_slashes"
            fi
        else
            if [ "$SH_FORCE_ALL" ] || [ "$(git diff-tree --no-commit-id --name-only -r HEAD "$SH_DEFAULT_BRANCH" "$module_slashes" | awk NF | wildmatch -c ".circleci/${module_dots}.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD "$SH_DEFAULT_BRANCH" .circleci/"$module_dots".yml | awk NF)" != "" ] && "$SH_INCLUDE_CONFIG_CHANGES"); then
                echo "$module_dots" >> "$SH_MODULES_FILTERED"
                printf "%s\\n" "$module_slashes"
            fi
        fi
    done
fi