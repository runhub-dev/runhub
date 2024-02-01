#!/usr/bin/env sh

set -o errexit
set -o nounset

darwin_output="$(sysctl -n hw.memsize 2> /dev/null || true)"

if [ "${darwin_output}" ]; then
  echo "${darwin_output}"' / 1024^3' | bc
else
  linux_output="$(cat /proc/meminfo 2> /dev/null || true)"

  if [ "${linux_output}" ]; then
    linux_output_grep="$(echo "${linux_output}" | grep '^MemTotal:')"
    linux_output_tr="$(echo "${linux_output_grep}" | tr -s ' ')"
    linux_output_cut="$(echo "${linux_output_tr}" | cut -d ' ' -f 2)"
    echo "${linux_output_cut}"' / 1024^2 + 1' | bc
  else
    exit 1
  fi
fi
