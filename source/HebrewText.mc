using Toybox.Lang;

// Hebrew strings: numerals, month / day / parasha names.
(:glance)
module HebrewText {

    const ONES = ["", "א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט"];
    const TENS = ["", "י", "כ", "ל", "מ", "נ", "ס", "ע", "פ", "צ"];
    const HUNDREDS = ["", "ק", "ר", "ש"];

    // Indexed by biblical month number (1 = Nisan); 0 unused.
    const MONTHS = ["", "ניסן", "אייר", "סיון", "תמוז", "אב", "אלול",
                    "תשרי", "חשוון", "כסלו", "טבת", "שבט", "אדר", "אדר ב׳"];

    const DAYS = ["ראשון", "שני", "שלישי", "רביעי", "חמישי", "שישי", "שבת"];

    const PARSHIOS = [
        "בראשית", "נח", "לך לך", "וירא", "חיי שרה", "תולדות", "ויצא", "וישלח",
        "וישב", "מקץ", "ויגש", "ויחי", "שמות", "וארא", "בא", "בשלח", "יתרו",
        "משפטים", "תרומה", "תצוה", "כי תשא", "ויקהל", "פקודי", "ויקרא", "צו",
        "שמיני", "תזריע", "מצורע", "אחרי מות", "קדושים", "אמור", "בהר", "בחוקותי",
        "במדבר", "נשא", "בהעלותך", "שלח", "קרח", "חקת", "בלק", "פינחס", "מטות",
        "מסעי", "דברים", "ואתחנן", "עקב", "ראה", "שופטים", "כי תצא", "כי תבוא",
        "נצבים", "וילך", "האזינו", "וזאת הברכה"
    ];

    // Hebrew numeral with geresh / gershayim: 7 -> ז׳, 15 -> ט״ו, 5787 -> תשפ״ז.
    function numeral(n) {
        var s = "";
        var h = (n % 1000) / 100;
        while (h >= 4) {
            s += "ת";
            h -= 4;
        }
        s += HUNDREDS[h];
        var r = n % 100;
        if (r == 15) {
            s += "טו";
        } else if (r == 16) {
            s += "טז";
        } else {
            s += TENS[r / 10] + ONES[r % 10];
        }
        var len = s.length();
        if (len == 1) {
            return s + "׳";
        }
        return s.substring(0, len - 1) + "״" + s.substring(len - 1, len);
    }

    function monthName(y, m) {
        if (m == 12 && HebrewCalendar.isLeapYear(y)) {
            return "אדר א׳";
        }
        return MONTHS[m];
    }

    function dayName(dow) {
        return DAYS[dow];
    }

    // "ז׳ חשוון"
    function date(y, m, d) {
        return numeral(d) + " " + monthName(y, m);
    }

    // "פרשת ויקהל-פקודי"; null when the Shabbat has no weekly parasha.
    function parasha(indices) {
        if (indices == null) {
            return null;
        }
        var s = "פרשת " + PARSHIOS[indices[0]];
        if (indices.size() > 1) {
            s += "-" + PARSHIOS[indices[1]];
        }
        return s;
    }
}
