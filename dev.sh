#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"/scripts

"${scripts_dir}"/install-nix.sh
