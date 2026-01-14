# Building Garmin Hebrew Date App

Complete guide to building and installing the Hebrew Date application for Garmin devices.

## Prerequisites

### 1. Install Connect IQ SDK

**For macOS:**

1. Download the SDK from [Garmin Developer Portal](https://developer.garmin.com/connect-iq/sdk/)
2. Install the DMG file
3. The SDK typically installs to: `~/Library/Application Support/Garmin/ConnectIQ/Sdks/`

**For Windows:**

1. Download the Windows SDK installer
2. Follow the installation wizard
3. SDK installs to: `C:\Garmin\ConnectIQ\Sdks\`

**For Linux:**

1. Download the Linux SDK package
2. Extract to your preferred location
3. Set up PATH environment variable

### 2. Add SDK to PATH

**macOS/Linux:**
```bash
# Find your SDK version
ls ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/

# Add to your shell profile (~/.zshrc or ~/.bashrc)
export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin"

# Reload your shell
source ~/.zshrc
```

**Windows:**
```powershell
# Add to System Environment Variables
$env:PATH += ";C:\Garmin\ConnectIQ\Sdks\connectiq-sdk-8.4.0\bin"
```

### 3. Verify Installation

```bash
monkeyc --version
# Should output: Connect IQ Compiler version: X.X.X
```

## Generate Developer Key

You need a developer key to sign your builds:

### Option 1: Using VS Code (Recommended)

1. Install [VS Code](https://code.visualstudio.com/)
2. Install the "Monkey C" extension
3. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
4. Type "Monkey C: Generate Developer Key"
5. Save as `developer_key` in the project root

### Option 2: Using OpenSSL

```bash
# Navigate to project directory
cd /path/to/garmin-hebrew-date

# Generate 4096-bit RSA key
openssl genrsa -out developer_key 4096
```

**Important:** Keep this key private! It's already in `.gitignore`.

## Building the Application

### Quick Build

```bash
# Navigate to project directory
cd /path/to/garmin-hebrew-date

# Make build script executable
chmod +x build.sh

# Run build
./build.sh
```

### Manual Build

#### For Direct Device Installation (.prg)

```bash
monkeyc \
  -d descentg1 \
  -f monkey.jungle \
  -o HebrewDate.prg \
  -y developer_key \
  -w
```

#### For Connect IQ Store (.iq package)

```bash
monkeyc \
  -e \
  -f monkey.jungle \
  -o HebrewDate.iq \
  -y developer_key \
  -r \
  -w
```

### Build Options Explained

- `-d descentg1` - Target device (Descent G1/G1 Solar)
- `-f monkey.jungle` - Jungle build configuration file
- `-o HebrewDate.prg` - Output file name
- `-y developer_key` - Your private signing key
- `-w` - Show warnings
- `-e` - Create package (for .iq files)
- `-r` - Release build (strip debug info)

### Build for Multiple Devices

To build for additional devices, edit `manifest.xml`:

```xml
<iq:products>
    <iq:product id="descentg1"/>
    <iq:product id="descentmk1"/>
    <iq:product id="descentmk2"/>
</iq:products>
```

Then rebuild with your desired device ID.

## Testing in Simulator

### Start Simulator

```bash
# Launch Connect IQ simulator
connectiq
```

### Run Application

```bash
# Run in simulator (replace descentg1 with your device)
monkeydo HebrewDate.prg descentg1
```

The simulator will open in a new window showing your app.

### Simulator Shortcuts

- **Arrow Keys** - Navigate menus
- **Enter** - Select/Start
- **Backspace** - Back button
- **Escape** - Exit app

## Installing on Device

### Method 1: USB Transfer (Recommended)

1. **Connect Device**
   - Plug your Garmin watch into your computer via USB
   - Wait for it to mount as a USB drive

2. **Copy File**
   ```bash
   # macOS/Linux
   cp HebrewDate.prg /Volumes/GARMIN/GARMIN/APPS/
   
   # Windows
   copy HebrewDate.prg E:\GARMIN\APPS\
   ```

3. **Safely Eject**
   - Eject the GARMIN drive properly
   - Don't just unplug!

4. **Restart Watch** ⚠️ **Important!**
   - Disconnect USB cable
   - Hold **LIGHT** button until watch powers off
   - Press **LIGHT** again to turn back on
   - The app should now appear in your apps list

### Method 2: Garmin Express

1. Install [Garmin Express](https://www.garmin.com/software/express/)
2. Connect your device
3. Garmin Express will detect and sync the app
4. **Restart the watch** after sync completes

### Method 3: Connect IQ Store (For Distribution)

1. Upload `HebrewDate.iq` to [Connect IQ Store](https://apps.garmin.com/developer/)
2. Users can install via Connect IQ mobile app
3. Or download directly from the store on compatible devices

## Troubleshooting

### App Not Showing Up

**Solution:** Restart the watch!
- Most common issue is the watch needs a reboot to recognize new apps
- Hold LIGHT button → Power off → Power on

### Build Errors

**"Invalid device id":**
- Check that your device is supported
- Verify device ID in manifest.xml
- Try updating SDK

**"Cannot find developer_key":**
- Generate a developer key (see above)
- Ensure it's named `developer_key` (no extension)
- Place it in project root directory

**"Invalid API Level":**
- Your device may not support the minimum API level
- Lower `minApiLevel` in manifest.xml
- Check device compatibility

### Simulator Issues

**"Unable to connect to simulator":**
- Make sure simulator is running: `connectiq`
- Try closing and reopening simulator
- Check that no other instances are running

**Hebrew characters not showing:**
- This is normal for some simulators
- Hebrew will work on the actual device
- descentg1 simulator has better Hebrew support

### Runtime Errors

**"Stack Overflow":**
- Usually a recursion issue
- Check HebrewCalendar.mc for infinite loops
- Try reducing calculation complexity

**"Out of Memory":**
- Reduce string sizes
- Optimize loops
- Clear unused variables

## Device Compatibility

Currently supported:
- ✅ Descent G1
- ✅ Descent G1 Solar
- ✅ Descent Mk1

To add more devices:
1. Check [Connect IQ Device List](https://developer.garmin.com/connect-iq/compatible-devices/)
2. Add device ID to manifest.xml
3. Rebuild and test

## Development Tips

### Using VS Code

1. Install Monkey C extension
2. Open project folder
3. Use `Cmd+Shift+P` → "Monkey C: Build for Device"
4. Select target device
5. Built files appear in `bin/` folder

### Debugging

1. Build with debug symbols (remove `-r` flag)
2. Run in simulator
3. Check simulator console for errors
4. Use `System.println()` for logging

### Code Structure

```
source/
├── HebrewDateApp.mc       - Application entry point
├── HebrewDateView.mc      - Main view and UI
├── HebrewCalendar.mc      - Hebrew calendar logic
└── HebrewFont.mc          - Hebrew text utilities
```

## Contributing

Found a bug or want to add features?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in simulator and on device
5. Submit a pull request

## Resources

- [Connect IQ Programmer's Guide](https://developer.garmin.com/connect-iq/programmers-guide/)
- [API Documentation](https://developer.garmin.com/connect-iq/api-docs/)
- [Connect IQ Forums](https://forums.garmin.com/developer/connect-iq/)
- [Device Compatibility](https://developer.garmin.com/connect-iq/compatible-devices/)

## License

See LICENSE file in repository.

---

**Need Help?** Open an issue on GitHub or check the Garmin forums.
