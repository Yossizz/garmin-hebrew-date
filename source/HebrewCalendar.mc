using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

module HebrewCalendar {
    
    // Hebrew month names mapped to ASCII for display
    const MONTH_NAMES = [
        "yrwa",     // תשרי - Tishrei (1)
        "nvwx",     // חשוון - Cheshvan (2)
        "vlok",     // כסלו - Kislev (3)
        "fbj",      // טבת - Tevet (4)
        "fbw",      // שבט - Shevat (5)
        "rda a",    // אדר א' - Adar I (6, only in leap year)
        "rda b",    // אדר ב' - Adar II (7, in leap year) / Adar (6, in regular year)
        "noyn",     // ניסן - Nisan (8/7)
        "ryya",     // אייר - Iyar (9/8)
        "nvyo",     // סיון - Sivan (10/9)
        "zvmt",     // תמוז - Tammuz (11/10)
        "ba",       // אב - Av (12/11)
        "lvla"      // אלול - Elul (13/12)
    ];
    
    // Check if Hebrew year is a leap year (13 months)
    function isHebrewLeapYear(year) {
        return ((7 * year + 1) % 19) < 7;
    }
    
    // Simple Hebrew date conversion using known algorithm
    // Based on the work of Gauss and others
    function gregorianToHebrew(gYear, gMonth, gDay) {
        // Days since epoch calculation
        var a = (14 - gMonth) / 12;
        var y = gYear + 4800 - a;
        var m = gMonth + 12 * a - 3;
        var jdn = gDay + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
        
        // Hebrew epoch is September 7, 3761 BCE (Julian) = -1373428 days from JDN epoch
        // But we need to calculate from Jewish epoch
        var daysFromEpoch = jdn - 347997;
        
        // Estimate Hebrew year (approximate)
        var hYear = ((daysFromEpoch * 98496.0) / 35975351.0).toNumber() + 1;
        
        // Adjust year by checking if we're past Tishrei 1
        while (hebrewNewYear(hYear) <= daysFromEpoch) {
            hYear++;
        }
        hYear--;
        
        // Calculate month and day
        var dayOfYear = daysFromEpoch - hebrewNewYear(hYear) + 1;
        var hMonth = 1;
        var hDay = dayOfYear;
        
        // Find the month
        var isLeap = isHebrewLeapYear(hYear);
        var monthLengths = getMonthLengths(hYear);
        
        for (var i = 0; i < 13; i++) {
            if (i >= 12 && !isLeap) {
                break;
            }
            if (hDay <= monthLengths[i]) {
                hMonth = i + 1;
                break;
            }
            hDay -= monthLengths[i];
        }
        
        return {
            "year" => hYear,
            "month" => hMonth,
            "day" => hDay
        };
    }
    
    // Calculate days from Hebrew epoch to Rosh Hashanah (Tishrei 1) of given year
    function hebrewNewYear(year) {
        // Simplified Gauss formula for Hebrew calendar
        // This is an approximation that works well for modern dates
        var monthsElapsed = (235 * ((year - 1) / 19)).toNumber() + 
                           (12 * ((year - 1) % 19)) + 
                           (((year - 1) % 19 * 7 + 1) / 19).toNumber();
        
        var partsElapsed = 204 + 793 * (monthsElapsed % 1080);
        var hoursElapsed = 5 + 12 * monthsElapsed + 793 * (monthsElapsed / 1080).toNumber() + 
                          (partsElapsed / 1080).toNumber();
        
        var day = 1 + 29 * monthsElapsed + (hoursElapsed / 24).toNumber();
        
        // Apply dehiyyot (postponement rules) - simplified
        var dayOfWeek = (day % 7);
        
        // Dehiyyah: Rosh Hashanah cannot fall on Sunday, Wednesday, or Friday
        if (dayOfWeek == 0 || dayOfWeek == 3 || dayOfWeek == 5) {
            day++;
        }
        
        return day;
    }
    
    // Get month lengths for a Hebrew year
    function getMonthLengths(year) {
        var isLeap = isHebrewLeapYear(year);
        var yearLength = hebrewNewYear(year + 1) - hebrewNewYear(year);
        
        // Determine if year is deficient, regular, or complete
        var expectedBase = isLeap ? 383 : 353;
        var yearType = yearLength - expectedBase; // -1=deficient, 0=regular, 1=complete
        
        var lengths = [];
        lengths.add(30); // Tishrei
        lengths.add(yearType >= 0 ? 30 : 29); // Cheshvan (variable)
        lengths.add(yearType > 0 ? 30 : 29);  // Kislev (variable)
        lengths.add(29); // Tevet
        lengths.add(30); // Shevat
        
        if (isLeap) {
            lengths.add(30); // Adar I
            lengths.add(29); // Adar II
        } else {
            lengths.add(29); // Adar
        }
        
        lengths.add(30); // Nisan
        lengths.add(29); // Iyar
        lengths.add(30); // Sivan
        lengths.add(29); // Tammuz
        lengths.add(30); // Av
        lengths.add(29); // Elul
        
        return lengths;
    }
    
    // Get Hebrew month name
    function getHebrewMonthName(month, isLeapYear) {
        if (month < 1 || month > 13) {
            return "";
        }
        
        // In a regular year, skip Adar I
        if (!isLeapYear && month >= 6) {
            if (month == 6) {
                return MONTH_NAMES[6]; // Just "Adar" (Adar II slot)
            }
            return MONTH_NAMES[month]; // Offset by 1 for remaining months
        }
        
        return MONTH_NAMES[month - 1];
    }
    
    // Format Hebrew day with Hebrew numerals
    function formatHebrewDay(day) {
        if (day < 1 || day > 30) {
            return "";
        }
        
        // Hebrew letter values
        // א=1, ב=2, ג=3, ד=4, ה=5, ו=6, ז=7, ח=8, ט=9
        // י=10, כ=20, ל=30
        var ones = ["", "a", "b", "g", "d", "h", "v", "z", "x", "j"];
        var tens = ["", "y", "k", "l"];
        
        var result = "";
        
        if (day <= 10) {
            result = ones[day];
        } else if (day == 15 || day == 16) {
            // Special cases: 15=ט״ו (9+6), 16=ט״ז (9+7)
            // To avoid writing God's name (יה)
            if (day == 15) {
                result = "jv"; // ט״ו
            } else {
                result = "jz"; // ט״ז
            }
        } else if (day < 20) {
            result = "y" + ones[day - 10]; // 10 + ones
        } else {
            var tensDigit = day / 10;
            var onesDigit = day % 10;
            result = tens[tensDigit];
            if (onesDigit > 0) {
                result = result + ones[onesDigit];
            }
        }
        
        // Add gershayim (") before last character, or geresh (') for single character
        if (result.length() == 1) {
            result = result + "'";
        } else if (result.length() > 1) {
            var lastChar = result.substring(result.length() - 1, result.length());
            var rest = result.substring(0, result.length() - 1);
            result = rest + "\"" + lastChar;
        }
        
        return result;
    }
}
