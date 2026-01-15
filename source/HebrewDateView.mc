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
    }
    
    function updateDate() {
        // Get current date
        var now = Time.now();
        var today = Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Only recalculate if day has changed
        if (today.day != mLastDay) {
            mLastDay = today.day;
            
            // Convert to Hebrew date
            var hebrewDate = HebrewCalendar.gregorianToHebrew(
                today.year,
                today.month,
                today.day
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
            
            // Get day of week (1=Sunday, 7=Saturday)
            var dayOfWeek = today.day_of_week;
            mDayName = dayNames[dayOfWeek - 1];
            
            // Format Hebrew day with Hebrew numerals
            var hebrewDay = HebrewCalendar.formatHebrewDay(hebrewDate["day"]);
            
            // Convert ASCII-mapped Hebrew back to actual Hebrew
            var hebrewDayText = HebrewFont.asciiToHebrew(hebrewDay);
            
            // Format date
            mHebrewDateString = hebrewDayText + " " + monthNames[monthIndex];
            
        }
        
        WatchUi.requestUpdate();
    }

    function onLayout(dc) {
        // No layout needed
    }

    function onShow() {
        // Reset GPS state
        mGpsAvailable = false;
        mGpsQuality = 0;
        mPreviousGpsQuality = 0;
        mCurrentLat = null;
        mCurrentLon = null;
        mBearingToJerusalem = null;
        
        // Enable GPS location events - basic GPS only (most reliable)
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
                
                // Check if GPS is locked (quality >= 50% POOR is enough)
                if (mGpsQuality >= 50 && !mGpsAvailable) {
                    mGpsAvailable = true;
                    
                    // Calculate bearing to Jerusalem
                    mBearingToJerusalem = Compass.getBearingToJerusalem(mCurrentLat, mCurrentLon);
                    
                    // Trigger vibration on lock
                    if (mPreviousGpsQuality < 50) {
                        try {
                            Attention.vibrate([new Attention.VibeProfile(100, 100)]);
                        } catch (ex) {
                            // Vibration not supported
                        }
                    }
                    
                    // Disable GPS to save battery now that we have a lock
                    Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
                    
                    // Enable sensor events to activate magnetometer
                    try {
                        Sensor.enableSensorEvents(method(:onSensor));
                        mSensorListenerActive = true;
                    } catch (ex) {
                        mSensorListenerActive = false;
                    }
                }
            }
        }
        
        // Request display update
        WatchUi.requestUpdate();
    }
    
    // Sensor event callback - called when sensor data changes
    function onSensor(sensorInfo as Sensor.Info) as Void {
        // This callback enables the magnetometer to be active
        // We'll still poll the data in onUpdate() for simplicity
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
        
        // Choose font based on screen size (restore original working font)
        var font = Graphics.FONT_LARGE;
        if (width < 150) {
            font = Graphics.FONT_MEDIUM;
        }
        
        // PRIORITY 2: Check if we have Hebrew date data
        if (mHebrewDateString == null || mHebrewDateString.length() == 0) {
            dc.drawText(
                width / 2,
                height / 2,
                font,
                "טוען...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }
        
        // PRIORITY 3: Draw Hebrew text FIRST (main feature)
        // Draw day of week (top line)
        dc.drawText(
            width / 2,
            height / 2 - 25,
            font,
            mDayName,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw Hebrew date (bottom line)
        dc.drawText(
            width / 2,
            height / 2 + 25,
            font,
            mHebrewDateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // PRIORITY 4: Update compass heading for smooth rotation (only if GPS is available)
        if (mGpsAvailable && mBearingToJerusalem != null) {
            mCompassHeading = Compass.getCompassHeading();
            if (mCompassHeading != null) {
                mArrowAngle = Compass.calculateArrowAngle(mBearingToJerusalem, mCompassHeading);
            }
            // Request another update immediately for smooth compass rotation
            WatchUi.requestUpdate();
        }
        
        // PRIORITY 5: Draw compass in top-right circle (secondary feature)
        drawCompass(dc, width, height);
    }
    
    // Draw compass arrow in top-right circle
    function drawCompass(dc, width, height) {
        // Circle position (top-right, matching hardware circle)
        var circleCenterX = width - 25;
        var circleCenterY = 25;
        var circleRadius = 20;
        
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
    
    // Draw arrow pointing in specified direction
    function drawArrow(dc, centerX, centerY, radius, angleDegrees) {
        // Convert angle to radians
        var angleRad = Math.toRadians(angleDegrees);
        
        // Arrow dimensions
        var arrowLength = radius * 0.7;  // Arrow extends 70% of radius
        var arrowWidth = 4;               // Width of arrow base
        
        // Calculate arrow tip position
        var tipX = centerX + arrowLength * Math.sin(angleRad);
        var tipY = centerY - arrowLength * Math.cos(angleRad);
        
        // Calculate arrow base positions (perpendicular to arrow direction)
        var perpAngle = angleRad + Math.PI / 2;
        var baseX1 = centerX + arrowWidth * Math.sin(perpAngle);
        var baseY1 = centerY - arrowWidth * Math.cos(perpAngle);
        var baseX2 = centerX - arrowWidth * Math.sin(perpAngle);
        var baseY2 = centerY + arrowWidth * Math.cos(perpAngle);
        
        // Draw filled arrow triangle
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        var points = [[tipX, tipY], [baseX1, baseY1], [baseX2, baseY2]];
        dc.fillPolygon(points);
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
