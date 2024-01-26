#!/usr/bin/env sh

set -o errexit
set -o nounset

is_found="$("$(dirname "$0")"/is-found.sh "$2")"

if [ "${is_found}" = 'no' ] || ! grep -Fq "$1" "$2"; then
  printf '\n%s\n' "$1" >> "$2"
fi
