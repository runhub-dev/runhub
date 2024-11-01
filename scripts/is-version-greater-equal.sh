#!/bin/sh

set -o errexit
set -o nounset

is_version() {
  echo "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
}

get_version_part() {
  echo "$1" | cut -f "${version_part_index}" -d '.'
}

main() {
  is_version "$1"
  is_version "$2"

  version_part_index=1
  while [ "${version_part_index}" -le 3 ]; do
    version_1_part="$(get_version_part "$1" "${version_part_index}")"
    version_2_part="$(get_version_part "$2" "${version_part_index}")"

    if [ "${version_1_part}" -gt "${version_2_part}" ]; then
      break
    fi

    if [ "${version_1_part}" -lt "${version_2_part}" ]; then
      echo 'false'
      exit
    fi

    version_part_index="$(( version_part_index + 1 ))"
  done

  echo 'true'
}

main "$@"
