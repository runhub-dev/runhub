#!/usr/bin/env sh

set -o errexit
set -o nounset

version_part=1

get_version_part() {
  echo "$1" | cut -d '.' -f "$2"
}

while [ "${version_part}" -le 3 ]; do
  version_part_1="$(get_version_part "$1" "${version_part}")"
  version_part_2="$(get_version_part "$2" "${version_part}")"

  if [ "${version_part_1}" -gt "${version_part_2}" ]; then
    echo 'yes'
    exit
  elif [ "${version_part_1}" -lt "${version_part_2}" ]; then
    echo 'no'
    exit
  fi

  version_part=$(( version_part + 1 ))
done

echo 'yes'
