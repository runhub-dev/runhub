#!/bin/sh

set -o errexit
set -o nounset

export IS_RUNHUB_TEST='yes'

runhub_dir="$(dirname "$0")"

"${runhub_dir}"/dev.sh
