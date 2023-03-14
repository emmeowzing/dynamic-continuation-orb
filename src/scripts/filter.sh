#! /usr/bin/env bash
# Filter modules.

# shellcheck disable=SC2288,SC2001


if ! "<< parameters.circle-token >>"; then
            printf "Must set CircleCI token for successful authentication.\\n" >&2
            exit 1
        fi

        # Add each module to `modules-filtered` if 1) `force-all` is set to `true`, or 2) there is a diff against master at HEAD, or 3) no workflow runs have occurred on the default branch for this project in the past << parameters.reporting-window >> days.
        if ! "<< parameters.force-all >>" && [ "$(curl -s --request GET --url "https://circleci.com/api/v2/insights/<< parameters.project-type >>/<< parameters.circle-organization >>/${CIRCLE_PROJECT_REPONAME}/workflows?reporting-window=<< parameters.reporting-window >>" --header "Circle-Token: << parameters.circle-token >>" | '[ .items[].name ] | length')" -eq 0 ]; then
            printf "Running all workflows.\\n"
            echo "<< parameters.modules >>" | awk NF | while read -r module; do
                module_dots="$(sed 's@\/@\.@g' <<< "$module")"
                if [ "${#module_dots}" -gt 1 ] && [ "${module_dots::1}" = "." ]; then
                    module_dots="${module_dots:1}"
                fi
                if [ "${#module_dots}" -gt 1 ] && [ "${module_dots: -1}" = "." ]; then
                    module_dots="${module_dots::-1}"
                fi

                echo "$module_dots" >> "<< parameters.modules-filtered >>"
            done
        else
            pip install wildmatch=="<< parameters.wildmatch-version >>"
            echo "<< parameters.modules >>" | awk NF | while read -r module; do
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
                    if [ ! -f .circleci/"<< parameters.root-config >>.ignore" ]; then
                        touch .circleci/"<< parameters.root-config >>.ignore"
                    fi

                    if [ "$CIRCLE_BRANCH" = "<< parameters.default-branch >>" ]; then
                        if "<< parameters.force-all >>" || [ "$(git diff-tree --no-commit-id --name-only -r HEAD~"<< parameters.squash-merge-lookbehind >>" "<< parameters.default-branch >>" "$module_dots" | awk NF | wildmatch -c ".circleci/<< parameters.root-config >>.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD~"<< parameters.squash-merge-lookbehind >>" "<< parameters.default-branch >>" ".circleci/<< parameters.root-config >>.yml" | awk NF)" != "" ] && "<< parameters.include-config-changes >>"); then
                            echo "$module_dots" >> "<< parameters.modules-filtered >>"
                            printf "%s\\n" "$module_slashes"
                        fi
                    else
                        if "<< parameters.force-all >>" || [ "$(git diff-tree --no-commit-id --name-only -r HEAD "<< parameters.default-branch >>" "$module_dots" | awk NF | wildmatch -c ".circleci/<< parameters.root-config >>.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD "<< parameters.default-branch >>" ".circleci/<< parameters.root-config >>.yml" | awk NF)" != "" ] && "<< parameters.include-config-changes >>"); then
                            echo "$module_dots" >> "<< parameters.modules-filtered >>"
                            printf "%s\\n" "$module_slashes"
                        fi
                    fi

                    continue
                fi

                # Handle non-root modules
                if [ ! -f ".circleci/${module_dots}.ignore" ]; then
                    touch ".circleci/${module_dots}.ignore"
                fi

                if [ "$CIRCLE_BRANCH" = "<< parameters.default-branch >>" ]; then
                    if "<< parameters.force-all >>" || [ "$(git diff-tree --no-commit-id --name-only -r HEAD~"<< parameters.squash-merge-lookbehind >>" "<< parameters.default-branch >>" "$module_slashes" | awk NF | wildmatch -c ".circleci/${module_dots}.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD~"<< parameters.squash-merge-lookbehind >>" "<< parameters.default-branch >>" .circleci/"$module_dots".yml | awk NF)" != "" ] && "<< parameters.include-config-changes >>"); then
                        echo "$module_dots" >> "<< parameters.modules-filtered >>"
                        printf "%s\\n" "$module_slashes"
                    fi
                else
                    if "<< parameters.force-all >>" || [ "$(git diff-tree --no-commit-id --name-only -r HEAD "<< parameters.default-branch >>" "$module_slashes" | awk NF | wildmatch -c ".circleci/${module_dots}.ignore")" != "" ] || ([ "$(git diff-tree --no-commit-id --name-only -r HEAD "<< parameters.default-branch >>" .circleci/"$module_dots".yml | awk NF)" != "" ] && "<< parameters.include-config-changes >>"); then
                        echo "$module_dots" >> "<< parameters.modules-filtered >>"
                        printf "%s\\n" "$module_slashes"
                    fi
                fi
            done
        fi