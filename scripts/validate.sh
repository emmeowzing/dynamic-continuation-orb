#! /bin/bash
# Validate this orb.

yarn orb:pack >/dev/null
circleci orb validate --skip-update-check orb.yml
yarn orb:clean >/dev/null
