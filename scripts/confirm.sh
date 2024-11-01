#!/bin/sh

set -o errexit
set -o nounset

printf '%s ([Y]es/[n]o): ' "$1"
IFS= read -r yes_no
echo "${yes_no}" | grep -Eqi '^$|^y(es)?$'
