using Toybox.Application.Properties;
using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.Time;

// Everything the glance and widget show for "now", including the switch to the
// next Hebrew date at local sunset.
(:glance)
module Today {

    function prop(key, dflt) {
        try {
            var v = Properties.getValue(key);
            if (v != null) {
                return v;
            }
        } catch (e) {
        }
        return dflt;
    }

    function israel() {
        return prop("Israel", true);
    }

    // Last known [lat, lon], saved by the widget when it gets a GPS position.
    function savedLocation() {
        return Storage.getValue("loc");
    }

    function compute(now, loc) {
        var isr = israel();
        var civil = HebrewCalendar.civilJdn(now);
        var sunset = (loc == null) ? null : SunTimes.sunset(loc[0], loc[1], civil);
        var after = prop("SunsetSwitch", true) && sunset != null && now.value() >= sunset.value();
        var jdn = after ? civil + 1 : civil;
        var h = HebrewCalendar.fromJdn(jdn);
        var dow = HebrewCalendar.dayOfWeek(jdn);
        return {
            "jdn" => jdn,
            "civil" => civil,
            "y" => h[0],
            "m" => h[1],
            "d" => h[2],
            "dow" => dow,
            "after" => after,
            "sunset" => sunset,
            "israel" => isr,
            "events" => Holidays.forDay(h[0], h[1], h[2], jdn, isr),
            "omer" => Holidays.omer(h[0], jdn),
            "hallel" => Holidays.hallel(h[0], h[1], h[2], jdn, isr),
            "parasha" => HebrewText.parasha(Parasha.forShabbat(jdn + 6 - dow, isr))
        };
    }

    // "יום שני" by day, "ליל שבת" after sunset.
    function dayLabel(t) {
        return (t["after"] ? "ליל " : "יום ") + HebrewText.dayName(t["dow"]);
    }

    // Extra lines below the date: observances, Omer, Hallel, then the parasha.
    function infoLines(t) {
        var lines = [];
        var events = t["events"];
        for (var i = 0; i < events.size(); i++) {
            lines.add(events[i]);
        }
        if (t["omer"] > 0) {
            lines.add(HebrewText.numeral(t["omer"]) + " לעומר");
        }
        if (t["hallel"] == 1) {
            lines.add("הלל");
        } else if (t["hallel"] == 2) {
            lines.add("חצי הלל");
        }
        if (t["parasha"] != null) {
            lines.add(t["parasha"]);
        }
        return lines;
    }
}
