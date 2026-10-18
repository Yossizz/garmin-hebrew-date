using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Hebrew calendar arithmetic after Reingold & Dershowitz, "Calendrical Calculations".
// Days are Julian Day Numbers (JDN). Months use the biblical numbering:
//   1 = Nisan ... 6 = Elul, 7 = Tishrei ... 11 = Shevat,
//   12 = Adar (Adar I in a leap year), 13 = Adar II (leap years only).
(:glance)
module HebrewCalendar {

    const EPOCH_JDN = 347998;   // 1 Tishrei AM 1

    function isLeapYear(y) {
        return ((7 * y + 1) % 19) < 7;
    }

    function lastMonth(y) {
        return isLeapYear(y) ? 13 : 12;
    }

    // Days from the epoch to the molad of Tishrei, applying "lo ADU Rosh".
    function elapsedDays(y) {
        var months = (235 * y - 234) / 19;
        var parts = 12084 + 13753 * months;
        var day = 29 * months + parts / 25920;
        if ((3 * (day + 1)) % 7 < 3) {
            day += 1;
        }
        return day;
    }

    // Extra postponement that keeps every year 353-355 / 383-385 days long.
    function newYearDelay(y) {
        var ny0 = elapsedDays(y - 1);
        var ny1 = elapsedDays(y);
        var ny2 = elapsedDays(y + 1);
        if (ny2 - ny1 == 356) {
            return 2;
        }
        if (ny1 - ny0 == 382) {
            return 1;
        }
        return 0;
    }

    // Small memo: month lengths, toJdn and fromJdn all lean on newYear(), and the
    // glance has a tight watchdog budget.
    var mNewYears = {};

    // JDN of 1 Tishrei of year y.
    function newYear(y) {
        var v = mNewYears.get(y);
        if (v == null) {
            v = EPOCH_JDN + elapsedDays(y) + newYearDelay(y);
            if (mNewYears.size() >= 8) {
                mNewYears = {};
            }
            mNewYears.put(y, v);
        }
        return v;
    }

    function yearLength(y) {
        return newYear(y + 1) - newYear(y);
    }

    function monthLength(y, m) {
        if (m == 2 || m == 4 || m == 6 || m == 10 || m == 13) {
            return 29;
        }
        if (m == 12) {
            return isLeapYear(y) ? 30 : 29;
        }
        if (m == 8) {
            return (yearLength(y) % 10 == 5) ? 30 : 29;    // Cheshvan is long in complete years
        }
        if (m == 9) {
            return (yearLength(y) % 10 == 3) ? 29 : 30;    // Kislev is short in deficient years
        }
        return 30;
    }

    function toJdn(y, m, d) {
        var jdn = newYear(y) + d - 1;
        var last = lastMonth(y);
        if (m < 7) {
            for (var i = 7; i <= last; i++) {
                jdn += monthLength(y, i);
            }
            for (var i = 1; i < m; i++) {
                jdn += monthLength(y, i);
            }
        } else {
            for (var i = 7; i < m; i++) {
                jdn += monthLength(y, i);
            }
        }
        return jdn;
    }

    // [year, month, day] for a JDN.
    function fromJdn(jdn) {
        var y = ((jdn - EPOCH_JDN).toDouble() * 98496.0d / 35975351.0d).toNumber() + 1;
        while (newYear(y) > jdn) {
            y--;
        }
        while (newYear(y + 1) <= jdn) {
            y++;
        }
        var start = newYear(y);
        var last = lastMonth(y);
        var m = 7;
        while (true) {
            var len = monthLength(y, m);
            if (jdn < start + len) {
                break;
            }
            start += len;
            m = (m == last) ? 1 : m + 1;
        }
        return [y, m, jdn - start + 1];
    }

    function gregorianToJdn(y, m, d) {
        var a = (14 - m) / 12;
        var yy = y + 4800 - a;
        var mm = m + 12 * a - 3;
        return d + (153 * mm + 2) / 5 + 365 * yy + yy / 4 - yy / 100 + yy / 400 - 32045;
    }

    // 0 = Sunday ... 6 = Shabbat
    function dayOfWeek(jdn) {
        return (jdn + 1) % 7;
    }

    // JDN of the civil (local midnight-to-midnight) date of a moment.
    function civilJdn(moment) {
        var g = Gregorian.info(moment, Time.FORMAT_SHORT);
        return gregorianToJdn(g.year, g.month, g.day);
    }
}
