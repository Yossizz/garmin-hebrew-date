using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;

// Sunset / nightfall via the USNO sunrise equation (moved here from Compass so the
// glance can use it). Dates are Julian Day Numbers; results are Time.Moment or null
// (polar day / night).
(:glance)
module SunTimes {

    const JERUSALEM_LAT = 31.7781;
    const JERUSALEM_LON = 35.2360;

    // Float modulo: Monkey C % only works on integers
    function fmod(a, b) {
        return a - (b * (a / b).toNumber().toFloat());
    }

    // horizonDeg: -0.833 = visible sunset (refraction + solar disk), -8.5 = nightfall.
    function sunEvent(lat, lon, jdn, horizonDeg) {
        var n = (jdn - 2451545).toDouble();    // days since J2000, small enough for float math
        var jStar = n - (lon / 360.0);
        var mDeg = fmod(357.5291 + 0.98560028 * jStar, 360.0);
        var mRad = Math.toRadians(mDeg);
        var c = 1.9148 * Math.sin(mRad) + 0.02 * Math.sin(2.0 * mRad) + 0.0003 * Math.sin(3.0 * mRad);
        var lambdaRad = Math.toRadians(fmod(mDeg + c + 180.0 + 102.9372, 360.0));
        var transit = jStar + 0.0053 * Math.sin(mRad) - 0.0069 * Math.sin(2.0 * lambdaRad);
        var sinDelta = Math.sin(lambdaRad) * Math.sin(Math.toRadians(23.44));
        var cosDelta = Math.cos(Math.asin(sinDelta));
        var latRad = Math.toRadians(lat);
        var cosOmega = (Math.sin(Math.toRadians(horizonDeg)) - Math.sin(latRad) * sinDelta)
                       / (Math.cos(latRad) * cosDelta);
        if (cosOmega > 1.0 || cosOmega < -1.0) {
            return null;
        }
        var setOffset = transit + Math.toDegrees(Math.acos(cosOmega)) / 360.0;
        // J2000.0 = 2000-01-01 12:00 UTC = Unix 946728000
        return new Time.Moment(946728000 + (setOffset * 86400.0).toLong());
    }

    function sunset(lat, lon, jdn) {
        return sunEvent(lat, lon, jdn, -0.833);
    }

    function isInJerusalem(lat, lon) {
        var dLat = lat - JERUSALEM_LAT;
        var dLon = (lon - JERUSALEM_LON) * 0.85;     // cos(31.8 deg)
        return (dLat * dLat + dLon * dLon) * 111.2 * 111.2 < 100.0;   // within ~10 km
    }

    // Candle lighting: sunset - 35 min in Jerusalem, - 18 min elsewhere.
    function candleLighting(lat, lon, jdn) {
        var s = sunset(lat, lon, jdn);
        if (s == null) {
            return null;
        }
        return s.subtract(new Time.Duration((isInJerusalem(lat, lon) ? 35 : 18) * 60));
    }

    // Havdalah: sunset + 40 min (Israeli standard).
    function havdalah(lat, lon, jdn) {
        var s = sunset(lat, lon, jdn);
        if (s == null) {
            return null;
        }
        return s.add(new Time.Duration(40 * 60));
    }
}
