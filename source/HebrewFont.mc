using Toybox.Lang;

module HebrewFont {
    
    // Hebrew to ASCII character mapping
    // This maps Hebrew Unicode characters to ASCII characters that will be
    // displayed using a custom Hebrew font
    const HEBREW_MAP = {
        // Hebrew letters
        "א" => "a",  // Alef
        "ב" => "b",  // Bet
        "ג" => "g",  // Gimel
        "ד" => "d",  // Dalet
        "ה" => "h",  // He
        "ו" => "v",  // Vav
        "ז" => "z",  // Zayin
        "ח" => "x",  // Het
        "ט" => "j",  // Tet
        "י" => "y",  // Yod
        "כ" => "k",  // Kaf
        "ך" => "K",  // Kaf sofit
        "ל" => "l",  // Lamed
        "מ" => "m",  // Mem
        "ם" => "M",  // Mem sofit
        "נ" => "n",  // Nun
        "ן" => "N",  // Nun sofit
        "ס" => "o",  // Samekh
        "ע" => "c",  // Ayin
        "פ" => "p",  // Pe
        "ף" => "P",  // Pe sofit
        "צ" => "q",  // Tsadi
        "ץ" => "Q",  // Tsadi sofit
        "ק" => "w",  // Qof
        "ר" => "r",  // Resh
        "ש" => "s",  // Shin
        "ת" => "t",  // Tav
        
        // Special characters
        "'" => "'",  // Geresh
        "\"" => "\"", // Gershayim
        "/" => "/",  // Slash
        " " => " "   // Space
    };
    
    // Reverse string for RTL display
    // Hebrew text needs to be displayed right-to-left
    function reverseString(str) {
        if (str == null || str.length() == 0) {
            return "";
        }
        
        var reversed = "";
        for (var i = str.length() - 1; i >= 0; i--) {
            reversed += str.substring(i, i + 1);
        }
        return reversed;
    }
    
    // Convert Hebrew Unicode string to ASCII mapping
    function hebrewToAscii(hebrewStr) {
        if (hebrewStr == null || hebrewStr.length() == 0) {
            return "";
        }
        
        var result = "";
        for (var i = 0; i < hebrewStr.length(); i++) {
            var char = hebrewStr.substring(i, i + 1);
            if (HEBREW_MAP.hasKey(char)) {
                result += HEBREW_MAP[char];
            } else {
                // If character not in map, keep it as is
                result += char;
            }
        }
        return result;
    }
    
    // Prepare Hebrew text for display
    // Converts to ASCII mapping and reverses for RTL
    function prepareHebrewText(hebrewStr) {
        var ascii = hebrewToAscii(hebrewStr);
        return reverseString(ascii);
    }
    
    // Format Hebrew date string in short format
    // Note: day and month are already in ASCII-mapped format from HebrewCalendar
    function formatShortDate(day, month) {
        // Simple format without reversal for now: day/month
        // The Hebrew font should handle RTL display
        return day + "/" + month;
    }
    
    // Convert ASCII-mapped Hebrew back to actual Hebrew Unicode
    function asciiToHebrew(asciiStr) {
        if (asciiStr == null || asciiStr.length() == 0) {
            return "";
        }
        
        // Reverse mapping: ASCII -> Hebrew
        var reverseMap = {
            "a" => "א", "b" => "ב", "g" => "ג", "d" => "ד", "h" => "ה",
            "v" => "ו", "z" => "ז", "x" => "ח", "j" => "ט", "y" => "י",
            "k" => "כ", "K" => "ך", "l" => "ל", "m" => "מ", "M" => "ם",
            "n" => "נ", "N" => "ן", "o" => "ס", "c" => "ע", "p" => "פ",
            "P" => "ף", "q" => "צ", "Q" => "ץ", "w" => "ק", "r" => "ר",
            "s" => "ש", "t" => "ת",
            "'" => "׳", "\"" => "״", "/" => "/", " " => " "
        };
        
        var result = "";
        for (var i = 0; i < asciiStr.length(); i++) {
            var char = asciiStr.substring(i, i + 1);
            if (reverseMap.hasKey(char)) {
                result += reverseMap[char];
            } else {
                result += char;
            }
        }
        return result;
    }
}
