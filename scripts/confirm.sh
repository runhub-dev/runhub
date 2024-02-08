#!/usr/bin/env sh

set -o errexit
set -o nounset

printf '%s ([y]es/[n]o): ' "$1"
read -r yes_no < /dev/tty
yes_no="$(echo "${yes_no}" | tr '[:upper:]' '[:lower:]')"
[ "${yes_no}" = 'y' ] || [ "${yes_no}" = 'yes' ]
