# shellcheck disable=SC2148,SC2153


# Resolve literal values and $NAME / ${NAME} references without executing input.
resolve_parameter()
{
    local value="$1" name
    if [[ "$value" =~ ^\$([a-zA-Z_][a-zA-Z0-9_]*)$ ]]; then
        name="${BASH_REMATCH[1]}"
        printf '%s' "${!name}"
    elif [[ "$value" =~ ^\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}$ ]]; then
        name="${BASH_REMATCH[1]}"
        printf '%s' "${!name}"
    else
        printf '%s' "$value"
    fi
}

_CIRCLE_ORGANIZATION="$(resolve_parameter "$SH_CIRCLE_ORGANIZATION")"
_CIRCLE_TOKEN="$(resolve_parameter "$SH_CIRCLE_TOKEN")"

ORG_SLUG="${SH_PROJECT_TYPE}/${_CIRCLE_ORGANIZATION}"

# Capture help first: grep -q in a pipe can cause SIGPIPE under pipefail.
VALIDATE_HELP="$(circleci config validate --help 2>&1)" || { printf '%s\n' "$VALIDATE_HELP" >&2; exit 1; }
if [[ "$VALIDATE_HELP" == *--org-slug* ]]; then
    circleci config validate "$SH_CONTINUE_CONFIG" --org-slug "$ORG_SLUG" --token "$_CIRCLE_TOKEN"
else
    CIRCLE_TOKEN="$_CIRCLE_TOKEN" circleci config validate "$SH_CONTINUE_CONFIG" --org "$ORG_SLUG"
fi
