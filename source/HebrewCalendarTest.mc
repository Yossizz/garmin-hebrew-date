using Toybox.Lang;
using Toybox.System;
using Toybox.Test;

(:test)
function testNumerals(logger) {
    Test.assertEqual(HebrewText.numeral(1), "א׳");
    Test.assertEqual(HebrewText.numeral(7), "ז׳");
    Test.assertEqual(HebrewText.numeral(15), "ט״ו");
    Test.assertEqual(HebrewText.numeral(16), "ט״ז");
    Test.assertEqual(HebrewText.numeral(30), "ל׳");
    Test.assertEqual(HebrewText.numeral(49), "מ״ט");
    Test.assertEqual(HebrewText.numeral(5787), "תשפ״ז");
    Test.assertEqual(HebrewText.numeral(5800), "ת״ת");
    return true;
}

(:test)
function testKnownDates(logger) {
    // 2026-10-18 = 7 Cheshvan 5787; Rosh Hashana 5786 = 2025-09-23; 5787 = 2026-09-12
    var h = HebrewCalendar.fromJdn(HebrewCalendar.gregorianToJdn(2026, 10, 18));
    Test.assertEqual(h[0], 5787);
    Test.assertEqual(h[1], 8);
    Test.assertEqual(h[2], 7);
    Test.assertEqual(HebrewCalendar.newYear(5786), HebrewCalendar.gregorianToJdn(2025, 9, 23));
    Test.assertEqual(HebrewCalendar.newYear(5787), HebrewCalendar.gregorianToJdn(2026, 9, 12));
    Test.assertEqual(HebrewText.date(5787, 8, 7), "ז׳ חשוון");
    Test.assertEqual(HebrewText.monthName(5784, 12), "אדר א׳");
    Test.assertEqual(HebrewCalendar.dayOfWeek(HebrewCalendar.gregorianToJdn(2026, 10, 18)), 0);
    return true;
}

// Yom HaShoah / HaZikaron / HaAtzmaut with the official date shifts.
(:test)
function testIsraeliDays(logger) {
    Test.assertEqual(israeliOn(2023, 4, 18), "יום השואה");      // 27 Nisan, Tuesday
    Test.assertEqual(israeliOn(2024, 5, 6), "יום השואה");       // 27 Nisan Sunday -> Monday
    Test.assertEqual(israeliOn(2025, 4, 24), "יום השואה");      // 27 Nisan Friday -> Thursday
    Test.assertEqual(israeliOn(2023, 4, 26), "יום העצמאות");    // 5 Iyar, Wednesday
    Test.assertEqual(israeliOn(2024, 5, 14), "יום העצמאות");    // 5 Iyar Monday -> Tuesday
    Test.assertEqual(israeliOn(2024, 5, 13), "יום הזיכרון");
    Test.assertEqual(israeliOn(2025, 5, 1), "יום העצמאות");     // 5 Iyar Shabbat -> Thursday
    Test.assertEqual(israeliOn(2025, 4, 30), "יום הזיכרון");
    Test.assertEqual(israeliOn(2022, 5, 5), "יום העצמאות");     // 5 Iyar Friday -> Thursday
    Test.assertEqual(israeliOn(2024, 6, 5), "יום ירושלים");
    return true;
}

function israeliOn(gy, gm, gd) {
    var jdn = HebrewCalendar.gregorianToJdn(gy, gm, gd);
    var h = HebrewCalendar.fromJdn(jdn);
    return Holidays.israeliDay(h[0], h[1], h[2]);
}

(:test)
function testOmerAndParasha(logger) {
    // 16 Nisan 5786 = 2026-04-03 is the first day of the Omer; Lag BaOmer = day 33
    Test.assertEqual(Holidays.omer(5786, HebrewCalendar.toJdn(5786, 1, 16)), 1);
    Test.assertEqual(Holidays.omer(5786, HebrewCalendar.toJdn(5786, 2, 18)), 33);
    Test.assertEqual(Holidays.omer(5786, HebrewCalendar.toJdn(5786, 3, 6)), 0);
    // Shabbat 2026-10-24 = Lech Lecha
    Test.assertEqual(HebrewText.parasha(Parasha.forShabbat(HebrewCalendar.gregorianToJdn(2026, 10, 24), true)), "פרשת לך לך");
    return true;
}

// Day-by-day dump compared against pyluach by tools/verify_calendar.py.
// D|jdn|y|m|d|coreDiaspora|coreIsrael|fast|omer|parashaDiaspora|parashaIsrael
function dumpYear(y) {
    var start = HebrewCalendar.newYear(y);
    var end = HebrewCalendar.newYear(y + 1);
    for (var jdn = start; jdn < end; jdn++) {
        var h = HebrewCalendar.fromJdn(jdn);
        var dow = HebrewCalendar.dayOfWeek(jdn);
        var leap = HebrewCalendar.isLeapYear(h[0]);
        var fast = Holidays.fast(h[1], h[2], dow, leap) != null;
        var ch = Holidays.chanukahDay(h[0], jdn) > 0;
        var line = "D|" + jdn + "|" + h[0] + "|" + h[1] + "|" + h[2] + "|"
            + flag(core(h, false) || fast || ch) + "|" + flag(core(h, true) || fast || ch) + "|"
            + flag(fast) + "|" + Holidays.omer(h[0], jdn) + "|";
        if (dow == 6) {
            line += par(Parasha.forShabbat(jdn, false)) + "|" + par(Parasha.forShabbat(jdn, true));
        } else {
            line += "|";
        }
        System.println(line);
    }
}

function core(h, israel) {
    var f = Holidays.festival(h[1], h[2], HebrewCalendar.isLeapYear(h[0]), israel);
    return f != null && f.find("ערב") != 0;
}

function flag(b) {
    return b ? "1" : "0";
}

function par(p) {
    if (p == null) {
        return "-";
    }
    return (p.size() == 1) ? p[0].toString() : p[0] + "," + p[1];
}
