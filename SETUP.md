# Setup Guide for Hebrew Date Data Field Development

## Prerequisites

You need to install the Garmin Connect IQ SDK to build this project.

## Installation Steps

### Step 1: Download Connect IQ SDK

1. **Visit the official SDK download page:**
   ```bash
   open https://developer.garmin.com/connect-iq/sdk/
   ```

2. **Download the SDK for macOS**
   - Click on "Download SDK for macOS"
   - This will download a file like `connectiq-sdk-mac-latest.dmg`

3. **Install the SDK**
   - Open the downloaded DMG file
   - Drag the SDK folder to your desired location (e.g., `~/connectiq-sdk`)
   - Or it may install to: `~/Library/Application Support/Garmin/ConnectIQ/Sdks/`

### Step 2: Set Up PATH

Add the SDK's bin directory to your PATH:

```bash
# Find where the SDK was installed
# Common locations:
# ~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-*/bin
# ~/connectiq-sdk/bin

# Add to your ~/.zshrc:
echo 'export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-4.2.4-2024-01-24-6d27c73b7/bin"' >> ~/.zshrc

# Or find it automatically:
SDK_PATH=$(find "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" -name "bin" -type d 2>/dev/null | head -n 1)
echo "export PATH=\"\$PATH:$SDK_PATH\"" >> ~/.zshrc

# Reload your shell
source ~/.zshrc
```

### Step 3: Install Monkey C Extension in VS Code (Optional but Recommended)

Since you already have VS Code installed:

1. **Open VS Code**
2. **Install Monkey C Extension**
   - Open Extensions (Cmd+Shift+X)
   - Search for "Monkey C"
   - Install the official Garmin Monkey C extension
3. **Configure SDK Path**
   - Open Command Palette (Cmd+Shift+P)
   - Type "Monkey C: Edit SDK and Products"
   - Point it to your SDK installation
4. **Select Device**
   - In the status bar, click on the device selector
   - Choose "descentg1solar"

### Option 2: Command Line Installation (macOS)

1. **Download Connect IQ SDK**
   ```bash
   # Visit the official Garmin developer site
   open https://developer.garmin.com/connect-iq/sdk/
   ```
   
   Download the SDK for macOS (usually a .dmg file)

2. **Install the SDK**
   ```bash
   # Mount the DMG and install to Applications
   # Or extract to a custom location like ~/connectiq-sdk
   ```

3. **Add to PATH**
   ```bash
   # Add this to your ~/.zshrc file:
   export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-4.2.4-2024-01-24-6d27c73b7/bin"
   
   # Or if you installed to a custom location:
   export PATH="$PATH:/path/to/connectiq-sdk/bin"
   
   # Then reload your shell:
   source ~/.zshrc
   ```

4. **Verify Installation**
   ```bash
   monkeyc --version
   ```

### Option 3: Using Homebrew (if available)

```bash
# Note: Check if there's a homebrew formula available
brew search garmin
```

## Generate Developer Key

Before building, you need a developer key:

```bash
# Create directory
mkdir -p ~/.Garmin/ConnectIQ

# Generate key (4096-bit RSA)
openssl genrsa -out ~/.Garmin/ConnectIQ/developer_key 4096
```

## Building the Project

### Using VS Code
1. Open the project folder
2. Press Cmd+Shift+P
3. Select "Monkey C: Build for Device"
4. Choose "descentg1solar"

### Using Command Line
```bash
cd /Users/yossi/Documents/date

# Build the project
monkeyc \
  -d descentg1solar \
  -f monkey.jungle \
  -o HebrewDate.prg \
  -y ~/.Garmin/ConnectIQ/developer_key \
  -w
```

### Using the Build Script
```bash
chmod +x build.sh
./build.sh
```

## Testing

### Using Simulator
```bash
# Start the simulator
connectiq

# Or with a specific device
monkeydo HebrewDate.prg descentg1solar
```

### On Real Device
1. Connect your Garmin Descent G1 Solar via USB
2. Copy `HebrewDate.prg` to `GARMIN/APPS/` folder on the device
3. Safely eject the device
4. The data field will appear in your Connect IQ apps

## Creating the Launcher Icon

Before building, you should create a launcher icon:

1. Create an 80x80 PNG image
2. Name it `launcher_icon.png`
3. Place it in `resources/drawables/`
4. Design suggestions:
   - Hebrew letters (תאריך, לוח)
   - Calendar icon with Hebrew date
   - Use high contrast colors

You can use these tools:
- **Online**: Canva, Figma (free tier)
- **Desktop**: GIMP (free), Photoshop, Sketch
- **Quick option**: Use an existing icon and modify it

## Troubleshooting

### Command not found: monkeyc
- Make sure you've installed the SDK
- Check that the SDK's bin directory is in your PATH
- Try restarting your terminal

### Build errors
- Verify manifest.xml has correct syntax
- Check that all source files are present
- Ensure developer key exists

### Device not recognized
- Try a different USB port/cable
- Enable USB debugging on device
- Check USB mode (should be "Mass Storage" or "File Transfer")

### Icon errors
- Verify launcher_icon.png is 80x80 pixels
- Check that the file is actually PNG format
- Ensure it's in resources/drawables/

## Alternative: Quick Start Without SDK

If you just want to test the logic without building for the device:

1. Use the Connect IQ Simulator online: https://developer.garmin.com/connect-iq/playground/
2. Copy/paste the code from the source files
3. Test the Hebrew calendar conversion logic

## Next Steps

1. Install the SDK using one of the methods above
2. Generate your developer key
3. Create the launcher icon
4. Build the project
5. Test in simulator
6. Deploy to your Garmin Descent G1 Solar

## Resources

- [Connect IQ Programmer's Guide](https://developer.garmin.com/connect-iq/programmers-guide/)
- [API Documentation](https://developer.garmin.com/connect-iq/api-docs/)
- [Developer Forums](https://forums.garmin.com/developer/connect-iq/)
- [Connect IQ Store](https://apps.garmin.com/en-US/)

## Support

If you encounter issues:
1. Check the Connect IQ forums
2. Review the API documentation for your device
3. Test in the simulator first
4. Verify all file paths and syntax
