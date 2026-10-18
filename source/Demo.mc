using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Clock and location used by the app. Normal builds use the real ones; the demo build
// (./build.sh demo) pretends to be in Tel Aviv on the coming Friday 15:00, or on
// DEMO_DATE [DEMO_TIME], so Shabbat times, holidays and Hallel can be checked in the simulator.
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

    // DemoConfig.START (set from DEMO_DATE / DEMO_TIME by ./build.sh demo), or the
    // coming Friday at 15:00 when it is 0; then running in real time from app start.
    function now() {
        if (mStart == null) {
            mStart = Time.now().value();
        }
        var target = DemoConfig.START;
        if (target == 0) {
            var today = Time.today();
            var dow = Gregorian.info(today, Time.FORMAT_SHORT).day_of_week;   // 1 = Sunday
            target = today.value() + ((6 - dow + 7) % 7) * 86400 + 15 * 3600;
        }
        return new Time.Moment(target + (Time.now().value() - mStart));
    }

    function location() {
        return [32.0853, 34.7818];   // Tel Aviv
    }
}
