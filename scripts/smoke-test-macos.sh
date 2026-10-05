#!/bin/bash
set -euo pipefail

app_dir="${1:?Usage: smoke-test-macos.sh APPLICATION_BUNDLE}"
executable="$app_dir/Contents/MacOS/R3"
architecture="$(uname -m)"
lipo "$executable" -verify_arch "$architecture"
codesign --verify --deep --strict "$app_dir"

log_file="$(mktemp -t r3-macos-launch)"
pid=''
cleanup() {
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        wait "$pid" 2>/dev/null || true
    fi
    cat "$log_file"
    rm -f "$log_file"
}
trap cleanup EXIT

# Each matrix runner starts the native binary for its own architecture.
/usr/bin/arch "-$architecture" "$executable" > "$log_file" 2>&1 &
pid=$!
for ((second = 0; second < 15; second++)); do
    sleep 1
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "The $architecture application exited during startup." >&2
        exit 1
    fi
done
echo "Native $architecture startup passed."
