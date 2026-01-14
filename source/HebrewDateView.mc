using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;
using Toybox.Timer;

class HebrewDateView extends WatchUi.View {

    hidden var mHebrewDateString;
    hidden var mDayName;
    hidden var mLastDay;

    function initialize() {
        View.initialize();
        mHebrewDateString = "";
        mDayName = "";
        mLastDay = -1;
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
        // Called when view is shown
    }

    function onUpdate(dc) {
        // Update date before drawing
        updateDate();
        
        // Clear screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Set white text color
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Choose font based on screen size
        var font = Graphics.FONT_LARGE;
        if (width < 150) {
            font = Graphics.FONT_MEDIUM;
        }
        
        // Check if we have data
        if (mHebrewDateString.length() == 0) {
            dc.drawText(
                width / 2,
                height / 2,
                font,
                "טוען...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }
        
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
    }

    function onHide() {
        // Called when view is hidden
    }
}
