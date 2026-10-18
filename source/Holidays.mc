using Toybox.Lang;

// Festivals, fasts, Rosh Chodesh, Israeli national days, Omer and Hallel.
// Months are biblical (1 = Nisan, 7 = Tishrei, 12/13 = Adar), see HebrewCalendar.
(:glance)
module Holidays {

    // The day's observances, most important first (possibly empty).
    function forDay(y, m, d, jdn, israel) {
        var out = [];
        var dow = HebrewCalendar.dayOfWeek(jdn);
        var leap = HebrewCalendar.isLeapYear(y);

        var name = festival(m, d, leap, israel);
        if (name != null) {
            out.add(name);
        }
        name = fast(m, d, dow, leap);
        if (name != null) {
            out.add(name);
        }
        var ch = chanukahDay(y, jdn);
        if (ch > 0) {
            out.add(HebrewText.numeral(ch) + " חנוכה");
        }
        name = israeliDay(y, m, d);
        if (name != null) {
            out.add(name);
        }
        name = roshChodesh(y, m, d);
        if (name != null) {
            out.add(name);
        }
        return out;
    }

    function festival(m, d, leap, israel) {
        if (m == 7) {
            if (d == 1) { return "א׳ ראש השנה"; }
            if (d == 2) { return "ב׳ ראש השנה"; }
            if (d == 9) { return "ערב יום כיפור"; }
            if (d == 10) { return "יום כיפור"; }
            if (d == 14) { return "ערב סוכות"; }
            if (d == 15) { return "סוכות"; }
            if (d == 16 && !israel) { return "ב׳ סוכות"; }
            if (d >= 16 && d <= 20) { return "חול המועד סוכות"; }
            if (d == 21) { return "הושענא רבה"; }
            if (d == 22) { return israel ? "שמחת תורה" : "שמיני עצרת"; }
            if (d == 23 && !israel) { return "שמחת תורה"; }
        } else if (m == 6) {
            if (d == 29) { return "ערב ראש השנה"; }
        } else if (m == 1) {
            if (d == 14) { return "ערב פסח"; }
            if (d == 15) { return "פסח"; }
            if (d == 16 && !israel) { return "ב׳ פסח"; }
            if (d >= 16 && d <= 20) { return "חול המועד פסח"; }
            if (d == 21) { return "שביעי של פסח"; }
            if (d == 22 && !israel) { return "אחרון של פסח"; }
        } else if (m == 2) {
            if (d == 14) { return "פסח שני"; }
            if (d == 18) { return "ל״ג בעומר"; }
        } else if (m == 3) {
            if (d == 5) { return "ערב שבועות"; }
            if (d == 6) { return "שבועות"; }
            if (d == 7 && !israel) { return "ב׳ שבועות"; }
        } else if (m == 5) {
            if (d == 15) { return "ט״ו באב"; }
        } else if (m == 11) {
            if (d == 15) { return "ט״ו בשבט"; }
        }
        if (m == (leap ? 13 : 12)) {
            if (d == 14) { return "פורים"; }
            if (d == 15) { return "שושן פורים"; }
        }
        if (leap && m == 12 && d == 14) {
            return "פורים קטן";
        }
        return null;
    }

    // Fasts that fall on Shabbat move to Sunday; Ta'anit Esther moves back to Thursday.
    function fast(m, d, dow, leap) {
        if (m == 7 && ((d == 3 && dow != 6) || (d == 4 && dow == 0))) { return "צום גדליה"; }
        if (m == 10 && d == 10) { return "עשרה בטבת"; }
        if (m == (leap ? 13 : 12) && ((d == 13 && dow != 6) || (d == 11 && dow == 4))) { return "תענית אסתר"; }
        if (m == 4 && ((d == 17 && dow != 6) || (d == 18 && dow == 0))) { return "שבעה עשר בתמוז"; }
        if (m == 5 && ((d == 9 && dow != 6) || (d == 10 && dow == 0))) { return "תשעה באב"; }
        return null;
    }

    // 1-8 during Chanukah, else 0.
    function chanukahDay(y, jdn) {
        var n = jdn - HebrewCalendar.toJdn(y, 9, 25) + 1;
        return (n >= 1 && n <= 8) ? n : 0;
    }

    // Yom HaShoah, Yom HaZikaron, Yom HaAtzmaut (with the Knesset's date shifts) and Yom Yerushalayim.
    function israeliDay(y, m, d) {
        if (m == 1 && d >= 26 && d <= 28) {
            var dow27 = HebrewCalendar.dayOfWeek(HebrewCalendar.toJdn(y, 1, 27));
            var shoah = (dow27 == 5) ? 26 : ((dow27 == 0) ? 28 : 27);
            return (d == shoah) ? "יום השואה" : null;
        }
        if (m == 2) {
            if (d == 28) {
                return "יום ירושלים";
            }
            if (d >= 2 && d <= 6) {
                var atz = atzmautDay(y);
                if (d == atz) { return "יום העצמאות"; }
                if (d == atz - 1) { return "יום הזיכרון"; }
            }
        }
        return null;
    }

    // Day of Iyar on which Yom HaAtzmaut is observed.
    function atzmautDay(y) {
        var dow5 = HebrewCalendar.dayOfWeek(HebrewCalendar.toJdn(y, 2, 5));
        if (dow5 == 5) { return 4; }     // Friday   -> Thursday
        if (dow5 == 6) { return 3; }     // Shabbat  -> Thursday
        if (dow5 == 1) { return 6; }     // Monday   -> Tuesday
        return 5;
    }

    function roshChodesh(y, m, d) {
        if (d == 30) {
            var next = (m == HebrewCalendar.lastMonth(y)) ? 1 : m + 1;
            return "ראש חודש " + HebrewText.monthName(y, next);
        }
        if (d == 1 && m != 7) {
            return "ראש חודש " + HebrewText.monthName(y, m);
        }
        return null;
    }

    // Day of the Omer (1-49), else 0. Counted from the night after 15 Nisan.
    function omer(y, jdn) {
        var n = jdn - HebrewCalendar.toJdn(y, 1, 15);
        return (n >= 1 && n <= 49) ? n : 0;
    }

    // 0 = none, 1 = full Hallel, 2 = half Hallel.
    function hallel(y, m, d, jdn, israel) {
        if (m == 7 && d >= 15 && d <= (israel ? 22 : 23)) { return 1; }
        if (chanukahDay(y, jdn) > 0) { return 1; }
        if (m == 1 && (d == 15 || (d == 16 && !israel))) { return 1; }
        if (m == 3 && (d == 6 || (d == 7 && !israel))) { return 1; }
        if (israel && m == 2 && (d == 28 || d == atzmautDay(y))) { return 1; }
        if (m == 1 && d >= 16 && d <= (israel ? 21 : 22)) { return 2; }
        if (roshChodesh(y, m, d) != null) { return 2; }
        return 0;
    }

    // If today is Erev Yom Tov (or a first Yom Tov day followed by another),
    // the number of days until the Yom Tov ends; else 0.
    function erevYomTov(m, d, israel) {
        var two = israel ? 1 : 2;
        if (m == 6 && d == 29) { return 2; }                     // Erev Rosh Hashana
        if (m == 7) {
            if (d == 1) { return 1; }                            // Rosh Hashana, day 1
            if (d == 9) { return 1; }                            // Erev Yom Kippur
            if (d == 14 || d == 21) { return two; }              // Erev Sukkot / Shemini Atzeret
            if (!israel && (d == 15 || d == 22)) { return 1; }
        }
        if (m == 1) {
            if (d == 14 || d == 20) { return two; }              // Erev Pesach / Shevi'i shel Pesach
            if (!israel && (d == 15 || d == 21)) { return 1; }
        }
        if (m == 3) {
            if (d == 5) { return two; }                          // Erev Shavuot
            if (!israel && d == 6) { return 1; }
        }
        return 0;
    }
}
