using Toybox.Application;
using Toybox.WatchUi;

class HebrewDateFieldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new HebrewDateView() ];
    }

}

function getApp() {
    return Application.getApp();
}
