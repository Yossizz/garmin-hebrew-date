# Hebrew Date App for Garmin Watches 🇮🇱

A Garmin Connect IQ application that displays the Hebrew calendar date in actual Hebrew characters.

## Features

✨ **Hebrew Calendar**
- Displays current Hebrew date with day of week
- Hebrew numerals (כ״ה, ט״ו, etc.)
- Hebrew month names (תשרי, חשוון, כסלו, טבת, etc.)
- Full leap year support (אדר א׳ and אדר ב׳)
- Accurate date conversion from Gregorian calendar

🧭 **Praying Compass**
- GPS-powered compass arrow pointing to Jerusalem
- Visual GPS acquisition indicator (filling circle)
- Vibration feedback when GPS locks
- Smooth arrow rotation as you turn the watch
- Multi-GNSS support (GPS + Galileo) for faster lock times
- Battery optimized (GPS stops after lock)

📱 **Standalone App**
- Launch anytime from your watch menu
- No need to start an activity
- Full-screen display
- Two-line format: Day of week + Hebrew date

🎯 **Compatible Devices**
- Garmin Descent G1
- Garmin Descent G1 Solar
- Garmin Descent Mk1
- More devices can be added easily

## Display Format

**Example (January 14, 2026):**
```
רביעי
כ״ה טבת
```
- **Line 1**: Day of week in Hebrew (Wednesday = רביעי)
- **Line 2**: Hebrew date (25th of Tevet = כ״ה טבת)
- **Top-right circle**: GPS acquisition indicator / Compass arrow pointing to Jerusalem

## Quick Start

### Installation

1. **Download** the latest `HebrewDate.prg` from [Releases](../../releases)
2. **Connect** your Garmin watch to your computer via USB
3. **Copy** `HebrewDate.prg` to the `GARMIN/APPS/` folder on your watch
4. **Eject** the watch safely
5. **⚠️ RESTART YOUR WATCH** (hold LIGHT button to power off, then power on)
6. **Launch** the "Hebrew Date" app from your watch's app menu

### Building from Source

See [BUILD.md](BUILD.md) for detailed build instructions.

**Quick build:**
```bash
git clone https://github.com/Yossizz/garmin-hebrew-date.git
cd garmin-hebrew-date

# Generate developer key (one time)
openssl genrsa -out developer_key 4096

# Build
./build.sh
```

## Usage

### On Your Watch

1. Press **START** button
2. Scroll to find **"Hebrew Date"** app
3. Press **START** to launch
4. View today's Hebrew date!

### What You'll See

The app displays:
- Current day of week in Hebrew (ראשון through שבת)
- Hebrew date with proper numerals and month name
- GPS acquisition circle (top-right) that fills as GPS signal improves
- Compass arrow (top-right) pointing to Jerusalem after GPS lock
- Updates automatically at midnight

**GPS Compass Usage:**
1. Launch the app
2. Wait for GPS lock (circle fills, watch vibrates)
3. Arrow appears pointing toward Jerusalem
4. Rotate your watch - arrow rotates smoothly to maintain direction

## Hebrew Month Reference

| Hebrew | Transliteration | Gregorian |
|--------|----------------|-----------|
| תשרי | Tishrei | Sep-Oct |
| חשוון | Cheshvan | Oct-Nov |
| כסלו | Kislev | Nov-Dec |
| טבת | Tevet | Dec-Jan |
| שבט | Shevat | Jan-Feb |
| אדר | Adar | Feb-Mar |
| ניסן | Nisan | Mar-Apr |
| אייר | Iyar | Apr-May |
| סיון | Sivan | May-Jun |
| תמוז | Tammuz | Jun-Jul |
| אב | Av | Jul-Aug |
| אלול | Elul | Aug-Sep |

*In leap years: אדר א׳ (Adar I) and אדר ב׳ (Adar II)*

## Project Structure

```
garmin-hebrew-date/
├── manifest.xml          # App configuration
├── monkey.jungle         # Build settings
├── build.sh             # Build script
├── source/
│   ├── HebrewDateApp.mc    # Application entry point
│   ├── HebrewDateView.mc   # Main view and UI
│   ├── HebrewCalendar.mc   # Hebrew calendar logic
│   ├── HebrewFont.mc       # Hebrew text utilities
│   └── Compass.mc          # GPS and compass calculations
├── resources/
│   ├── drawables/
│   │   └── launcher_icon.png
│   ├── layouts/
│   │   └── layout.xml
│   ├── drawables.xml
│   ├── properties.xml
│   └── strings.xml
└── docs/
    ├── BUILD.md          # Build instructions
    └── CONTRIBUTING.md   # Contribution guidelines
```

## Development

### Prerequisites

- Connect IQ SDK 3.2.0+ (for multi-GNSS support)
- Developer key for signing
- Garmin device or simulator
- GPS-enabled device (for compass feature)

### Building

```bash
# For device installation
monkeyc -d descentg1 -f monkey.jungle -o HebrewDate.prg -y developer_key -w

# For Connect IQ Store
monkeyc -e -f monkey.jungle -o HebrewDate.iq -y developer_key -r -w
```

### Testing

```bash
# In simulator
monkeydo HebrewDate.prg descentg1
```

See [BUILD.md](BUILD.md) for complete details.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit code improvements
- 🌍 Add support for more devices

## Technical Details

### Hebrew Calendar Conversion

The app uses a simplified Gauss-based algorithm to convert Gregorian dates to Hebrew calendar:
- Handles variable month lengths (29-30 days)
- Supports leap years (13 vs 12 months)
- Applies dehiyyot (postponement rules)
- Accurate for modern dates

### Hebrew Numerals

Hebrew numerals follow traditional formatting:
- Geresh (׳) for single letters: א׳, ב׳, ג׳
- Gershayim (״) for multiple letters: כ״ה, י״א
- Special handling for 15 (ט״ו) and 16 (ט״ז) to avoid writing God's name

### GPS Compass Feature

The praying compass uses:
- **Multi-GNSS**: GPS + Galileo constellations for faster lock (15-30 seconds)
- **Bearing Calculation**: Haversine formula to calculate direction to Jerusalem (31.7781°N, 35.2360°E)
- **Compass Integration**: Watch magnetometer for smooth arrow rotation
- **Battery Optimization**: GPS disables after lock, compass activates only when needed
- **Visual Feedback**: Filling circle shows GPS acquisition progress (0-50%)
- **Haptic Feedback**: Vibration when GPS achieves lock

### Font Support

Since Garmin devices don't natively support Hebrew Unicode, the app:
1. Converts Hebrew to ASCII mapping internally
2. Converts back to Hebrew Unicode for display
3. Works on devices with Hebrew font support (Descent series)

## Troubleshooting

### App Doesn't Appear on Watch

**Solution**: Restart your watch!
- Hold LIGHT button until watch powers off
- Press LIGHT again to power on
- This is required after copying new apps

### Wrong Date Displayed

- Ensure watch time/date is set correctly
- Watch needs GPS lock or manual time setting
- Hebrew calendar is calculated from Gregorian date

### GPS Not Locking

- Go outside with clear view of sky
- Wait 15-30 seconds for GPS + Galileo lock
- Ensure watch has GPS enabled in settings
- First lock may take longer (cold start)

### Compass Arrow Not Rotating

- Ensure GPS has locked (watch vibrated)
- Rotate watch slowly - arrow should follow
- Compass requires magnetometer sensor (available on Descent G1)
- If stuck, restart app

### Hebrew Text Shows as Boxes

- Some simulators don't display Hebrew correctly
- The app WILL work on actual Garmin devices
- Descent G1/G1 Solar have confirmed Hebrew support

## License

[MIT License](LICENSE) - see LICENSE file for details.

## Acknowledgments

- Hebrew calendar algorithm based on Gauss formula
- Built with Garmin Connect IQ SDK
- Community feedback and testing

## Support

- 📖 [Build Instructions](BUILD.md)
- 🐛 [Report Issues](../../issues)
- 💬 [Discussions](../../discussions)
- 📧 Contact: [Open an issue](../../issues/new)

## Roadmap

- [x] GPS compass pointing to Jerusalem
- [x] Multi-GNSS support for faster GPS lock
- [ ] Add widget version
- [ ] Include Hebrew year display
- [ ] Add holidays and special dates
- [ ] Support more Garmin devices
- [ ] Add customization options
- [ ] Compass calibration option

---

Made with ❤️ for the Hebrew-speaking Garmin community
