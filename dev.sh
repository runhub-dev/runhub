#!/bin/sh
set -ex

SRC_PATH="$(dirname "${0:?}")"

if ! command -v brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle --file "${SRC_PATH:?}"/Brewfile

trap 'colima delete runhub --force' EXIT
colima start runhub \
  --cpu $(( $(sysctl -n hw.logicalcpu_max) / 2 )) \
  --memory $(( $(sysctl -n hw.memsize) / $(echo '1024^3' | bc) / 2 ))
k3d cluster create --config "${SRC_PATH:?}"/k3d.yaml
sleep 2147483647
