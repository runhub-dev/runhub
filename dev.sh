#!/usr/bin/env sh

set -o errexit
set -o nounset

"$(dirname "$0")"/scripts/install-dependencies.sh
trap 'exit 0' INT
trap '"$(dirname "$0")"/scripts/stop-dev-mode.sh' EXIT
"$(dirname "$0")"/scripts/start-dev-mode.sh
"$(dirname "$0")"/scripts/print.sh 'Press Ctrl+C to stop dev mode.'
sleep 2147483647
