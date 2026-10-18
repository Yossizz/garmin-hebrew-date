using Toybox.Application.Storage;
using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

// Widget view. Page 0: day, year, date, observances and (Fri / Shabbat / Erev Yom Tov)
// candle lighting + havdalah. Page 1: sunset and every observance line.
// The compass to Jerusalem is drawn in the round sub-screen on both pages.
class HebrewDateView extends WatchUi.View {

    hidden var mPage = 0;
    hidden var mToday = null;
    hidden var mStartTime = null;     // candle lighting (Time.Moment)
    hidden var mEndTime = null;       // havdalah / end of Yom Tov (Time.Moment)

    // GPS and compass
    hidden var mCurrentLat = null;
    hidden var mCurrentLon = null;
    hidden var mBearingToJerusalem = null;
    hidden var mGpsAvailable = false;
    hidden var mGpsQuality = 0;
    hidden var mPreviousGpsQuality = 0;
    hidden var mCompassHeading = null;
    hidden var mArrowAngle = null;
    hidden var mSensorListenerActive = false;
    hidden var mUsingCachedGps = false;

    function initialize() {
        View.initialize();
        var saved = Today.savedLocation();
        if (saved != null) {
            mCurrentLat = saved[0];
            mCurrentLon = saved[1];
            mUsingCachedGps = true;
        }
    }

    function togglePage() {
        mPage = 1 - mPage;
        WatchUi.requestUpdate();
    }

    // Recompute the Hebrew date and the Shabbat / Yom Tov times.
    function refresh() {
        var loc = (mCurrentLat == null) ? null : [mCurrentLat, mCurrentLon];
        mToday = Today.compute(Time.now(), loc);
        mStartTime = null;
        mEndTime = null;
        if (loc == null) {
            return;
        }
        var civil = mToday["civil"];
        var cdow = HebrewCalendar.dayOfWeek(civil);
        var hd = HebrewCalendar.fromJdn(civil);
        var erev = Holidays.erevYomTov(hd[1], hd[2], mToday["israel"]);
        var startJdn = null;
        var endJdn = null;
        if (erev > 0) {
            startJdn = civil;
            endJdn = civil + erev;
        }
        if (cdow == 5) {
            startJdn = civil;
            if (endJdn == null || endJdn < civil + 1) {
                endJdn = civil + 1;
            }
        } else if (cdow == 6) {
            startJdn = civil - 1;
            if (endJdn == null) {
                endJdn = civil;
            }
        }
        if (endJdn != null && HebrewCalendar.dayOfWeek(endJdn) == 5) {
            endJdn++;    // Yom Tov running into Shabbat
        }
        if (startJdn != null) {
            mStartTime = SunTimes.candleLighting(mCurrentLat, mCurrentLon, startJdn);
            mEndTime = SunTimes.havdalah(mCurrentLat, mCurrentLon, endJdn);
        }
    }

    function formatTime(moment) {
        if (moment == null) {
            return "--:--";
        }
        var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    function onShow() {
        mGpsQuality = 0;
        mPreviousGpsQuality = 0;

        // Use the last-known position immediately; keep GPS running for a fresh fix
        // (important when travelling).
        var lastInfo = Position.getInfo();
        if (lastInfo != null && lastInfo.position != null &&
            lastInfo.accuracy != Position.QUALITY_NOT_AVAILABLE) {
            var coords = lastInfo.position.toDegrees();
            if (validCoords(coords)) {
                setLocation(coords[0].toDouble(), coords[1].toDouble(), true);
                mGpsQuality = Compass.getGpsQuality(lastInfo.accuracy);
                enableCompass();
            }
        }
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        refresh();
        WatchUi.requestUpdate();
    }

    function validCoords(coords) {
        return coords != null && coords.size() >= 2 &&
            coords[0].toDouble() >= -90.0 && coords[0].toDouble() <= 90.0 &&
            coords[1].toDouble() > -180.0 && coords[1].toDouble() < 180.0;
    }

    function setLocation(lat, lon, cached) {
        mCurrentLat = lat;
        mCurrentLon = lon;
        mUsingCachedGps = cached;
        mGpsAvailable = true;
        mBearingToJerusalem = Compass.getBearingToJerusalem(lat, lon);
        Storage.setValue("loc", [lat, lon]);
    }

    function enableCompass() {
        if (!mSensorListenerActive) {
            try {
                Sensor.enableSensorEvents(method(:onSensor));
                mSensorListenerActive = true;
            } catch (ex) {
                mSensorListenerActive = false;
            }
        }
    }

    function onPosition(info as Position.Info) as Void {
        if (info == null) {
            return;
        }
        mPreviousGpsQuality = mGpsQuality;
        mGpsQuality = Compass.getGpsQuality(info.accuracy);
        if (info.position != null) {
            var coords = info.position.toDegrees();
            if (validCoords(coords)) {
                var fresh = info.accuracy != Position.QUALITY_LAST_KNOWN;
                setLocation(coords[0].toDouble(), coords[1].toDouble(), !fresh);
                if (fresh) {
                    refresh();
                    if (mPreviousGpsQuality < 50) {
                        try {
                            Attention.vibrate([new Attention.VibeProfile(100, 100)]);
                        } catch (ex) {
                        }
                    }
                    // Stop GPS to save battery once we have a real fix
                    Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
                    enableCompass();
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function onSensor(sensorInfo as Sensor.Info) as Void {
        if (sensorInfo == null) {
            return;
        }
        var heading = null;
        if (sensorInfo has :heading && sensorInfo.heading != null) {
            heading = Math.toDegrees(sensorInfo.heading);
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

    // Round sub-screen (Descent G1) or a matching top-right circle elsewhere: [cx, cy, r].
    function bubble(dc) {
        if (WatchUi has :getSubscreen) {
            var sub = WatchUi.getSubscreen();
            if (sub != null) {
                return [sub.x + sub.width / 2, sub.y + sub.height / 2, sub.width / 2 - 4];
            }
        }
        return [dc.getWidth() - 30, 30, 27];
    }

    function onUpdate(dc) {
        // The Hebrew date can change at sunset or midnight while the widget is open.
        if (mToday == null || HebrewCalendar.civilJdn(Time.now()) != mToday["civil"] ||
            (mToday["sunset"] != null && !mToday["after"] && Time.now().value() >= mToday["sunset"].value())) {
            refresh();
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var b = bubble(dc);
        if (mPage == 0) {
            drawSummary(dc, b);
        } else {
            drawDetails(dc, b);
        }
        drawCompass(dc, b[0], b[1], b[2]);
    }

    function drawSummary(dc, b) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var t = mToday;
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var top = b[1] + b[2] + 4;                   // just below the bubble
        var sideX = (b[0] - b[2]) / 2;               // centre of the area left of the bubble

        dc.drawText(sideX, top * 0.30, Graphics.FONT_SMALL, Today.dayLabel(t), c);
        dc.drawText(sideX, top * 0.72, Graphics.FONT_SMALL, HebrewText.numeral(t["y"]), c);
        dc.drawText(w / 2, top + 16, Graphics.FONT_MEDIUM, HebrewText.date(t["y"], t["m"], t["d"]), c);

        var font = Graphics.FONT_XTINY;
        var lh = dc.getFontHeight(font);
        var y = top + 34 + lh / 2;
        var bottom = h - 12;
        var lines = Today.infoLines(t);
        var hasTimes = mStartTime != null && mEndTime != null;
        var maxLines = hasTimes ? 1 : 3;
        for (var i = 0; i < lines.size() && i < maxLines && y < bottom; i++) {
            dc.drawText(w / 2, y, font, fit(dc, lines[i], font, w - 30), c);
            y += lh;
        }
        if (hasTimes) {
            drawTimeRow(dc, w / 2, y, font, "כניסה:", formatTime(mStartTime));
            drawTimeRow(dc, w / 2, y + lh, font, "יציאה:", formatTime(mEndTime));
            if (mUsingCachedGps) {
                dc.fillCircle(w / 2, y + lh + lh / 2 + 3, 2);    // times from a cached location
            }
        }
    }

    function drawDetails(dc, b) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var t = mToday;
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var top = b[1] + b[2] + 4;
        var sideX = (b[0] - b[2]) / 2;
        var font = Graphics.FONT_XTINY;
        var lh = dc.getFontHeight(font);

        if (t["sunset"] != null) {
            dc.drawText(sideX, top * 0.30, font, "שקיעה", c);
            dc.drawText(sideX, top * 0.70, Graphics.FONT_SMALL, formatTime(t["sunset"]), c);
        } else {
            dc.drawText(sideX, top * 0.30, font, "אין מיקום", c);
            dc.drawText(sideX, top * 0.70, font, "GPS", c);
        }

        var lines = Today.infoLines(t);
        if (lines.size() == 0) {
            lines.add(HebrewText.date(t["y"], t["m"], t["d"]));
        }
        var y = top + lh / 2 + 2;
        var bottom = h - 12;
        for (var i = 0; i < lines.size() && y < bottom; i++) {
            dc.drawText(w / 2, y, font, fit(dc, lines[i], font, w - 30), c);
            y += lh;
        }
    }

    // Label and time on either side of the centre so mixed Hebrew / digits never reorder.
    function drawTimeRow(dc, x, y, font, label, time) {
        dc.drawText(x - 3, y, font, label, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x + 3, y, font, time, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Drop the "פרשת " prefix when a long parasha name does not fit.
    function fit(dc, s, font, maxW) {
        if (dc.getTextWidthInPixels(s, font) > maxW && s.find("פרשת ") == 0) {
            return s.substring(5, s.length());
        }
        return s;
    }

    function drawCompass(dc, cx, cy, r) {
        if (!mGpsAvailable || mBearingToJerusalem == null || mCompassHeading == null || mArrowAngle == null) {
            drawGpsAcquisition(dc, cx, cy, r);
            return;
        }
        drawArrow(dc, cx, cy, r, mArrowAngle);
    }

    // GPS acquisition ring, like the native GPS screen.
    function drawGpsAcquisition(dc, centerX, centerY, radius) {
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(centerX, centerY, radius);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 5, Graphics.FONT_XTINY, "GPS",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY + 5, Graphics.FONT_XTINY, mGpsQuality + "%",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (mGpsQuality > 0) {
            dc.setPenWidth(6);
            dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 270, 270 + mGpsQuality * 360 / 100);
        }
        dc.setPenWidth(1);
    }

    // Two-tone needle that reads on black-and-white screens: solid tip toward
    // Jerusalem, outlined tail, centre dot.
    function drawArrow(dc, centerX, centerY, radius, angleDegrees) {
        var angleRad = Math.toRadians(angleDegrees);
        var perpAngle = angleRad + Math.PI / 2.0;
        var sinA = Math.sin(angleRad);
        var cosA = Math.cos(angleRad);
        var sinP = Math.sin(perpAngle);
        var cosP = Math.cos(perpAngle);

        var tipX = centerX + radius * 0.85 * sinA;
        var tipY = centerY - radius * 0.85 * cosA;
        var tailX = centerX - radius * 0.55 * sinA;
        var tailY = centerY + radius * 0.55 * cosA;
        var leftX = centerX + radius * 0.28 * sinP;
        var leftY = centerY - radius * 0.28 * cosP;
        var rightX = centerX - radius * 0.28 * sinP;
        var rightY = centerY + radius * 0.28 * cosP;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillPolygon([[tailX, tailY], [leftX, leftY], [rightX, rightY]]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(tailX, tailY, leftX, leftY);
        dc.drawLine(tailX, tailY, rightX, rightY);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillPolygon([[tipX, tipY], [leftX, leftY], [rightX, rightY]]);
        dc.fillCircle(centerX, centerY, 2);
    }

    function onHide() {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if (mSensorListenerActive) {
            try {
                Sensor.enableSensorEvents(null);
            } catch (ex) {
            }
            mSensorListenerActive = false;
        }
    }
}

class HebrewDateDelegate extends WatchUi.BehaviorDelegate {

    hidden var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onSelect() {
        mView.togglePage();
        return true;
    }
}
