#!/usr/bin/env sh

set -o errexit
set -o nounset

is_allowed() {
  status_output="$(cd "$1" && direnv status)"

  if echo "${status_output}" | grep -Fq 'Found RC allowed 0'; then
    echo 'yes'
  else
    echo 'no'
  fi
}

main() {
  is_allowed="$(is_allowed "$1")"

  if [ "${is_allowed}" = 'no' ]; then
    direnv allow "$1"
  fi
}

main "$@"
