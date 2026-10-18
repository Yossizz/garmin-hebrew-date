#!/usr/bin/env bash
# ./build.sh [build|sim|demo|test|release|iq]   (DEVICE=descentg1 by default)
#   build    debug .prg            sim      debug .prg + run in the simulator
#   demo     simulator run in Tel Aviv on the coming Friday 15:00, or DEMO_DATE=YYYY-MM-DD [DEMO_TIME=HH:MM]
#   test     run the unit tests    release  release .prg (sideload)
#   iq       release .iq package for the Connect IQ Store
set -euo pipefail
cd "$(dirname "$0")"

if ! java -version >/dev/null 2>&1 && [ -d /opt/homebrew/opt/openjdk@21/bin ]; then
    export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
fi
CIQ="$HOME/Library/Application Support/Garmin/ConnectIQ"
[ -f "$CIQ/current-sdk.cfg" ] || { echo "No current SDK: open SDK Manager and click 'Use as current SDK'" >&2; exit 1; }
SDK="$(tr -d '\n' < "$CIQ/current-sdk.cfg")"
SDK="${SDK%/}"
DEVICE="${DEVICE:-descentg1}"

# Developer key: ./developer_key, ~/.Garmin/ConnectIQ/developer_key, or ~/.connectiq-keys/developer_key.der
KEY="${KEY:-}"
for k in developer_key "$HOME/.Garmin/ConnectIQ/developer_key" "$HOME/.connectiq-keys/developer_key.der"; do
    [ -z "$KEY" ] && [ -f "$k" ] && KEY="$k"
done
[ -n "$KEY" ] || { echo "No developer key found" >&2; exit 1; }

mkdir -p bin
mc() { "$SDK/bin/monkeyc" -f monkey.jungle -y "$KEY" -w "$@"; }

case "${1:-build}" in
    build)   mc -d "$DEVICE" -o "bin/HebrewDate-$DEVICE.prg" ;;
    sim)     mc -d "$DEVICE" -o "bin/HebrewDate-$DEVICE.prg"
             pgrep -f 'ConnectIQ.app' >/dev/null || { "$SDK/bin/connectiq" & sleep 5; }
             "$SDK/bin/monkeydo" "bin/HebrewDate-$DEVICE.prg" "$DEVICE" ;;
    demo)    # DEMO_DATE=2026-12-10 [DEMO_TIME=18:30] ./build.sh demo  (default: coming Friday 15:00)
             mkdir -p bin/demo-src
             start=0
             if [ -n "${DEMO_DATE:-}" ]; then
                 start=$(date -j -f "%Y-%m-%d %H:%M" "$DEMO_DATE ${DEMO_TIME:-15:00}" +%s)
             fi
             printf '(:shabbatDemo, :glance)\nmodule DemoConfig {\n    const START = %s;\n}\n' "$start" > bin/demo-src/DemoConfig.mc
             "$SDK/bin/monkeyc" -f "monkey.jungle;demo.jungle" -y "$KEY" -w -d "$DEVICE" -o "bin/HebrewDate-demo.prg"
             pgrep -f 'ConnectIQ.app' >/dev/null || { "$SDK/bin/connectiq" & sleep 5; }
             "$SDK/bin/monkeydo" bin/HebrewDate-demo.prg "$DEVICE" ;;
    test)    mc -d "$DEVICE" -o "bin/HebrewDate-test.prg" --unit-test
             pgrep -f 'ConnectIQ.app' >/dev/null || { "$SDK/bin/connectiq" & sleep 5; }
             "$SDK/bin/monkeydo" bin/HebrewDate-test.prg "$DEVICE" -t ;;
    release) mc -d "$DEVICE" -o "bin/HebrewDate.prg" -r ;;
    iq)      mc -e -o bin/HebrewDate.iq -r ;;
    *)       echo "usage: $0 [build|sim|demo|test|release|iq]" >&2; exit 2 ;;
esac
