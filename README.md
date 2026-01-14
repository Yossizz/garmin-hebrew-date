# Hebrew Date App for Garmin Watches 🇮🇱

A Garmin Connect IQ application that displays the Hebrew calendar date in actual Hebrew characters.

## Features

✨ **Hebrew Calendar**
- Displays current Hebrew date with day of week
- Hebrew numerals (כ״ה, ט״ו, etc.)
- Hebrew month names (תשרי, חשוון, כסלו, טבת, etc.)
- Full leap year support (אדר א׳ and אדר ב׳)
- Accurate date conversion from Gregorian calendar

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
- Updates automatically at midnight

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
│   └── HebrewFont.mc       # Hebrew text utilities
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

- Connect IQ SDK 2.3.0+
- Developer key for signing
- Garmin device or simulator

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

- [ ] Add widget version
- [ ] Include Hebrew year display
- [ ] Add holidays and special dates
- [ ] Support more Garmin devices
- [ ] Add customization options

---

Made with ❤️ for the Hebrew-speaking Garmin community
