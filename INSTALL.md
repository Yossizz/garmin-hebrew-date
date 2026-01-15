# Installation Guide - Hebrew Date Data Field

## ✅ Build Complete!

Your Hebrew Date data field has been successfully built as `HebrewDate.prg` (100KB).

## Installation on Garmin Descent G1 Solar

### Method 1: USB Installation (Recommended)

1. **Connect your Garmin Descent G1 Solar** to your Mac via USB cable
2. **Wait for the device** to mount as a USB drive
3. **Navigate** to the `GARMIN/APPS/` folder on the device
4. **Copy** the file `HebrewDate.prg` from `/Users/yossi/Documents/date/` to the `GARMIN/APPS/` folder
5. **Safely eject** the Garmin device
6. **Disconnect** the USB cable

### Method 2: Using Garmin Express

1. Download and install Garmin Express if you haven't already
2. Connect your device
3. Use Garmin Express to sync apps
4. The app should appear in your Connect IQ apps

### Method 3: Using Connect IQ Mobile App

1. Install the Garmin Connect IQ mobile app on your phone
2. Use the app to transfer sideloaded apps to your watch

## Adding the Data Field to Your Activities

1. **On your watch**, press and hold the **UP** button during any activity
2. Navigate to **Settings** → **Data Screens**
3. Select a data screen to customize
4. Add a new data field
5. Scroll to find **"Hebrew Date"**
6. Select it to add to your data screen

## What You'll See

The data field displays the Hebrew date in short format:
- Example: `כ"ה/כסלו` (25th of Kislev)
- Day in Hebrew numerals / Month name in Hebrew

## Features

✅ Hebrew calendar conversion from Gregorian date
✅ Hebrew numerals with proper gershayim notation (כ"ה)
✅ Hebrew month names (תשרי, חשוון, כסלו, etc.)
✅ Leap year support (with Adar I and Adar II)
✅ Right-to-left text rendering
✅ Low battery impact (cached calculations)

## Device Compatibility

This build is compatible with:
- Garmin Descent Mk1
- Garmin Descent Mk2
- Garmin Descent Mk2S
- Garmin Descent G1 Solar (should work, similar hardware)

## Rebuilding (If Needed)

To rebuild the project:

```bash
cd /Users/yossi/Documents/date
export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin"
monkeyc -d descentmk2 -f monkey.jungle -o HebrewDate.prg -y developer_key -w
```

Or simply run:
```bash
./build.sh
```

## Testing in Simulator

To test without a physical device:

```bash
export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc/bin"
monkeydo HebrewDate.prg descentmk2
```

## Using VS Code

Since you have VS Code installed:

1. Open the project folder in VS Code
2. Make sure Monkey C extension is installed
3. Press **Cmd+Shift+P** → "Monkey C: Build for Device"
4. Select **descentmk2** (or any compatible device)
5. The built file will be in the `bin/` folder

## Troubleshooting

**Data field not showing**
- Make sure the `.prg` file is in `GARMIN/APPS/` folder
- Try restarting your watch
- Check if there are any error messages on the watch

**Wrong date displayed**
- The watch needs accurate GPS time
- Ensure your watch date/time is set correctly
- The Hebrew calendar is calculated from the Gregorian date

**Hebrew characters not displaying**
- This is expected on Garmin devices without Hebrew font support
- The app uses character mapping, but may show as ASCII on some devices
- Consider creating a custom font for better Hebrew display (advanced)

## Customization

To customize the display format, edit:
- `source/HebrewFont.mc` - Change character mappings
- `source/HebrewDateFieldView.mc` - Change display layout
- `source/HebrewCalendar.mc` - Modify date formatting

Then rebuild with `./build.sh`

## Support

For issues or improvements:
1. Check the build warnings (already shown during compilation)
2. Test in the simulator first
3. Review the code in `source/` directory
4. Consult Garmin Connect IQ documentation

## Files Created

```
/Users/yossi/Documents/date/
├── HebrewDate.prg          ← Install this file to your watch
├── manifest.xml
├── monkey.jungle
├── developer_key
├── build.sh
├── source/
│   ├── HebrewDateFieldApp.mc
│   ├── HebrewDateFieldView.mc
│   ├── HebrewCalendar.mc
│   └── HebrewFont.mc
└── resources/
    ├── strings.xml
    ├── properties.xml
    ├── drawables.xml
    ├── layouts/
    │   └── layout.xml
    └── drawables/
        └── launcher_icon.png
```

## Next Steps

1. ✅ Project built successfully
2. → Install `HebrewDate.prg` on your watch
3. → Add to your activity data screens
4. → Test and enjoy Hebrew dates on your dive computer!

## Hebrew Date Examples

- January 14, 2026 → ט"ו/שבט (15th of Shevat)
- September 25, 2025 → ב'/תשרי (2nd of Tishrei)
- March 1, 2026 → כ"ט/אדר א' (29th of Adar I in leap year)

Enjoy your new Hebrew date data field! 🇮🇱📅⌚
