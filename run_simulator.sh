#!/bin/bash

# Build and launch HebrewDate app in the ConnectIQ simulator for descentg1

DEVICE="descentg1"
OUTPUT="HebrewDate.prg"
JUNGLE_FILE="monkey.jungle"
SDK_DIR="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc"
SDK_BIN="$SDK_DIR/bin"

export PATH="$PATH:$SDK_BIN"

# Developer key
DEV_KEY="developer_key"
if [ ! -f "$DEV_KEY" ]; then
    DEV_KEY="$HOME/.Garmin/ConnectIQ/developer_key"
fi

if ! command -v monkeyc &> /dev/null; then
    echo "Error: monkeyc not found. Check SDK path: $SDK_BIN"
    exit 1
fi

echo "Building for $DEVICE..."
monkeyc -d "$DEVICE" -f "$JUNGLE_FILE" -o "$OUTPUT" -y "$DEV_KEY" -w
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi
echo "Build OK: $OUTPUT"

# Launch simulator in background if not already running
if ! pgrep -f "simulator" > /dev/null; then
    echo "Starting ConnectIQ simulator..."
    "$SDK_BIN/simulator" &
    sleep 3
fi

# Load app into simulator
echo "Loading app into simulator ($DEVICE)..."
monkeydo "$OUTPUT" "$DEVICE"
