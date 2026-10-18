using Toybox.Application;
using Toybox.WatchUi;

(:glance)
class HebrewDateFieldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new HebrewDateView();
        return [view, new HebrewDateDelegate(view)];
    }

    (:glance)
    function getGlanceView() {
        return [new HebrewDateGlanceView()];
    }
}

function getApp() {
    return Application.getApp();
}
