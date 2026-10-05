#!/bin/bash
set -euo pipefail

# A fixed SDK keeps the runtime identical in local builds and CI.
sdk_version=51.4.1.1
sdk_sha256=855dd09ed31e368ac604ef187801981e2e280df7edd12416d422b11a24911269
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
