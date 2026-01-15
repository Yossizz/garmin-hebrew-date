# Quick Start - Build Your Hebrew Date Data Field

Follow these steps to build the data field for your Garmin Descent G1 Solar.

## Step 1: Download and Install Connect IQ SDK

```bash
# 1. Download the SDK from Garmin's official site
open https://developer.garmin.com/connect-iq/sdk/

# 2. After downloading the DMG, install it
# It typically installs to:
# ~/Library/Application Support/Garmin/ConnectIQ/Sdks/

# 3. Find your SDK installation
ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"
```

## Step 2: Add SDK to Your PATH

```bash
# Find the SDK bin directory
find "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" -name "monkeyc" 2>/dev/null

# Add to PATH (adjust the version number based on what you found above)
echo 'export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-4.2.4-2024-01-24-6d27c73b7/bin"' >> ~/.zshrc

# Reload your shell
source ~/.zshrc

# Verify installation
monkeyc --version
```

## Step 3: Generate Developer Key

```bash
mkdir -p ~/.Garmin/ConnectIQ
openssl genrsa -out ~/.Garmin/ConnectIQ/developer_key 4096
```

## Step 4: Create Launcher Icon

Create a simple launcher icon or use a placeholder:

```bash
# You can create a simple colored square as a placeholder for now
# Or download/create an 80x80 PNG with Hebrew letters/calendar icon
# Place it at: resources/drawables/launcher_icon.png
```

For now, let's create a placeholder:

```bash
cd /Users/yossi/Documents/date/resources/drawables
# You'll need to add an actual PNG file here before building
```

## Step 5: Build the Project

```bash
cd /Users/yossi/Documents/date

# Build using monkeyc directly
monkeyc \
  -d descentg1solar \
  -f monkey.jungle \
  -o HebrewDate.prg \
  -y ~/.Garmin/ConnectIQ/developer_key \
  -w

# Or use the build script
chmod +x build.sh
./build.sh
```

## Step 6: Test in Simulator (Optional)

```bash
# Run in simulator
monkeydo HebrewDate.prg descentg1solar

# Or start the simulator GUI
connectiq
```

## Step 7: Install on Your Device

1. Connect your Garmin Descent G1 Solar to your Mac via USB
2. It should mount as a USB drive
3. Copy `HebrewDate.prg` to the `GARMIN/APPS/` folder on the device
4. Safely eject the device
5. On the watch, go to an activity and add the "Hebrew Date" data field

## Troubleshooting

**"monkeyc: command not found"**
- Make sure you've added the SDK bin directory to your PATH
- Close and reopen your terminal
- Verify the path is correct: `echo $PATH | grep -i garmin`

**Can't find SDK installation**
```bash
# Try these locations:
ls ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/
ls ~/connectiq-sdk/
```

**Build errors about launcher_icon.png**
- You must create an 80x80 PNG file at `resources/drawables/launcher_icon.png`
- Quick fix: Find any 80x80 PNG online and use it as a placeholder

## Using VS Code (Optional)

Since you already have VS Code installed:

1. Install the "Monkey C" extension
2. Open the `/Users/yossi/Documents/date` folder in VS Code
3. The extension should detect the SDK automatically
4. Use Cmd+Shift+P → "Monkey C: Build for Device"

## Resources

- Official SDK Download: https://developer.garmin.com/connect-iq/sdk/
- Getting Started Guide: https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/
- Your First App Tutorial: https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/
- API Documentation: https://developer.garmin.com/connect-iq/api-docs/
