using Toybox.Position;
using Toybox.Sensor;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;

module Compass {
    
    // Jerusalem coordinates (Temple Mount / Old City)
    const JERUSALEM_LAT = 31.7781;
    const JERUSALEM_LON = 35.2360;
    const JERUSALEM_RADIUS_KM = 10.0;  // 10km radius to consider location as Jerusalem
    
    // Get current GPS location with quality information
    // Returns: {lat, lon, accuracy, quality} or null if unavailable
    function getCurrentLocation() {
        try {
            var info = Position.getInfo();
            
            if (info == null) {
                return null;
            }
            
            // Always return info about GPS state, even if no position yet
            var result = {
                "lat" => null,
                "lon" => null,
                "accuracy" => info.accuracy,
                "quality" => getGpsQuality(info.accuracy)
            };
            
            if (info.position == null) {
                return result;
            }
            
            var position = info.position;
            var coords = position.toDegrees();
            
            if (coords == null || coords.size() < 2) {
                return result;
            }
            
            result["lat"] = coords[0];
            result["lon"] = coords[1];
            
            return result;
        } catch (ex) {
            return null;
        }
    }
    
    // Convert GPS accuracy to quality percentage (0-100)
    // Returns: 0 (no signal) to 100 (excellent signal)
    function getGpsQuality(accuracy) {
        if (accuracy == null) {
            return 0;
        }
        
        // Position.QUALITY constants:
        // NOT_AVAILABLE = 0, LAST_KNOWN = 1, POOR = 2, USABLE = 3, GOOD = 4
        if (accuracy == Position.QUALITY_NOT_AVAILABLE) {
            return 0;
        } else if (accuracy == Position.QUALITY_LAST_KNOWN) {
            return 25;
        } else if (accuracy == Position.QUALITY_POOR) {
            return 50;
        } else if (accuracy == Position.QUALITY_USABLE) {
            return 75;
        } else if (accuracy == Position.QUALITY_GOOD) {
            return 100;
        }
        
        return 0;
    }
    
    // Check if GPS is available
    function isGpsAvailable() {
        var info = Position.getInfo();
        return (info != null && info.position != null && info.accuracy != Position.QUALITY_NOT_AVAILABLE);
    }
    
    // Calculate bearing from point 1 to point 2
    // Returns bearing in degrees (0-360, where 0 = North)
    function calculateBearing(lat1, lon1, lat2, lon2) {
        try {
            if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
                return null;
            }
            
            // Convert to radians
            var lat1Rad = Math.toRadians(lat1);
            var lat2Rad = Math.toRadians(lat2);
            var lon1Rad = Math.toRadians(lon1);
            var lon2Rad = Math.toRadians(lon2);
            
            var dLon = lon2Rad - lon1Rad;
            
            // Calculate bearing using atan2
            var y = Math.sin(dLon) * Math.cos(lat2Rad);
            var x = Math.cos(lat1Rad) * Math.sin(lat2Rad) - 
                    Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);
            
            var bearing = Math.atan2(y, x);
            
            // Convert to degrees and normalize to 0-360
            bearing = Math.toDegrees(bearing);
            bearing = (bearing.toNumber() + 360) % 360;
            
            return bearing.toDouble();
        } catch (ex) {
            return null;
        }
    }
    
    // Calculate bearing from current location to Jerusalem
    // Returns: bearing in degrees (0-360) or null if GPS unavailable
    function getBearingToJerusalem(currentLat, currentLon) {
        if (currentLat == null || currentLon == null) {
            return null;
        }
        
        return calculateBearing(currentLat, currentLon, JERUSALEM_LAT, JERUSALEM_LON);
    }
    
    // Get compass heading from watch's magnetometer
    // Returns: heading in degrees (0-360, where 0 = North) or null if unavailable
    function getCompassHeading() {
        try {
            var info = Sensor.getInfo();
            
            if (info == null) {
                return null;
            }
            
            // Try direct heading first
            if (info has :heading && info.heading != null) {
                // heading is in radians, convert to degrees
                var headingDegrees = Math.toDegrees(info.heading);
                headingDegrees = (headingDegrees.toNumber() + 360) % 360;
                return headingDegrees.toDouble();
            }
            
            // Try magnetometer data
            if (info has :magX && info has :magY) {
                var magX = info.magX;
                var magY = info.magY;
                
                if (magX != null && magY != null) {
                    // Calculate heading from magnetometer
                    var heading = Math.atan2(magY, magX);
                    heading = Math.toDegrees(heading);
                    heading = (heading.toNumber() + 360) % 360;
                    return heading.toDouble();
                }
            }
            
            return null;
        } catch (ex) {
            return null;
        }
    }
    
    // Calculate arrow angle for drawing
    // Returns: angle in degrees (0-360) where arrow should point
    // Formula: bearing_to_jerusalem - compass_heading
    function calculateArrowAngle(bearingToJerusalem, compassHeading) {
        if (bearingToJerusalem == null || compassHeading == null) {
            return null;
        }
        
        // Calculate relative angle
        var angle = bearingToJerusalem - compassHeading;
        
        // Normalize to 0-360
        angle = (angle.toNumber() + 360) % 360;
        
        return angle.toDouble();
    }
    
    // Calculate distance between two points using Haversine formula
    // Returns: distance in kilometers
    function calculateDistance(lat1, lon1, lat2, lon2) {
        var R = 6371.0; // Earth radius in kilometers
        
        var lat1Rad = Math.toRadians(lat1);
        var lat2Rad = Math.toRadians(lat2);
        var dLat = Math.toRadians(lat2 - lat1);
        var dLon = Math.toRadians(lon2 - lon1);
        
        var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        
        return R * c;
    }
    
    // Check if location is within Jerusalem
    // Returns: true if within JERUSALEM_RADIUS_KM of Jerusalem center
    function isInJerusalem(lat, lon) {
        if (lat == null || lon == null) {
            return false;
        }
        
        var distance = calculateDistance(lat, lon, JERUSALEM_LAT, JERUSALEM_LON);
        return distance < JERUSALEM_RADIUS_KM;
    }
    
    // Calculate sunset time for given date and location
    // Returns: Time.Moment for sunset, or null if calculation fails
    // Float modulo: Monkey C % only works on integers
    function fmod(a, b) {
        return a - (b * (a / b).toNumber().toFloat());
    }

    // Generic sun event calculator — horizon_deg controls which event:
    //   -0.833 = visible sunset (refraction + solar disk)
    //   -8.5   = nightfall / tzet hakochavim
    function calculateSunEvent(lat, lon, year, month, day, horizon_deg) {
        try {
            System.println("SUNSET: lat=" + lat + " lon=" + lon + " " + year + "-" + month + "-" + day);

            // Days since J2000.0 as integer (avoids large float precision loss)
            var a = (14 - month) / 12;
            var y = year + 4800 - a;
            var m = month + 12 * a - 3;
            var jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
            var n = (jdn - 2451545).toDouble(); // ~9652 for 2026 — small enough for float32

            System.println("SUNSET: n=" + n);

            var J_star = n - (lon / 360.0);

            var M = fmod(357.5291 + 0.98560028 * J_star, 360.0);
            var M_rad = Math.toRadians(M);

            var C = 1.9148 * Math.sin(M_rad) + 0.02 * Math.sin(2.0 * M_rad) + 0.0003 * Math.sin(3.0 * M_rad);

            var lambda = fmod(M + C + 180.0 + 102.9372, 360.0);
            var lambda_rad = Math.toRadians(lambda);

            var J_transit_offset = J_star + 0.0053 * Math.sin(M_rad) - 0.0069 * Math.sin(2.0 * lambda_rad);

            var sin_delta = Math.sin(lambda_rad) * Math.sin(Math.toRadians(23.44));
            var cos_delta = Math.cos(Math.asin(sin_delta));

            var lat_rad = Math.toRadians(lat);
            var cos_omega = (Math.sin(Math.toRadians(horizon_deg)) - Math.sin(lat_rad) * sin_delta) /
                            (Math.cos(lat_rad) * cos_delta);

            System.println("SUNSET: cos_omega=" + cos_omega);

            if (cos_omega > 1.0 || cos_omega < -1.0) {
                System.println("SUNSET: No sunset (polar region)");
                return null;
            }

            var omega = Math.toDegrees(Math.acos(cos_omega));

            var J_set_offset = J_transit_offset + (omega / 360.0);

            // J2000.0 = Jan 1, 2000 12:00:00 UTC = Unix 946728000
            var unix_time = 946728000 + (J_set_offset * 86400.0).toLong();

            System.println("SUNSET: unix_time=" + unix_time);

            var moment = new Time.Moment(unix_time);
            System.println("SUNSET: Created moment=" + moment);
            return moment;

        } catch (ex) {
            System.println("SUNSET: Exception=" + ex);
            return null;
        }
    }
    
    // Sunset wrapper (visible horizon, refraction corrected)
    function calculateSunset(lat, lon, year, month, day) {
        return calculateSunEvent(lat, lon, year, month, day, -0.833);
    }

    // Nightfall wrapper (tzet hakochavim: sun at -8.5° below horizon, ~42 min after sunset)
    function calculateNightfall(lat, lon, year, month, day) {
        return calculateSunEvent(lat, lon, year, month, day, -8.5);
    }

    // Candle lighting: Friday sunset - 35 min (Jerusalem) or - 18 min elsewhere
    function calculateShabbatStart(lat, lon, year, month, day) {
        var sunset = calculateSunset(lat, lon, year, month, day);
        if (sunset == null) {
            return null;
        }
        var offsetMinutes = isInJerusalem(lat, lon) ? 35 : 18;
        return sunset.subtract(new Time.Duration(offsetMinutes * 60));
    }

    // Havdalah: Saturday sunset + 40 min (Israeli standard / Gra opinion)
    function calculateShabbatEnd(lat, lon, year, month, day) {
        var sunset = calculateSunset(lat, lon, year, month, day + 1);
        if (sunset == null) {
            return null;
        }
        return sunset.add(new Time.Duration(40 * 60));
    }

    // Hallel type for a given Hebrew date.
    // hMonth numbering (as returned by HebrewCalendar.gregorianToHebrew):
    //   non-leap: 1=Tishrei…6=Adar, 7=Nisan, 8=Iyar, 9=Sivan, 10=Tammuz, 11=Av, 12=Elul
    //   leap:     1=Tishrei…6=Adar I, 7=Adar II, 8=Nisan, 9=Iyar, 10=Sivan, 11=Tammuz, 12=Av, 13=Elul
    // Returns: 0=no Hallel, 1=full Hallel (הלל שלם), 2=half Hallel (חצי הלל)
    function getHallelType(hYear, hMonth, hDay, isLeap) {
        var NISAN  = isLeap ? 8  : 7;
        var IYAR   = isLeap ? 9  : 8;
        var SIVAN  = isLeap ? 10 : 9;
        var AV     = isLeap ? 12 : 11;

        // --- Full Hallel ---
        // Sukkot (15–21 Tishrei) + Shemini Atzeret (22 Tishrei)
        if (hMonth == 1 && hDay >= 15 && hDay <= 22) { return 1; }

        // Chanukah: 25 Kislev onward, plus Tevet 1–2 always, Tevet 3 if Kislev=29
        if (hMonth == 3 && hDay >= 25) { return 1; }
        if (hMonth == 4 && hDay <= 3) {
            if (hDay <= 2) { return 1; }
            var mlen = HebrewCalendar.getMonthLengths(hYear);
            if (mlen[2] == 29) { return 1; } // Kislev defective → day 8 falls on 3 Tevet
        }

        // Passover day 1 (Israel minhag: only 15 Nisan is full Hallel)
        if (hMonth == NISAN && hDay == 15) { return 1; }

        // Shavuot (6 Sivan)
        if (hMonth == SIVAN && hDay == 6) { return 1; }

        // Yom Ha'atzmaut (5 Iyar, simplified — no calendar-shift logic)
        if (hMonth == IYAR && hDay == 5) { return 1; }

        // Yom Yerushalayim (28 Iyar)
        if (hMonth == IYAR && hDay == 28) { return 1; }

        // --- Half Hallel ---
        // Remaining Passover days (16–21 Nisan, Israel minhag)
        if (hMonth == NISAN && hDay >= 16 && hDay <= 21) { return 2; }

        // Rosh Chodesh: day 1 of any month except Tishrei (= Rosh Hashana, no Hallel)
        if (hDay == 1 && hMonth != 1) { return 2; }

        // Rosh Chodesh: day 30 of months that are always full (30 days)
        if (hDay == 30) {
            // Tishrei always 30 → 30 Tishrei = Rosh Chodesh Cheshvan
            if (hMonth == 1) { return 2; }
            // Shevat always 30 → 30 Shevat = Rosh Chodesh Adar
            if (hMonth == 5) { return 2; }
            // Nisan always 30 → 30 Nisan = Rosh Chodesh Iyar
            if (hMonth == NISAN) { return 2; }
            // Sivan always 30 → 30 Sivan = Rosh Chodesh Tammuz
            if (hMonth == SIVAN) { return 2; }
            // Av always 30 → 30 Av = Rosh Chodesh Elul
            if (hMonth == AV) { return 2; }
            // Adar I in leap year (always 30) → 30 Adar I = Rosh Chodesh Adar II
            if (isLeap && hMonth == 6) { return 2; }
            // Cheshvan: 30 only in shalem year
            if (hMonth == 2) {
                var mlen2 = HebrewCalendar.getMonthLengths(hYear);
                if (mlen2[1] == 30) { return 2; }
            }
            // Note: 30 Kislev = Rosh Chodesh Tevet but also Chanukah day 6 → full Hallel (handled above)
        }

        return 0;
    }
}
