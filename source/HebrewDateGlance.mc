using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

// Glance: day, Hebrew date and the most relevant extra line (holiday, Omer or parasha).
// Uses the location the widget last saved for the sunset switch.
(:glance)
class HebrewDateGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        var t = Today.compute(Time.now(), Today.savedLocation());
        var lines = Today.infoLines(t);
        var h = dc.getHeight();
        // The G1 glance strip is clipped short of the sub-screen bubble, so right-align
        // Hebrew a little inside that edge; overflow is cut at the end of the text.
        var x = glanceRight(dc);
        var j = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, h * 0.18, Graphics.FONT_XTINY, Today.dayLabel(t), j);
        dc.drawText(x, h * 0.48, Graphics.FONT_XTINY, HebrewText.date(t["y"], t["m"], t["d"]), j);
        if (lines.size() > 0) {
            dc.drawText(x, h * 0.80, Graphics.FONT_XTINY, lines[0], j);
        }
    }

    function glanceRight(dc) {
        if (WatchUi has :getSubscreen && WatchUi.getSubscreen() != null) {
            return 88;
        }
        return dc.getWidth() - 2;
    }
}
