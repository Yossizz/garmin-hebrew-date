using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Clock and location used by the app. Normal builds use the real ones; the Shabbat
// demo build (./build.sh demo) pretends it is the coming Friday 15:00 in Tel Aviv so
// candle lighting / havdalah can be checked in the simulator.
(:noDemo, :glance)
module Demo {
    function now() {
        return Time.now();
    }

    function location() {
        return null;
    }
}

(:shabbatDemo, :glance)
module Demo {
    var mStart = null;

    // Coming Friday at 15:00 local, then running in real time from app start.
    function now() {
        if (mStart == null) {
            mStart = Time.now().value();
        }
        var today = Time.today();
        var dow = Gregorian.info(today, Time.FORMAT_SHORT).day_of_week;   // 1 = Sunday
        var friday = today.value() + ((6 - dow + 7) % 7) * 86400 + 15 * 3600;
        return new Time.Moment(friday + (Time.now().value() - mStart));
    }

    function location() {
        return [32.0853, 34.7818];   // Tel Aviv
    }
}
