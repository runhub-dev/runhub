#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

. "${scripts_dir}"/load-envrc.sh
echo 'Running `shfmt`...'
shfmt --simplify --diff "${runhub_dir}" "${runhub_dir}"/.envrc
