#!/bin/sh

set -o errexit
set -o nounset

bash_export_unset_diff="$(cd "${runhub_dir:?}" && direnv export bash)"

if [ -n "${bash_export_unset_diff}" ]; then
  sh_export_unset_diff="$(echo "${bash_export_unset_diff}" \
    | sed -e 's/$'\''\([^'\'']*\)'\''/"$(printf '\''%s'\'' '\''\1'\'')"/g')"
  eval "${sh_export_unset_diff}"
fi
