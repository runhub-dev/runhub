#!/usr/bin/env sh

set -o errexit
set -o nounset

if command -v "$1" > /dev/null || [ -e "$1" ]; then
  echo 'yes'
else
  echo 'no'
fi
