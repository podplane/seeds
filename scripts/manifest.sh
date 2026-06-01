#!/usr/bin/env bash
# Podplane <https://podplane.dev>
# Copyright The Podplane Authors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

version=""
repo="podplane/seeds"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      version="${2:-}"
      shift 2
      ;;
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$version" ]]; then
  echo "--version is required" >&2
  exit 2
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]]; then
  echo "version must match <components-version>-<seed-revision>, e.g. 1.2.3-1" >&2
  exit 1
fi

components_version="${COMPONENTS_VERSION:-${version%-*}}"
tag="v${version}"
out_dir="dist/release"
out="${out_dir}/seeds_${version}.json"
manifest_path="manifests/seeds.json"

sha512() {
  shasum -a 512 "$1" | awk '{print $1}'
}

file_size() {
  if stat -f '%z' "$1" >/dev/null 2>&1; then
    stat -f '%z' "$1"
  else
    stat -c '%s' "$1"
  fi
}

mkdir -p "$out_dir"
items_file="$(mktemp)"
trap 'rm -f "$items_file"' EXIT

if [[ ! -f "$manifest_path" ]]; then
  echo "development manifest is missing: $manifest_path" >&2
  exit 1
fi

while IFS= read -r name; do
  path="$(jq -r --arg name "$name" '.seeds.snapshots[$name].path // ""' "$manifest_path")"
  entry_url="$(jq -r --arg name "$name" '.seeds.snapshots[$name].url // ""' "$manifest_path")"
  if [[ -z "$path" || -n "$entry_url" ]]; then
    echo "development manifest snapshot $name must set path and must not set url" >&2
    exit 1
  fi
  source="$(cd "$(dirname "$manifest_path")/$(dirname "$path")" && pwd)/$(basename "$path")"
  if [[ ! -s "$source" ]]; then
    echo "required snapshot is missing or empty: $source" >&2
    exit 1
  fi
  repo_root="$(pwd)"
  repo_path="${source#"$repo_root"/}"
  if [[ "$repo_path" == "$source" ]]; then
    echo "snapshot $source is outside repository root" >&2
    exit 1
  fi
  url="https://raw.githubusercontent.com/${repo}/${tag}/${repo_path}"
  jq -n \
    --arg name "$name" \
    --arg url "$url" \
    --arg digest "sha512:$(sha512 "$source")" \
    --argjson size "$(file_size "$source")" \
    '{key: $name, value: {url: $url, digest: $digest, size: $size}}' \
    >> "$items_file"
done < <(jq -r '.seeds.snapshots | keys[]' "$manifest_path")

jq -s \
  --arg version "$version" \
  --arg components "$components_version" \
  '{seeds: {version: $version, components: $components, snapshots: (map({(.key): .value}) | add)}}' \
  "$items_file" > "$out"

jq . "$out" >/dev/null
echo "wrote $out"
