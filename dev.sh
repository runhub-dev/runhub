#!/bin/sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"

"${runhub_dir}"/scripts/install-nix.sh
