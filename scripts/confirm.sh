#!/bin/sh

set -o errexit
set -o nounset

printf '%s ([Y]es/[n]o): ' "$1"

if [ "${IS_RUNHUB_TEST}" = 'no' ]; then
  IFS= read -r yes_no
  echo "${yes_no}" | grep -Eqi '^$|^y(es)?$'
else
  echo
fi
