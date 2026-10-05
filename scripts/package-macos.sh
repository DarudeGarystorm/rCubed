#!/bin/bash
set -euo pipefail

sdk_dir="${1:?Usage: package-macos.sh SDK_DIRECTORY GAME_SWF VERSION OUTPUT_DIRECTORY}"
game_swf="${2:?Missing compiled game SWF}"
version="${3:?Missing version}"
output_dir="${4:?Missing output directory}"
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(uname -s)" != Darwin ]]; then
    echo 'Mac bundles must be packaged on macOS.' >&2
    exit 1
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo 'The bundle version must be three numeric components, for example 1.2.3.' >&2
    exit 1
fi

mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
stage_dir="$(mktemp -d -t r3-macos-package)"
trap 'rm -rf "$stage_dir"' EXIT
cp "$game_swf" "$stage_dir/R3Air.swf"
cp -R "$repo_dir/data" "$stage_dir/data"
cp "$repo_dir/changelog.txt" "$stage_dir/changelog.txt"

python3 - "$repo_dir/application.xml" "$stage_dir/application.xml" "$version" <<'PY'
import sys
import xml.etree.ElementTree as ET

source, destination, version = sys.argv[1:]
tree = ET.parse(source)
namespace = tree.getroot().tag.split('}')[0][1:]
ET.register_namespace('', namespace)
tree.find(f'{{{namespace}}}versionNumber').text = version
tree.find(f'{{{namespace}}}initialWindow/{{{namespace}}}content').text = 'R3Air.swf'
tree.write(destination, encoding='utf-8', xml_declaration=True)
PY

app_dir="$stage_dir/R3.app"
certificate_password="$(openssl rand -hex 16)"
"$sdk_dir/bin/adt" -certificate -cn 'rCubed Mac Build' 2048-RSA \
    "$stage_dir/air-cert.p12" "$certificate_password"
"$sdk_dir/bin/adt" -package -storetype pkcs12 -keystore "$stage_dir/air-cert.p12" \
    -storepass "$certificate_password" -tsa none -target bundle "$app_dir" "$stage_dir/application.xml" \
    -C "$stage_dir" R3Air.swf data changelog.txt

# Refuse to label an Intel-only runtime as universal.
lipo -verify_arch x86_64 arm64 "$app_dir/Contents/MacOS/R3"
lipo -verify_arch x86_64 arm64 "$app_dir/Contents/Frameworks/Adobe AIR.framework/Adobe AIR"

# Apple Silicon requires signed executables. An ad hoc signature works for
# testing; trusted distribution still needs a Developer ID and notarization.
codesign --force --deep --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"

archive="$output_dir/rCubed-$version-macOS-universal.zip"
ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$archive"
echo "$archive"
