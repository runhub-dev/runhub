#!/bin/sh

set -o errexit
set -o nounset

version_part_index=1

while [ "${version_part_index}" -le 3 ]; do
  version_1_part="$(echo "$1" | cut -d '.' -f "${version_part_index}")"
  version_2_part="$(echo "$2" | cut -d '.' -f "${version_part_index}")"

  if [ "${version_1_part}" -gt "${version_2_part}" ]; then
    echo true
    exit
  elif [ "${version_1_part}" -lt "${version_2_part}" ]; then
    echo false
    exit
  fi

  version_part_index=$(( version_part_index + 1 ))
done

echo true
