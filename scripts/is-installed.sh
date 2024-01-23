#!/usr/bin/env sh

set -o errexit
set -o nounset

command -v "$1" > /dev/null 2>&1
