#!/bin/bash

# Build script for Hebrew Date Data Field
# Requires Garmin Connect IQ SDK to be installed

# Configuration
DEVICE="descentg1"
OUTPUT="HebrewDate.prg"
JUNGLE_FILE="monkey.jungle"

# Add SDK to PATH
export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin"

# Check if monkeyc is available
if ! command -v monkeyc &> /dev/null; then
    echo "Error: monkeyc command not found"
    echo "Please check SDK installation in:"
    echo "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/"
    exit 1
fi

# Check for developer key (try local first, then global)
DEV_KEY="developer_key"
if [ ! -f "$DEV_KEY" ]; then
    if [ -f "$HOME/.Garmin/ConnectIQ/developer_key" ]; then
        DEV_KEY="$HOME/.Garmin/ConnectIQ/developer_key"
    else
        echo "Warning: Developer key not found"
        echo "Looked in: ./developer_key and $HOME/.Garmin/ConnectIQ/developer_key"
        exit 1
    fi
fi

# Build command
echo "Building Hebrew Date Data Field for $DEVICE..."
echo "Using developer key: $DEV_KEY"

monkeyc \
    -d "$DEVICE" \
    -f "$JUNGLE_FILE" \
    -o "$OUTPUT" \
    -y "$DEV_KEY" \
    -w

if [ $? -eq 0 ]; then
    echo "Build successful! Output: $OUTPUT"
    echo "Copy this file to your Garmin device's GARMIN/APPS folder"
else
    echo "Build failed!"
    exit 1
fi
