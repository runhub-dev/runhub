#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"

output="$("$@" 2>&1)" || exit_status="$?"

if [ "${exit_status:-0}" != 0 ]; then
  "${SCRIPTS_DIR}"/print.sh "${output}"
  exit "${exit_status}"
fi
