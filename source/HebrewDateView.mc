using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Position;
using Toybox.Attention;
using Toybox.Sensor;

class HebrewDateView extends WatchUi.View {

    hidden var mHebrewDateString;
    hidden var mDayName;
    hidden var mLastDay;
    
    // GPS and compass variables
    hidden var mCurrentLat;           // Stored GPS latitude (set once at startup)
    hidden var mCurrentLon;           // Stored GPS longitude (set once at startup)
    hidden var mBearingToJerusalem;   // Bearing from stored location to Jerusalem (0-360)
    hidden var mGpsAvailable;         // Boolean: GPS signal status (checked at startup)
    hidden var mGpsQuality;           // GPS quality percentage (0-100)
    hidden var mPreviousGpsQuality;   // Previous GPS quality to detect lock transition
    hidden var mCompassHeading;       // Current compass heading from watch (0-360)
    hidden var mArrowAngle;           // Calculated arrow angle for drawing
    hidden var mGpsInitialized;      // Flag to track if we've tried to get GPS once
    hidden var mSensorListenerActive; // Track if sensor listener is active
    
    // Shabbat times variables
    hidden var mShabbatStartTime;     // Time.Moment for Shabbat start
    hidden var mShabbatEndTime;       // Time.Moment for Shabbat end
    hidden var mIsFriday;             // Boolean: is today Friday?
    hidden var mUsingCachedGps;       // true = times calculated from cached location, not fresh fix
    hidden var mHallelText;           // "הלל" / "חצי הלל" / null
    
    // Test mode - set to true to always show Shabbat times (for testing)
    const TEST_MODE = false;

    function initialize() {
        View.initialize();
        mHebrewDateString = "";
        mDayName = "";
        mLastDay = -1;
        mCurrentLat = null;
        mCurrentLon = null;
        mBearingToJerusalem = null;
        mGpsAvailable = false;
        mGpsQuality = 0;
        mPreviousGpsQuality = 0;
        mCompassHeading = null;
        mArrowAngle = null;
        mGpsInitialized = false;
        mSensorListenerActive = false;
        mShabbatStartTime = null;
        mShabbatEndTime = null;
        mIsFriday = false;
        mUsingCachedGps = false;
        mHallelText = null;
    }
    
    function updateDate() {
        // Get current date
        var now = Time.now();
        var today = Gregorian.info(now, Time.FORMAT_SHORT);
        
        // In TEST_MODE, always pretend it's Friday for testing
        var actualDay = today.day;
        var actualMonth = today.month;
        var actualYear = today.year;
        var actualDayOfWeek = today.day_of_week;
        
        if (TEST_MODE) {
            // Always pretend it's Friday to test Shabbat times
            // Find most recent Friday (or today if already Friday)
            var daysBack = (today.day_of_week == 6) ? 0 : ((today.day_of_week + 1) % 7);
            if (daysBack == 0) {
                // today is Friday, use as-is
            } else {
                var fridayMoment = now.subtract(new Time.Duration(daysBack * 24 * 60 * 60));
                var fridayInfo = Gregorian.info(fridayMoment, Time.FORMAT_SHORT);
                actualDay = fridayInfo.day;
                actualMonth = fridayInfo.month;
                actualYear = fridayInfo.year;
            }
            actualDayOfWeek = 6; // Friday
        }
        
        // Only recalculate if day has changed
        if (actualDay != mLastDay) {
            mLastDay = actualDay;
            
            // Convert to Hebrew date (use actual adjusted date in TEST_MODE)
            var hebrewDate = HebrewCalendar.gregorianToHebrew(
                actualYear,
                actualMonth,
                actualDay
            );
            
            // Hebrew month names in actual Hebrew
            var monthNames = ["תשרי", "חשוון", "כסלו", "טבת", "שבט", 
                            "אדר", "אדר ב", "ניסן", "אייר", "סיון", 
                            "תמוז", "אב", "אלול"];
            
            // Hebrew day names (Sunday = 1)
            var dayNames = ["ראשון", "שני", "שלישי", "רביעי", "חמישי", "שישי", "שבת"];
            
            var monthIndex = hebrewDate["month"] - 1;
            if (monthIndex >= monthNames.size()) {
                monthIndex = monthNames.size() - 1;
            }
            
            // Get day of week (use adjusted day in TEST_MODE)
            mDayName = dayNames[actualDayOfWeek - 1];
            
            // Format Hebrew day with Hebrew numerals
            var hebrewDay = HebrewCalendar.formatHebrewDay(hebrewDate["day"]);
            
            // Convert ASCII-mapped Hebrew back to actual Hebrew
            var hebrewDayText = HebrewFont.asciiToHebrew(hebrewDay);
            
            // Format date
            mHebrewDateString = hebrewDayText + " " + monthNames[monthIndex];

            // Hallel indicator
            var isLeap = HebrewCalendar.isHebrewLeapYear(hebrewDate["year"]);
            var hallelType = Compass.getHallelType(hebrewDate["year"], hebrewDate["month"], hebrewDate["day"], isLeap);
            if (hallelType == 1) {
                mHallelText = "הלל";
            } else if (hallelType == 2) {
                mHallelText = "חצי הלל";
            } else {
                mHallelText = null;
            }

            // Check if today is Friday and calculate Shabbat times if GPS available
            // Use actualDayOfWeek which accounts for TEST_MODE adjustment
            var shouldCalculateShabbat = (actualDayOfWeek == 6) && mGpsAvailable && mCurrentLat != null && mCurrentLon != null;
            
            System.println("DEBUG: shouldCalculateShabbat=" + shouldCalculateShabbat);
            System.println("DEBUG: actualDayOfWeek=" + actualDayOfWeek + " TEST_MODE=" + TEST_MODE);
            System.println("DEBUG: mGpsAvailable=" + mGpsAvailable + " lat=" + mCurrentLat + " lon=" + mCurrentLon);
            System.println("DEBUG: Using date: " + actualYear + "-" + actualMonth + "-" + actualDay);
            
            if (shouldCalculateShabbat) {
                mIsFriday = true;
                System.println("DEBUG: Calculating Shabbat times...");
                mShabbatStartTime = Compass.calculateShabbatStart(mCurrentLat, mCurrentLon, actualYear, actualMonth, actualDay);
                mShabbatEndTime = Compass.calculateShabbatEnd(mCurrentLat, mCurrentLon, actualYear, actualMonth, actualDay);
                System.println("DEBUG: Start=" + mShabbatStartTime + " End=" + mShabbatEndTime);

                // In TEST_MODE, fall back to hardcoded Jerusalem times if calculation fails
                if (TEST_MODE && (mShabbatStartTime == null || mShabbatEndTime == null)) {
                    System.println("DEBUG: Sunset calc failed, using hardcoded Jerusalem test times");
                    // ~19:15 candle lighting, ~20:30 havdalah (typical Jerusalem summer)
                    var baseNow = Time.now();
                    var todayMidnight = baseNow.subtract(new Time.Duration(baseNow.value() % 86400));
                    if (mShabbatStartTime == null) {
                        mShabbatStartTime = todayMidnight.add(new Time.Duration(16 * 3600 + 15 * 60)); // 19:15 Jerusalem = 16:15 UTC
                    }
                    if (mShabbatEndTime == null) {
                        mShabbatEndTime = todayMidnight.add(new Time.Duration(17 * 3600 + 30 * 60 + 86400)); // 20:30 Jerusalem next day = 17:30 UTC+1day
                    }
                }
            } else {
                mIsFriday = false;
                mShabbatStartTime = null;
                mShabbatEndTime = null;
            }
        } else {
            return; // Day hasn't changed, skip recalculation
        }
        
        WatchUi.requestUpdate();
    }

    function onLayout(dc) {
        // No layout needed
    }
    
    // Format Time.Moment to HH:MM string (24-hour format)
    function formatTime(timeMoment) {
        if (timeMoment == null) {
            return "--:--";
        }
        
        try {
            var info = Time.Gregorian.info(timeMoment, Time.FORMAT_SHORT);
            var hour = info.hour.format("%02d");
            var min = info.min.format("%02d");
            return hour + ":" + min;
        } catch (ex) {
            return "--:--";
        }
    }

    function onShow() {
        // In TEST_MODE, simulate GPS lock with Jerusalem coordinates
        if (TEST_MODE) {
            mCurrentLat = 31.7781;  // Jerusalem
            mCurrentLon = 35.2360;
            mGpsAvailable = true;
            mGpsQuality = 100;
            mBearingToJerusalem = Compass.calculateBearing(mCurrentLat, mCurrentLon, Compass.JERUSALEM_LAT, Compass.JERUSALEM_LON);
            
            // Enable sensor for compass
            try {
                Sensor.enableSensorEvents(method(:onSensor));
                mSensorListenerActive = true;
            } catch (ex) {
                // Sensor not available
            }
            
            // Trigger update to calculate and display Shabbat times
            updateDate();
            WatchUi.requestUpdate();
            return;
        }
        
        // Reset GPS state
        mGpsAvailable = false;
        mGpsQuality = 0;
        mPreviousGpsQuality = 0;
        mCurrentLat = null;
        mCurrentLon = null;
        mBearingToJerusalem = null;

        // Use last-known position immediately so compass shows without waiting.
        // GPS continues running in background to get a fresh fix — important when traveling.
        var lastInfo = Position.getInfo();
        if (lastInfo != null && lastInfo.position != null &&
            lastInfo.accuracy != Position.QUALITY_NOT_AVAILABLE) {
            var coords = lastInfo.position.toDegrees();
            if (coords != null && coords.size() >= 2) {
                mCurrentLat = coords[0];
                mCurrentLon = coords[1];
                mGpsQuality = Compass.getGpsQuality(lastInfo.accuracy);
                mGpsAvailable = true;
                mUsingCachedGps = true;  // flag: times may be from wrong location
                mBearingToJerusalem = Compass.getBearingToJerusalem(mCurrentLat, mCurrentLon);
                Sensor.enableSensorEvents(method(:onSensor));
                mSensorListenerActive = true;
                updateDate();
                WatchUi.requestUpdate();
                // Fall through — still start GPS to get a fresh accurate fix
            }
        }

        // Always request a fresh GPS fix. Once quality > LAST_KNOWN the bearing is updated.
        // onPosition() will stop GPS once a real fix is acquired.
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        
        // Request update to start rendering
        WatchUi.requestUpdate();
    }
    
    // GPS location callback - called when GPS data is updated
    function onPosition(info as Position.Info) as Void {
        if (info == null) {
            return;
        }
        
        // Store previous quality to detect lock transition
        mPreviousGpsQuality = mGpsQuality;
        
        // Update GPS quality
        mGpsQuality = Compass.getGpsQuality(info.accuracy);
        
        // Check if we have position data
        if (info.position != null) {
            var coords = info.position.toDegrees();
            if (coords != null && coords.size() >= 2) {
                mCurrentLat = coords[0];
                mCurrentLon = coords[1];
                
                // Always update bearing with latest position (covers travel case)
                mBearingToJerusalem = Compass.getBearingToJerusalem(mCurrentLat, mCurrentLon);
                mGpsAvailable = true;

                // Only stop GPS and finalise once we have a real fresh fix (not just cached)
                if (info.accuracy != Position.QUALITY_LAST_KNOWN) {
                    // Always recalculate Shabbat times with fresh accurate position.
                    // Covers both: (a) cached location from wrong place, (b) first open with no cache
                    mUsingCachedGps = false;
                    mLastDay = -1;  // force updateDate() to recalculate with correct location
                    updateDate();

                    // Vibrate on first real lock
                    if (mPreviousGpsQuality < 50) {
                        try {
                            Attention.vibrate([new Attention.VibeProfile(100, 100)]);
                        } catch (ex) {}
                    }

                    // Stop GPS to save battery — bearing is now accurate
                    Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));

                    // Enable magnetometer
                    if (!mSensorListenerActive) {
                        try {
                            Sensor.enableSensorEvents(method(:onSensor));
                            mSensorListenerActive = true;
                        } catch (ex) {
                            mSensorListenerActive = false;
                        }
                    }
                }
            }
        }
        
        // Request display update
        WatchUi.requestUpdate();
    }
    
    // Sensor event callback - update heading here (event-driven, not polled in onUpdate)
    function onSensor(sensorInfo as Sensor.Info) as Void {
        if (sensorInfo == null) { return; }

        var heading = null;

        // Try direct heading field (radians → degrees)
        if (sensorInfo has :heading && sensorInfo.heading != null) {
            heading = Math.toDegrees(sensorInfo.heading);
        // Fallback: raw magnetometer axes
        } else if ((sensorInfo has :magX) && (sensorInfo has :magY) &&
                   sensorInfo.magX != null && sensorInfo.magY != null) {
            heading = Math.toDegrees(Math.atan2(sensorInfo.magY, sensorInfo.magX));
        }

        if (heading != null) {
            mCompassHeading = ((heading.toNumber() + 360) % 360).toDouble();

            if (mGpsAvailable && mBearingToJerusalem != null) {
                mArrowAngle = Compass.calculateArrowAngle(mBearingToJerusalem, mCompassHeading);
            }

            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc) {
        // PRIORITY 1: Update date before anything else
        updateDate();
        
        // Clear screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Set white text color
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Choose font based on screen size - use smaller font for date
        var dateFont = Graphics.FONT_MEDIUM;
        var dayFont = Graphics.FONT_MEDIUM;
        if (width < 150) {
            dateFont = Graphics.FONT_SMALL;
            dayFont = Graphics.FONT_SMALL;
        }
        
        // PRIORITY 2: Check if we have Hebrew date data
        if (mHebrewDateString == null || mHebrewDateString.length() == 0) {
            dc.drawText(
                width / 2,
                height / 2,
                dateFont,
                "טוען...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }
        
        // PRIORITY 3: Draw Hebrew text FIRST (main feature)
        // Shift text left so it clears the compass circle in the top-right corner
        // Keep date text clear of the compass circle (top-right, radius 20 at x=width-25)
        var circleLeft = width - 57;  // left edge of enlarged circle (width-30-27)
        var textX = circleLeft / 2;
        var hasHallel = (mHallelText != null);
        var dayY = mIsFriday ? (height / 2 - 35) : (height / 2 - 25);
        var dateY = mIsFriday ? (height / 2 - 10) : (height / 2 + (hasHallel ? 0 : 10));

        // Draw day of week (top line)
        dc.drawText(
            textX,
            dayY,
            dayFont,
            mDayName,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw Hebrew date
        dc.drawText(
            textX,
            dateY,
            dateFont,
            mHebrewDateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Draw Hallel indicator below date (when applicable)
        if (hasHallel) {
            dc.drawText(
                textX,
                dateY + 20,
                Graphics.FONT_SMALL,
                mHallelText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Draw Shabbat times if Friday and times are available
        System.println("DISPLAY: mIsFriday=" + mIsFriday + " start=" + mShabbatStartTime + " end=" + mShabbatEndTime);
        if (mIsFriday && mShabbatStartTime != null && mShabbatEndTime != null) {
            var shabbatFont = Graphics.FONT_SMALL;
            
            var startTime = formatTime(mShabbatStartTime);
            var endTime = formatTime(mShabbatEndTime);
            System.println("DISPLAY: Showing times: " + startTime + " - " + endTime);
            
            // Draw Shabbat times: split at screen center so label and time never overlap
            var split = width / 2;
            var y1 = height / 2 + 20;
            var y2 = height / 2 + 40;

            // Small dot below times when location is from cache (not yet confirmed fresh fix)
            if (mUsingCachedGps) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(split, height / 2 + 55, 3);
            }

            dc.drawText(split - 3, y1, shabbatFont, "כניסה:", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(split + 3, y1, shabbatFont, startTime, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(split - 3, y2, shabbatFont, "יציאה:", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(split + 3, y2, shabbatFont, endTime,   Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            System.println("DISPLAY: NOT showing Shabbat times");
        }
        
        // PRIORITY 5: Draw compass in top-right circle (secondary feature)
        drawCompass(dc, width, height);
    }
    
    // Draw compass arrow in top-right circle
    function drawCompass(dc, width, height) {
        // Circle position (top-right, matching hardware circle)
        var circleCenterX = width - 30;
        var circleCenterY = 30;
        var circleRadius = 27;
        
        // Check if GPS is fully acquired and locked
        if (!mGpsAvailable || mBearingToJerusalem == null) {
            // Draw GPS acquisition indicator
            drawGpsAcquisition(dc, circleCenterX, circleCenterY, circleRadius);
            return;
        }
        
        // Check if compass heading is available
        if (mCompassHeading == null || mArrowAngle == null) {
            // Draw GPS acquisition indicator (waiting for compass)
            drawGpsAcquisition(dc, circleCenterX, circleCenterY, circleRadius);
            return;
        }
        
        // GPS locked and compass available - draw arrow pointing toward Jerusalem
        drawArrow(dc, circleCenterX, circleCenterY, circleRadius, mArrowAngle);
    }
    
    // Draw GPS acquisition indicator (like default Garmin GPS app)
    function drawGpsAcquisition(dc, centerX, centerY, radius) {
        // Draw background circle outline (gray) so we can see where arc fills
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(centerX, centerY, radius);
        
        // Draw "GPS" text with quality percentage
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY - 5,
            Graphics.FONT_XTINY,
            "GPS",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            centerX,
            centerY + 5,
            Graphics.FONT_XTINY,
            mGpsQuality + "%",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw thick filled arc based on GPS quality (0-100%)
        if (mGpsQuality > 0) {
            // Calculate arc angle (0-360 degrees)
            var arcAngle = (mGpsQuality * 360) / 100;
            
            // Set thick pen width for the arc (matching Garmin style)
            dc.setPenWidth(6);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            
            // Draw arc using drawArc if available, otherwise use thick line segments
            // Start from top (270 degrees) and go clockwise
            try {
                // Try using drawArc (available on newer devices)
                dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 270, 270 + arcAngle);
            } catch (ex) {
                // Fallback: draw thick arc using line segments
                var segments = arcAngle / 3;  // More segments for smoother arc
                if (segments > 0) {
                    for (var i = 0; i <= segments; i++) {
                        var angle = 270 + (i * 3);  // Start from top (270°)
                        var nextAngle = angle + 3;
                        
                        if (angle > 270 + arcAngle) {
                            break;
                        }
                        
                        var rad1 = Math.toRadians(angle);
                        var rad2 = Math.toRadians(nextAngle);
                        
                        var x1 = centerX + radius * Math.cos(rad1);
                        var y1 = centerY + radius * Math.sin(rad1);
                        var x2 = centerX + radius * Math.cos(rad2);
                        var y2 = centerY + radius * Math.sin(rad2);
                        
                        dc.drawLine(x1, y1, x2, y2);
                    }
                }
            }
            
            // Reset pen width
            dc.setPenWidth(1);
        }
    }
    
    // Classic two-tone compass needle, works on B&W screens:
    // - White filled tip  → toward Jerusalem (solid white, visible on black)
    // - Black filled tail → white outline makes it visible against black background
    // - White center dot  → clean join between the two halves
    function drawArrow(dc, centerX, centerY, radius, angleDegrees) {
        var angleRad  = Math.toRadians(angleDegrees);
        var perpAngle = angleRad + Math.PI / 2.0;

        var sinA = Math.sin(angleRad);
        var cosA = Math.cos(angleRad);
        var sinP = Math.sin(perpAngle);
        var cosP = Math.cos(perpAngle);

        var tipDist  = radius * 0.85;
        var tailDist = radius * 0.55;
        var wingDist = radius * 0.28;

        var tipX   = centerX + tipDist  * sinA;
        var tipY   = centerY - tipDist  * cosA;
        var tailX  = centerX - tailDist * sinA;
        var tailY  = centerY + tailDist * cosA;
        var leftX  = centerX + wingDist * sinP;
        var leftY  = centerY - wingDist * cosP;
        var rightX = centerX - wingDist * sinP;
        var rightY = centerY + wingDist * cosP;

        // Tail: fill black then white outline — visible as hollow on black screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillPolygon([[tailX, tailY], [leftX, leftY], [rightX, rightY]]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(tailX, tailY, leftX, leftY);
        dc.drawLine(tailX, tailY, rightX, rightY);
        // shared base line drawn after tip so tip overdraw covers it cleanly

        // Tip: solid white toward Jerusalem
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillPolygon([[tipX, tipY], [leftX, leftY], [rightX, rightY]]);

        // Center dot to cleanly join the two halves
        dc.fillCircle(centerX, centerY, 2);
    }

    function onHide() {
        // Disable GPS location events when view is hidden
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        
        // Disable sensor events to save battery
        if (mSensorListenerActive) {
            try {
                Sensor.enableSensorEvents(null);
            } catch (ex) {
                // Failed to disable
            }
            mSensorListenerActive = false;
        }
    }
}
