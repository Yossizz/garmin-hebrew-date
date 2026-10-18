# Hebrew Date for Garmin Watches

A Garmin Connect IQ widget and glance that shows today's Hebrew date in Hebrew letters, together with holidays, the weekly parasha, the Omer count, Shabbat / Yom Tov times and a compass that points to Jerusalem.

## Features

**Hebrew calendar**
- Day, date and year in Hebrew, for example יום ראשון · ז׳ חשוון · תשפ״ז, including leap years (אדר א׳ / אדר ב׳).
- The date changes at **local sunset**, using the last GPS position. After sunset the day reads ליל ... (this can be turned off in settings).
- The conversion follows Reingold & Dershowitz and is checked day by day against [pyluach](https://github.com/simlist/pyluach) for 5780–5810.

**Holidays and readings**
- Festivals, Chol HaMoed and erev days, plus fasts with their postponements: Gedaliah, 10 Tevet, Esther, 17 Tammuz and 9 Av.
- Rosh Chodesh, Chanukah (day count), Purim, Shushan Purim and Purim Katan.
- Israeli national days with the official date shifts: Yom HaShoah, HaZikaron, HaAtzmaut and Yerushalayim.
- The weekly parasha for the coming Shabbat, including double parshiyot, using Dr. Irv Bromberg's rules.
- Sefirat HaOmer and Hallel (full / half).
- An **Israel / Diaspora** setting covers one- or two-day Yom Tov, Hallel and the parasha schedule.

**Shabbat and Yom Tov times**
- Shown on Friday, on Shabbat and on Erev Yom Tov (including a Yom Tov that runs into Shabbat).
- Candle lighting is sunset − 18 min, or − 35 min in Jerusalem. Havdalah is sunset + 40 min.
- Sunset uses the USNO sunrise equation.

**Compass to Jerusalem**
- A two-tone needle in the Descent G1 sub-screen.
- Uses multi-GNSS for a faster lock, vibrates on the first fix, and shows a progress ring while it is still working from the cached position.
- The heading is polled 4× per second while the widget is open.

## On the watch

- **Glance:** day, date and the most relevant extra line (holiday, Omer or parasha).
- **Widget:** START switches between:
  - **Summary:** day, year, date, observances and, when relevant, כניסה / יציאה times.
  - **Details:** sunset, every observance line, and diagnostics (GPS state, compass heading, bearing to Jerusalem).
- **Settings** (Connect IQ app): Israel calendar; new date at sunset.

Compatible device: **Garmin Descent G1 / G1 Solar**. The layout is built around its round sub-screen.

## Building

Requires the Connect IQ SDK (SDK Manager, current SDK + Descent G1 device), Java, and a developer key. `build.sh` looks for `./developer_key`, `~/.Garmin/ConnectIQ/developer_key` or `~/.connectiq-keys/developer_key.der`.

```bash
./build.sh            # debug build -> bin/HebrewDate-descentg1.prg
./build.sh sim        # debug build + run in the simulator
./build.sh demo       # simulator run pretending it is Friday 15:00 in Tel Aviv (Shabbat times)
./build.sh test       # unit tests + a 31-year calendar dump
./build.sh release    # release .prg for sideloading
./build.sh iq         # release .iq for the Connect IQ Store
```

Verify the calendar against pyluach after changing calendar code:

```bash
./build.sh test > /tmp/dump.txt
pip install pyluach && python3 tools/verify_calendar.py /tmp/dump.txt
```

## Project structure

```
source/
├── HebrewDateApp.mc        # entry point (widget + glance)
├── HebrewDateView.mc       # widget pages, GPS, compass, Shabbat times
├── HebrewDateGlance.mc     # glance
├── Today.mc                # "now": sunset switch, observances, parasha
├── HebrewCalendar.mc       # JDN <-> Hebrew date (biblical month numbering, 1 = Nisan)
├── HebrewText.mc           # Hebrew numerals, month / day / parasha names
├── Holidays.mc             # festivals, fasts, Rosh Chodesh, Israeli days, Omer, Hallel, Erev Yom Tov
├── Parasha.mc              # weekly Torah portion
├── SunTimes.mc             # sunset, candle lighting, havdalah
├── Compass.mc              # bearing / GPS quality helpers
├── Demo.mc                 # real clock, or the Shabbat demo clock (./build.sh demo)
└── *Test.mc                # unit tests and the calendar dump
store/                      # Connect IQ Store icons, screenshot and listing text
tools/verify_calendar.py    # compares the dump with pyluach
```

## Troubleshooting

- **No vibration / arrow off:** go outside and wait for the vibration (the first fix). If the needle is still off, calibrate the compass in the watch's sensor settings and hold the watch level. On the details page, מצפן should match the watch's own compass app.
- **Shabbat times show a dot:** the times come from a cached location; they update after the GPS fix.
- **Date changed early or late:** the sunset switch uses the last GPS position. Open the widget once in a new place to refresh it.

## Hebrew month reference

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

## License

[MIT License](LICENSE)

---

Made for the Hebrew-speaking Garmin community
