using Toybox.Lang;

// Weekly Torah portion, ported from pyluach's implementation of Dr. Irv Bromberg's
// rules (http://individual.utoronto.ca/kalendis/hebrew/parshah.htm).
// Parasha numbers start at 0 = Bereshit; a double parasha is [n, n + 1].
(:glance)
module Parasha {

    const VAYAKHEL = 21;
    const TAZRIA = 26;
    const ACHAREI_MOT = 28;
    const BEHAR = 31;
    const CHUKAT = 38;
    const MATOT = 41;
    const NITZAVIM = 50;

    // One year's table is cached: [year, israel, firstShabbatJdn, entries...].
    var mYear = null;
    var mIsrael = null;
    var mFirst = 0;
    var mTable = null;

    // Parasha for the Shabbat at shabbatJdn, or null when that Shabbat is a festival.
    function forShabbat(shabbatJdn, israel) {
        var y = HebrewCalendar.fromJdn(shabbatJdn)[0];
        if (mYear != y || mIsrael != israel) {
            build(y, israel);
        }
        var i = (shabbatJdn - mFirst) / 7;
        return (i >= 0 && i < mTable.size()) ? mTable[i] : null;
    }

    function build(y, israel) {
        var rh = HebrewCalendar.newYear(y);
        var first = rh + (6 - HebrewCalendar.dayOfWeek(rh));
        var leap = HebrewCalendar.isLeapYear(y);
        var pesachDow = HebrewCalendar.dayOfWeek(HebrewCalendar.toJdn(y, 1, 15));
        var erevPesach = HebrewCalendar.toJdn(y, 1, 14);
        var tishaBav = HebrewCalendar.toJdn(y, 5, 9);
        var nextRhDow = HebrewCalendar.dayOfWeek(HebrewCalendar.newYear(y + 1));
        var end = HebrewCalendar.newYear(y + 1);
        var pesach = HebrewCalendar.toJdn(y, 1, 15);
        var shavuot = HebrewCalendar.toJdn(y, 3, 6);

        // Reading order: Vayelech, Haazinu, then Bereshit ... Vayelech.
        var pos = (HebrewCalendar.dayOfWeek(rh) > 3) ? 1 : 0;
        var table = [];
        for (var s = first; s < end; s += 7) {
            if (parashaless(s - rh, s - pesach, s - shavuot, israel) || pos > 53) {
                table.add(null);
                continue;
            }
            var p = at(pos);
            pos++;
            var entry = [p];
            if ((p == VAYAKHEL && floorDiv7(erevPesach - s) < 3)
                || ((p == TAZRIA || p == ACHAREI_MOT) && !leap)
                || (p == BEHAR && !leap && (!israel || pesachDow != 6))
                || (p == CHUKAT && !israel && pesachDow == 4)
                || (p == MATOT && floorDiv7(tishaBav - s) < 2)
                || (p == NITZAVIM && nextRhDow > 3)) {
                entry.add(at(pos));
                pos++;
            }
            table.add(entry);
        }
        mYear = y;
        mIsrael = israel;
        mFirst = first;
        mTable = table;
    }

    function at(pos) {
        if (pos == 0) { return 51; }
        if (pos == 1) { return 52; }
        return pos - 2;
    }

    function floorDiv7(x) {
        return (x >= 0) ? x / 7 : -((-x + 6) / 7);
    }

    // Shabbatot that are festivals (or Chol HaMoed) have no weekly parasha. Arguments are
    // day offsets from 1 Tishrei, 15 Nisan and 6 Sivan: Rosh Hashana (0, 1), Yom Kippur (9),
    // Sukkot-Simchat Torah (14-22), Pesach (0-7) and Shavuot (0, 1); the last day of each
    // is a weekday in Israel.
    function parashaless(fromRh, fromPesach, fromShavuot, israel) {
        if (fromRh == 0 || fromRh == 1 || fromRh == 9 || (fromRh >= 14 && fromRh <= (israel ? 21 : 22))) {
            return true;
        }
        if (fromPesach >= 0 && fromPesach <= (israel ? 6 : 7)) {
            return true;
        }
        return fromShavuot == 0 || (fromShavuot == 1 && !israel);
    }
}
