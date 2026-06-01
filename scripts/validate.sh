#!/usr/bin/env bash
# Podplane <https://podplane.dev>
# Copyright The Podplane Authors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ "${SEEDS_VALIDATE:-true}" == "false" ]]; then
  echo "SEEDS_VALIDATE=false; skipping seed snapshot validation" >&2
  exit 0
fi

if [[ $# -eq 0 ]]; then
  echo "usage: scripts/validate.sh <snapshot.netsy>..." >&2
  exit 2
fi

if ! command -v read-netsy-file >/dev/null 2>&1; then
  echo "read-netsy-file is required for seed snapshot validation" >&2
  echo "install it with: go install github.com/netsy-dev/netsy/cmd/read-netsy-file@latest" >&2
  exit 1
fi

for path in "$@"; do
  if [[ ! -s "$path" ]]; then
    echo "required snapshot is missing or empty: $path" >&2
    exit 1
  fi
  case "$path" in
    *.netsy) ;;
    *)
      echo "snapshot must use .netsy extension: $path" >&2
      exit 1
      ;;
  esac
  read-netsy-file "$path" >/dev/null
done
