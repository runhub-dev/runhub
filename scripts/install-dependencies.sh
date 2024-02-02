#!/usr/bin/env sh

set -o errexit
set -o nounset

"$(dirname "$0")"/install-nix.sh
"$(dirname "$0")"/install-devbox.sh
"$(dirname "$0")"/install-direnv.sh
"$(dirname "$0")"/direnv-allow.sh "$(dirname "$0")"/..
