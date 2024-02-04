#!/usr/bin/env sh

set -o errexit
set -o nounset

output="$("$@" 2>&1)" || exit_status="$?"

if [ "${exit_status:-0}" != 0 ]; then
  echo "${output}"
  exit "${exit_status}"
fi
