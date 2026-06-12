# Hebrew Date App for Garmin Watches

A Garmin Connect IQ application that displays the Hebrew calendar date in Hebrew characters, a GPS compass pointing to Jerusalem, and Shabbat candle lighting / havdalah times.

## Features

**Hebrew Calendar**
- Current Hebrew date with day of week in Hebrew
- Hebrew numerals (כ״ה, ט״ו, etc.)
- Hebrew month names (תשרי, חשוון, כסלו, etc.)
- Full leap year support (אדר א׳ and אדר ב׳)

**Praying Compass**
- GPS-powered classic two-tone needle pointing to Jerusalem
- White tip toward Jerusalem, outlined tail pointing away
- Smooth rotation driven by magnetometer sensor events
- GPS acquisition circle fills while acquiring signal
- Vibration feedback on GPS lock

**GPS Fast-Lock**
- Uses last-known cached position instantly on startup for immediate compass display
- Continues acquiring a fresh fix in background (important when traveling abroad)
- Once a real fix arrives, bearing and Shabbat times are updated automatically
- Small dot indicator shown when times are based on cached location

**Shabbat Times (Fridays only)**
- Candle lighting: Friday sunset − 35 minutes (Jerusalem standard)
- Havdalah: Saturday sunset + 40 minutes (Israeli standard / Gra opinion)
- Astronomical sunset calculated via USNO sunrise equation
- Jerusalem rule: 35-minute early candle lighting offset
- Elsewhere: 18-minute offset
- Times auto-update when fresh GPS confirms your actual location

**Compatible Devices**
- Garmin Descent G1 / G1 Solar
- Garmin Descent Mk1

## Display

**Normal days:**
```
      שני         ← day of week        [compass]
    י״ב סיוון     ← Hebrew date
```

**Fridays:**
```
      שישי                             [compass]
    כ׳ סיוון
   כניסה: | 19:10
   יציאה: | 20:23
      •              ← dot = cached location, disappears after fresh GPS fix
```

## Installation

1. Download `HebrewDate.prg` from [Releases](../../releases)
2. Connect Garmin watch via USB
3. Copy to `GARMIN/APPS/HebrewDate.prg`
4. Eject and restart watch (hold LIGHT to power off, then on)
5. Launch "Hebrew Date" from the app menu

## Building from Source

```bash
git clone https://github.com/Yossizz/garmin-hebrew-date.git
cd garmin-hebrew-date

# Generate developer key (one time)
openssl genrsa -out developer_key 4096

# Build for device
./build.sh

# Build and launch in simulator
./run_simulator.sh
```

Requires Garmin Connect IQ SDK 8.x. See [BUILD.md](BUILD.md) for details.

## Project Structure

```
garmin-hebrew-date/
├── manifest.xml          # App configuration
├── monkey.jungle         # Build settings
├── build.sh              # Build script
├── run_simulator.sh      # Build + launch simulator
├── source/
│   ├── HebrewDateApp.mc    # Application entry point
│   ├── HebrewDateView.mc   # Main view, UI, GPS logic
│   ├── HebrewCalendar.mc   # Hebrew calendar conversion
│   ├── HebrewFont.mc       # Hebrew text utilities
│   └── Compass.mc          # GPS, compass, sunset calculations
└── resources/
    ├── drawables.xml
    ├── properties.xml
    └── strings.xml
```

## Technical Details

### Sunset Calculation

Uses the USNO sunrise equation with fixes for Monkey C's 32-bit float limitations:
- Works in J2000.0 offsets (~9652 days) rather than absolute Julian dates (~2461197) to avoid float32 precision loss
- `fmod()` helper replaces `%` operator which only works on integers in Monkey C
- Horizon angles: −0.833° for visible sunset (refraction corrected), −8.5° for nightfall

### GPS Strategy

1. `Position.getInfo()` called synchronously on startup — uses cached position instantly if available
2. `LOCATION_CONTINUOUS` events started in background to acquire fresh fix
3. On fresh fix (`accuracy != QUALITY_LAST_KNOWN`): bearing and Shabbat times recalculated with real location, GPS stopped to save battery
4. Magnetometer driven by `onSensor` callback (event-driven, not polled) for smooth arrow rotation

### Hebrew Calendar

Gauss-based algorithm with:
- Variable month lengths (29–30 days)
- Leap year support (13 months)
- Dehiyyot (postponement rules)

### Hebrew Numerals

- Geresh (׳) for single letters: א׳, ב׳
- Gershayim (״) for compound: כ״ה, י״א
- Special cases for 15 (ט״ו) and 16 (ט״ז)

## Troubleshooting

**App doesn't appear:** Restart the watch after copying the `.prg` file.

**Wrong date:** Ensure watch time is set correctly (requires GPS or manual set).

**Compass arrow stuck:** Fixed in current version — arrow is now updated via sensor events rather than polling. If it still happens, restart the app.

**Shabbat times show a dot:** Times are calculated from a cached GPS location. Wait a moment for a fresh GPS fix — the dot disappears and times update automatically.

**Times seem off:** The app uses Israeli standard times (Gra opinion). Candle lighting = sunset − 35 min, havdalah = sunset + 40 min.

## Hebrew Month Reference

| Hebrew | Transliteration | Gregorian |
|--------|----------------|-----------|
| תשרי | Tishrei | Sep–Oct |
| חשוון | Cheshvan | Oct–Nov |
| כסלו | Kislev | Nov–Dec |
| טבת | Tevet | Dec–Jan |
| שבט | Shevat | Jan–Feb |
| אדר | Adar | Feb–Mar |
| ניסן | Nisan | Mar–Apr |
| אייר | Iyar | Apr–May |
| סיון | Sivan | May–Jun |
| תמוז | Tammuz | Jun–Jul |
| אב | Av | Jul–Aug |
| אלול | Elul | Aug–Sep |

*Leap years: אדר א׳ (Adar I) and אדר ב׳ (Adar II)*

## Roadmap

- [x] GPS compass pointing to Jerusalem
- [x] Shabbat candle lighting and havdalah times
- [x] Fast GPS lock using cached position
- [x] Accurate astronomical sunset calculation
- [x] Travel-safe: recalculates times after fresh GPS fix
- [ ] Widget version
- [ ] Hebrew year display
- [ ] Jewish holidays
- [ ] More Garmin devices

## License

[MIT License](LICENSE)

---

Made for the Hebrew-speaking Garmin community
