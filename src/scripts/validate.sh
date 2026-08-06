# shellcheck disable=SC2148,SC2153


if [ "${SH_CIRCLE_ORGANIZATION:0:1}" = '$' ]; then
    _CIRCLE_ORGANIZATION="$(eval echo "$SH_CIRCLE_ORGANIZATION")"
else
    _CIRCLE_ORGANIZATION="$SH_CIRCLE_ORGANIZATION"
fi

if [ "${SH_CIRCLE_TOKEN:0:1}" = '$' ]; then
    _CIRCLE_TOKEN="$(eval echo "$SH_CIRCLE_TOKEN")"
else
    _CIRCLE_TOKEN="$SH_CIRCLE_TOKEN"
fi

ORG_SLUG="${SH_PROJECT_TYPE}/${_CIRCLE_ORGANIZATION}"

if circleci config validate --help 2>&1 | grep -q -- '--org-slug'; then
    circleci config validate "$SH_CONTINUE_CONFIG" --org-slug "$ORG_SLUG" --token "$_CIRCLE_TOKEN"
else
    CIRCLE_TOKEN="$_CIRCLE_TOKEN" circleci config validate "$SH_CONTINUE_CONFIG" --org "$ORG_SLUG"
fi
