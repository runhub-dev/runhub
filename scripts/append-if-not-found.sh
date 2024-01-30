#!/usr/bin/env sh

set -o errexit
set -o nounset

append() {
  printf '\n%s\n' "$1" >> "$2"
}

main() {
  is_found="$("$(dirname "$0")"/is-found.sh "$2")"

  if [ "${is_found}" = 'yes' ]; then
    grep -Fq "$1" "$2" || exit_status="$?"

    if [ "${exit_status:-0}" = 1 ]; then
      append "$@"
    else
      exit "${exit_status:-0}"
    fi
  else
    append "$@"
  fi
}

main "$@"
