#!/bin/sh

set -o errexit
set -o nounset

darwin_memory_output="$(sysctl -n hw.memsize 2> /dev/null || true)"

if [ "${darwin_memory_output}" ]; then
  echo "${darwin_memory_output}"' / 1024^3' | bc
else
  linux_memory_output="$(cat /proc/meminfo 2> /dev/null || true)"

  if [ "${linux_memory_output}" ]; then
    linux_memory_output_head="$(echo "${linux_memory_output}" | head -n 1)"
    linux_memory_output_tr="$(echo "${linux_memory_output_head}" | tr -s ' ')"
    linux_memory_output_cut="$(echo "${linux_memory_output_tr}" | cut -d ' ' -f 2)"
    echo "${linux_memory_output_cut}"' / 1024^2 + 1' | bc
  else
    exit 1
  fi
fi
