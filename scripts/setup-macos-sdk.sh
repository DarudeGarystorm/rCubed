#!/bin/bash
set -euo pipefail

# A fixed SDK keeps the runtime identical in local builds and CI.
sdk_version=51.1.3.5
sdk_sha256=1f259b07546fc9d9a5bb737e8b404a5db96391898b6058c452fd75ba566f5e7f
sdk_dir="${1:?Usage: setup-macos-sdk.sh SDK_DIRECTORY}"

if [[ -f "$sdk_dir/.r3-sdk-$sdk_sha256" ]]; then
    exit 0
fi

archive="$(mktemp -t r3-air-sdk)"
trap 'rm -f "$archive"' EXIT
curl --fail --location --retry 3 --output "$archive" \
    "https://airsdk.harman.com/api/versions/$sdk_version/sdks/AIRSDK_MacOS.zip?license=accepted"
printf '%s  %s\n' "$sdk_sha256" "$archive" | shasum -a 256 -c -
mkdir -p "$sdk_dir"
ditto -x -k "$archive" "$sdk_dir"
touch "$sdk_dir/.r3-sdk-$sdk_sha256"
